-- Sprint 5: device registry + reminder audit log
-- Idempotent — safe to re-run if you've already created either table from the
-- snippets in docs/Query.md.

create table if not exists public.user_devices (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  fcm_token    text not null unique,
  platform     text not null,
  device_name  text,
  is_active    boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists user_devices_user_id_idx
  on public.user_devices(user_id);
create index if not exists user_devices_is_active_idx
  on public.user_devices(is_active);

create table if not exists public.reminder_logs (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  invoice_id    uuid not null references public.invoices(id) on delete cascade,
  reminder_type text not null,
  channel       text not null,
  status        text not null default 'pending',
  sent_at       timestamptz,
  error_message text,
  created_at    timestamptz not null default now()
);
create index if not exists reminder_logs_user_id_idx
  on public.reminder_logs(user_id);
create index if not exists reminder_logs_invoice_id_idx
  on public.reminder_logs(invoice_id);

alter table public.user_devices  enable row level security;
alter table public.reminder_logs enable row level security;

drop policy if exists "Users manage own devices" on public.user_devices;
create policy "Users manage own devices"
  on public.user_devices for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users manage own reminder logs" on public.reminder_logs;
create policy "Users manage own reminder logs"
  on public.reminder_logs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Convenience: bump updated_at on user_devices.
create or replace function public.touch_user_devices_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists trg_user_devices_updated_at on public.user_devices;
create trigger trg_user_devices_updated_at
  before update on public.user_devices
  for each row execute function public.touch_user_devices_updated_at();
