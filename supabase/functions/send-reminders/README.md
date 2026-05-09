# Send Reminders – Supabase Edge Function

Daily scheduled job that:
1. Reads every user's row in `reminder_settings`.
2. Finds invoices whose `due_date` matches one of the user's reminder windows
   (N days before, on due date, N days after).
3. Sends an FCM push notification to every active row in `user_devices` for
   that user.
4. Writes one row to `reminder_logs` per device per attempt.

Source code: [index.ts](./index.ts)
Import map:  [deno.json](./deno.json)

---

## Prerequisites

You need the Supabase CLI installed locally:

```bash
brew install supabase/tap/supabase
supabase --version    # should print 1.x or newer
```

Then link your local repo to the Supabase project (one-time):

```bash
cd /Users/peilinfoo/Desktop/my_project/Quo_Inv_app
supabase link --project-ref qtmufapdhghwkugseilg
```

`qtmufapdhghwkugseilg` is the project ref from your Supabase URL
(`https://qtmufapdhghwkugseilg.supabase.co`).

---

## Step 1 — Run the database migration

Open the Supabase SQL editor (or `supabase db push`) and run the file:

[../../migrations/20260501_user_devices_reminder_logs.sql](../../migrations/20260501_user_devices_reminder_logs.sql)

This creates / re-creates `user_devices`, `reminder_logs`, RLS policies, and
the `updated_at` trigger. It is **idempotent** — safe to run twice.

Verify in SQL editor:

```sql
select count(*) from public.user_devices;     -- should return 0 the first time
select count(*) from public.reminder_logs;    -- should return 0 the first time
```

---

## Step 2 — Generate a Firebase service-account key

The Edge Function uses FCM HTTP v1 API, which requires a service-account JWT.

1. Open Firebase console: <https://console.firebase.google.com/project/quoswift-1c795/settings/serviceaccounts/adminsdk>
2. Click **"Generate new private key"** → confirm → a JSON file downloads
   (something like `quoswift-1c795-firebase-adminsdk-xxxxx.json`).
3. **Do NOT commit this file.** Move it somewhere outside the repo, e.g.
   `~/Downloads/quoswift-firebase-key.json`.

The JSON looks like:

```json
{
  "type": "service_account",
  "project_id": "quoswift-1c795",
  "private_key_id": "abcd…",
  "private_key": "-----BEGIN PRIVATE KEY-----\n…\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@quoswift-1c795.iam.gserviceaccount.com",
  ...
}
```

---

## Step 3 — Set Edge Function secrets

The function reads four environment variables. `SUPABASE_URL` and
`SUPABASE_SERVICE_ROLE_KEY` are auto-injected by Supabase, so you only need
to set the Firebase ones plus a cron secret.

Pick a random string for `CRON_SECRET` (any 32+ chars):

```bash
openssl rand -hex 32     # copy the output, e.g. 7f2c…d91
```

Then set all three secrets from the repo root:

```bash
supabase login

supabase link --project-ref qtmufapdhghwkugseilg

cd /Users/peilinfoo/Desktop/my_project/Quo_Inv_app

supabase secrets set FCM_PROJECT_ID=quoswift-1c795
supabase secrets set CRON_SECRET=17a7d6387b48abe8bf5dcc632d3b8782eee65a006dc039e00dd3cd5f93f834f7
supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat ~/Downloads/quoswift-1c795-firebase-adminsdk-fbsvc-e5f92ba1b8.json)"
```

> The `$(cat …)` trick passes the file contents as a single string. The JSON's
> embedded `\n` in `private_key` is preserved correctly.

Verify:

```bash
supabase secrets list
# Should show: FCM_PROJECT_ID, CRON_SECRET, FCM_SERVICE_ACCOUNT_JSON
```

---

## Step 4 — Deploy the function

```bash
cd /Users/peilinfoo/Desktop/my_project/Quo_Inv_app
supabase functions deploy send-reminders --no-verify-jwt
```

`--no-verify-jwt` is required because the function will be called by
`pg_cron` (server-to-server, no end-user JWT). Authentication is enforced via
the `X-Cron-Secret` header instead.

After deploy, your function URL is:

```
https://qtmufapdhghwkugseilg.supabase.co/functions/v1/send-reminders
```

---

## Step 5 — Test manually (dry run)

Dry run logs what *would* be sent without calling FCM:

