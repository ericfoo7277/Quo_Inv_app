// Send Reminders Edge Function
// ---------------------------------------------------------------------------
// Scheduled daily by pg_cron. For every user with reminder_settings, finds
// invoices whose due_date matches one of the configured windows and sends
// FCM push notifications to every active device.
//
// Run locally: supabase functions serve send-reminders --no-verify-jwt
// Deploy:      supabase functions deploy send-reminders --no-verify-jwt
// ---------------------------------------------------------------------------

// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

interface ServiceAccount {
     client_email: string;
     private_key: string;
     project_id: string;
}

interface ReminderSetting {
     user_id: string;
     remind_before_days: number;
     remind_on_due_date: boolean;
     remind_after_days: number;
     enable_push_notifications: boolean;
     message_template: string | null;
}

interface InvoiceRow {
     id: string;
     user_id: string;
     invoice_number: string;
     customer_name: string;
     total: number;
     currency: string;
     due_date: string; // YYYY-MM-DD
     status: string;
}

interface DeviceRow {
     fcm_token: string;
     platform: string;
}

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID")!;
const FCM_SERVICE_ACCOUNT_JSON = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!;
const CRON_SECRET = Deno.env.get("CRON_SECRET");

// ---------------------------------------------------------------------------
// FCM HTTP v1 – exchange service-account JWT for OAuth access token.
// ---------------------------------------------------------------------------

let cachedAccessToken: { token: string; exp: number } | null = null;

async function getAccessToken(sa: ServiceAccount): Promise<string> {
     const now = Math.floor(Date.now() / 1000);
     if (cachedAccessToken && cachedAccessToken.exp - 60 > now) {
          return cachedAccessToken.token;
     }

     // Import the PEM private key for RS256.
     const pem = sa.private_key
          .replace(/-----BEGIN PRIVATE KEY-----/, "")
          .replace(/-----END PRIVATE KEY-----/, "")
          .replace(/\s+/g, "");
     const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
     const key = await crypto.subtle.importKey(
          "pkcs8",
          der,
          { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
          false,
          ["sign"],
     );

     const jwt = await create(
          { alg: "RS256", typ: "JWT" },
          {
               iss: sa.client_email,
               scope: "https://www.googleapis.com/auth/firebase.messaging",
               aud: "https://oauth2.googleapis.com/token",
               iat: now,
               exp: getNumericDate(60 * 60),
          },
          key,
     );

     const resp = await fetch("https://oauth2.googleapis.com/token", {
          method: "POST",
          headers: { "Content-Type": "application/x-www-form-urlencoded" },
          body: new URLSearchParams({
               grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
               assertion: jwt,
          }),
     });

     if (!resp.ok) {
          const text = await resp.text();
          throw new Error(`OAuth token exchange failed (${resp.status}): ${text}`);
     }

     const json = await resp.json();
     cachedAccessToken = {
          token: json.access_token as string,
          exp: now + (json.expires_in as number),
     };
     return cachedAccessToken.token;
}

async function sendFcm(opts: {
     accessToken: string;
     projectId: string;
     token: string;
     title: string;
     body: string;
     data: Record<string, string>;
}): Promise<{ ok: boolean; error?: string }> {
     const resp = await fetch(
          `https://fcm.googleapis.com/v1/projects/${opts.projectId}/messages:send`,
          {
               method: "POST",
               headers: {
                    Authorization: `Bearer ${opts.accessToken}`,
                    "Content-Type": "application/json",
               },
               body: JSON.stringify({
                    message: {
                         token: opts.token,
                         notification: { title: opts.title, body: opts.body },
                         data: opts.data,
                         android: { priority: "HIGH" },
                         apns: { payload: { aps: { sound: "default" } } },
                    },
               }),
          },
     );

     if (resp.ok) return { ok: true };
     const text = await resp.text();
     return { ok: false, error: `${resp.status} ${text}` };
}

// ---------------------------------------------------------------------------
// Reminder window logic.
// ---------------------------------------------------------------------------

function ymd(d: Date): string {
     const y = d.getUTCFullYear();
     const m = String(d.getUTCMonth() + 1).padStart(2, "0");
     const day = String(d.getUTCDate()).padStart(2, "0");
     return `${y}-${m}-${day}`;
}

/** Days from `today` to `dueDate`. Negative = overdue. */
function daysDiff(today: Date, dueDate: string): number {
     const due = new Date(`${dueDate}T00:00:00Z`);
     return Math.round((due.getTime() - today.getTime()) / 86_400_000);
}

function reminderTypeFor(diff: number, s: ReminderSetting): string | null {
     if (diff === s.remind_before_days && s.remind_before_days > 0) {
          return "before_due";
     }
     if (diff === 0 && s.remind_on_due_date) return "on_due";
     if (diff === -s.remind_after_days && s.remind_after_days > 0) {
          return "after_due";
     }
     return null;
}

function renderTemplate(
     tpl: string,
     inv: InvoiceRow,
     diff: number,
): { title: string; body: string } {
     const fmt = new Intl.NumberFormat("en", {
          style: "currency",
          currency: inv.currency || "USD",
     });
     const status = diff > 0
          ? `due in ${diff} days`
          : diff === 0
               ? "due today"
               : `${Math.abs(diff)} days overdue`;
     const body = (tpl || "Invoice {{number}} for {{customer}} is {{status}}.")
          .replaceAll("{{number}}", inv.invoice_number)
          .replaceAll("{{customer}}", inv.customer_name)
          .replaceAll("{{amount}}", fmt.format(inv.total))
          .replaceAll("{{status}}", status);
     return {
          title: diff < 0
               ? `Invoice ${inv.invoice_number} overdue`
               : diff === 0
                    ? `Invoice ${inv.invoice_number} due today`
                    : `Invoice ${inv.invoice_number} due soon`,
          body,
     };
}

// ---------------------------------------------------------------------------
// Main handler.
// ---------------------------------------------------------------------------

Deno.serve(async (req) => {
     // Cron auth – reject unauthenticated invocations.
     if (CRON_SECRET) {
          const supplied = req.headers.get("X-Cron-Secret");
          if (supplied !== CRON_SECRET) {
               return new Response("forbidden", { status: 403 });
          }
     }

     let dryRun = false;
     try {
          const body = await req.json().catch(() => ({}));
          dryRun = body?.dryRun === true;
     } catch (_) {
          // ignore
     }

     const sa: ServiceAccount = JSON.parse(FCM_SERVICE_ACCOUNT_JSON);
     const supa = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

     // Today in UTC – pg_cron schedules in UTC, so we pick a UTC reference day.
     const today = new Date();
     today.setUTCHours(0, 0, 0, 0);

     // 1. Load every user's reminder settings (only those with push enabled).
     const { data: settings, error: settingsErr } = await supa
          .from("reminder_settings")
          .select(
               "user_id, remind_before_days, remind_on_due_date, remind_after_days, enable_push_notifications, message_template",
          )
          .eq("enable_push_notifications", true);

     if (settingsErr) {
          return new Response(
               JSON.stringify({ error: settingsErr.message }),
               { status: 500 },
          );
     }

     const accessToken = dryRun ? "" : await getAccessToken(sa);

     let scanned = 0;
     let sent = 0;
     let failed = 0;
     let skipped = 0;

     for (const s of (settings ?? []) as ReminderSetting[]) {
          // 2. Build the due-date filter for this user's windows.
          const candidates: Array<{ date: string; diff: number }> = [];
          if (s.remind_before_days > 0) {
               const d = new Date(today);
               d.setUTCDate(d.getUTCDate() + s.remind_before_days);
               candidates.push({ date: ymd(d), diff: s.remind_before_days });
          }
          if (s.remind_on_due_date) {
               candidates.push({ date: ymd(today), diff: 0 });
          }
          if (s.remind_after_days > 0) {
               const d = new Date(today);
               d.setUTCDate(d.getUTCDate() - s.remind_after_days);
               candidates.push({ date: ymd(d), diff: -s.remind_after_days });
          }
          if (candidates.length === 0) continue;

          const { data: invoices, error: invErr } = await supa
               .from("invoices")
               .select(
                    "id, user_id, invoice_number, customer_name, total, currency, due_date, status",
               )
               .eq("user_id", s.user_id)
               .in("status", ["sent", "partial", "overdue"])
               .in("due_date", candidates.map((c) => c.date));

          if (invErr) {
               console.error(`invoices query failed for ${s.user_id}: ${invErr.message}`);
               continue;
          }
          if (!invoices || invoices.length === 0) continue;

          // 3. Load all active devices for this user (one query, reuse across invoices).
          const { data: devices, error: devErr } = await supa
               .from("user_devices")
               .select("fcm_token, platform")
               .eq("user_id", s.user_id)
               .eq("is_active", true);

          if (devErr) {
               console.error(`devices query failed for ${s.user_id}: ${devErr.message}`);
               continue;
          }
          if (!devices || devices.length === 0) {
               skipped += invoices.length;
               continue;
          }

          for (const inv of invoices as InvoiceRow[]) {
               scanned++;
               const diff = daysDiff(today, inv.due_date);
               const reminderType = reminderTypeFor(diff, s);
               if (reminderType == null) continue;

               const { title, body } = renderTemplate(
                    s.message_template ?? "",
                    inv,
                    diff,
               );

               // 4. Skip if we've already logged a successful send today for this
               //    invoice + reminder_type (idempotency for re-runs).
               const { data: existing } = await supa
                    .from("reminder_logs")
                    .select("id")
                    .eq("invoice_id", inv.id)
                    .eq("reminder_type", reminderType)
                    .eq("status", "sent")
                    .gte("sent_at", `${ymd(today)}T00:00:00Z`)
                    .limit(1);

               if (existing && existing.length > 0) {
                    skipped++;
                    continue;
               }

               for (const d of devices as DeviceRow[]) {
                    if (dryRun) {
                         console.log(
                              `[dryRun] -> ${d.fcm_token.slice(0, 8)}… ${title} | ${body}`,
                         );
                         sent++;
                         continue;
                    }

                    const result = await sendFcm({
                         accessToken,
                         projectId: FCM_PROJECT_ID,
                         token: d.fcm_token,
                         title,
                         body,
                         data: {
                              invoice_id: inv.id,
                              reminder_type: reminderType,
                         },
                    });

                    await supa.from("reminder_logs").insert({
                         user_id: inv.user_id,
                         invoice_id: inv.id,
                         reminder_type: reminderType,
                         channel: "push",
                         status: result.ok ? "sent" : "failed",
                         sent_at: result.ok ? new Date().toISOString() : null,
                         error_message: result.ok ? null : result.error,
                    });

                    if (result.ok) {
                         sent++;
                    } else {
                         failed++;
                         console.error(
                              `FCM send failed for invoice ${inv.id}: ${result.error}`,
                         );

                         // Auto-deactivate clearly-bad tokens (UNREGISTERED / INVALID_ARGUMENT).
                         if (
                              result.error?.includes("UNREGISTERED") ||
                              result.error?.includes("registration-token-not-registered")
                         ) {
                              await supa
                                   .from("user_devices")
                                   .update({ is_active: false })
                                   .eq("fcm_token", d.fcm_token);
                         }
                    }
               }
          }
     }

     return new Response(
          JSON.stringify({ scanned, sent, failed, skipped, dryRun }),
          { headers: { "Content-Type": "application/json" } },
     );
});