```bash
curl -X POST 'https://qtmufapdhghwkugseilg.supabase.co/functions/v1/send-reminders' \
  -H 'X-Cron-Secret: 17a7d6387b48abe8bf5dcc632d3b8782eee65a006dc039e00dd3cd5f93f834f7' \
  -H 'Content-Type: application/json' \
  -d '{"dryRun": true}'
```

Expected response:

```json
{"scanned": 0, "sent": 0, "failed": 0, "skipped": 0, "dryRun": true}
```

Once you have at least one invoice with `due_date` matching a window AND one
device registered in `user_devices`, do a **real** send:

```bash
curl -X POST 'https://qtmufapdhghwkugseilg.supabase.co/functions/v1/send-reminders' \
  -H 'X-Cron-Secret: 17a7d6387b48abe8bf5dcc632d3b8782eee65a006dc039e00dd3cd5f93f834f7' \
  -H 'Content-Type: application/json' \
  -d '{}'
```

Then check `reminder_logs` in the SQL editor:

```sql
select invoice_id, reminder_type, status, sent_at, error_message
from public.reminder_logs
order by created_at desc
limit 20;
```

---

## Step 6 — Schedule with pg_cron

Run this **once** in the Supabase SQL editor. Replace `7f2c…d91` with your
actual `CRON_SECRET`:

```sql
-- Enable extensions (one-time, idempotent)
create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net  with schema extensions;

-- Daily at 09:00 UTC. Adjust the cron expression to your preferred hour.
-- Examples:
--   '0 9 * * *'   = 09:00 UTC every day
--   '0 1 * * *'   = 01:00 UTC every day  (= 09:00 in Singapore/Malaysia)
--   '0 */6 * * *' = every 6 hours
select cron.schedule(
  'daily-reminders',
  '0 1 * * *',
  $$
  select net.http_post(
    url     := 'https://qtmufapdhghwkugseilg.supabase.co/functions/v1/send-reminders',
    headers := jsonb_build_object(
      'Content-Type',   'application/json',
      'X-Cron-Secret',  '17a7d6387b48abe8bf5dcc632d3b8782eee65a006dc039e00dd3cd5f93f834f7'
    ),
    body    := '{}'::jsonb
  );
  $$
);
```

Verify the schedule:

```sql
select * from cron.job;             -- list scheduled jobs
select * from cron.job_run_details  -- last 50 runs (after first execution)
order by start_time desc limit 50;
```

To remove or change the schedule:

```sql
select cron.unschedule('daily-reminders');
```

---

## Files you'll edit later

| When you want to… | Edit this file |
| --- | --- |
| Change the notification title/body wording | [index.ts](./index.ts) → `renderTemplate()` |
| Change which invoice statuses get reminders | [index.ts](./index.ts) → the `.in("status", [...])` array |
| Add a new reminder window (e.g. 14 days before) | Add a UI toggle in `lib/features/settings/`, a column in `reminder_settings`, then add another `candidates.push(...)` block in [index.ts](./index.ts) |
| Add email or WhatsApp delivery | [index.ts](./index.ts) → after the FCM send loop, add a second loop that POSTs to your provider, and write `channel: 'email'` to `reminder_logs` |
| Change schedule time | Re-run `cron.schedule(...)` with a new cron expression (overwrites by name) |

---

## Troubleshooting

**`401 Unauthorized` from `oauth2.googleapis.com`**
The service-account JSON is malformed (likely the newlines in `private_key`
got escaped wrong). Re-run Step 3 using the `$(cat ...)` form, not by pasting.

**`UNREGISTERED` errors in `reminder_logs.error_message`**
The device's FCM token is stale (user uninstalled the app, etc.). The function
auto-marks those `is_active = false` so they stop being targeted.

**Function returns `{scanned: 0}` even though invoices exist**
- Confirm `enable_push_notifications = true` in `reminder_settings` for that
  user.
- Confirm the invoice's `status` is one of `sent`, `partial`, `overdue`.
- Confirm `due_date` matches **today + remind_before_days** OR **today** OR
  **today − remind_after_days** (UTC).

**Push received on Android but not iOS**
Check that the APNs `.p8` key is uploaded in Firebase console → Cloud
Messaging → iOS app, and that the bundle ID matches Xcode
(`com.paralleltech.quoswift`).
