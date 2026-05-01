QuoSwift Schema

create table public.business_profiles (
  id                      uuid primary key default gen_random_uuid(),
  user_id                 uuid not null unique references auth.users(id) on delete cascade,
  business_name           text not null,
  phone                   text,
  email                   text,
  address                 text,
  logo_url                text,
  currency                text not null default 'MYR',
  payment_instructions    text,
  default_quotation_notes text,
  default_invoice_notes   text,
  quotation_prefix        text not null default 'Q-',
  invoice_prefix          text not null default 'INV-',
  quotation_next_number   integer not null default 1,
  invoice_next_number     integer not null default 1,
  timezone                text not null default 'Asia/Kuala_Lumpur',
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

create table public.customers (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  name            text not null,
  company_name    text,
  phone           text,
  whatsapp_number text,
  email           text,
  billing_address text,
  notes           text,
  is_archived     boolean not null default false,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index customers_user_id_idx on public.customers(user_id);
create index customers_is_archived_idx on public.customers(is_archived);

create table public.quotations (
  id                   uuid primary key default gen_random_uuid(),
  user_id              uuid not null references auth.users(id) on delete cascade,
  customer_id          uuid not null references public.customers(id) on delete restrict,
  quotation_number     text not null,
  issue_date           date not null,
  valid_until          date,
  currency             text not null default 'MYR',
  subtotal             numeric(12,2) not null default 0,
  discount_amount      numeric(12,2) not null default 0,
  total_amount         numeric(12,2) not null default 0,
  notes                text,
  payment_instructions text,
  status               text not null default 'draft',
  converted_invoice_id uuid,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  unique(user_id, quotation_number)
);
create index quotations_user_id_idx on public.quotations(user_id);
create index quotations_customer_id_idx on public.quotations(customer_id);
create index quotations_status_idx on public.quotations(status);

create table public.quotation_items (
  id           uuid primary key default gen_random_uuid(),
  quotation_id uuid not null references public.quotations(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  item_name    text not null,
  description  text,
  quantity     numeric(12,2) not null default 1,
  unit_price   numeric(12,2) not null default 0,
  line_total   numeric(12,2) not null default 0,
  sort_order   integer not null default 0,
  created_at   timestamptz not null default now()
);
create index quotation_items_quotation_id_idx on public.quotation_items(quotation_id);
create index quotation_items_user_id_idx on public.quotation_items(user_id);

create table public.invoices (
  id                   uuid primary key default gen_random_uuid(),
  user_id              uuid not null references auth.users(id) on delete cascade,
  customer_id          uuid not null references public.customers(id) on delete restrict,
  source_quotation_id  uuid references public.quotations(id) on delete set null,
  invoice_number       text not null,
  issue_date           date not null,
  due_date             date not null,
  currency             text not null default 'MYR',
  subtotal             numeric(12,2) not null default 0,
  discount_amount      numeric(12,2) not null default 0,
  total_amount         numeric(12,2) not null default 0,
  amount_paid          numeric(12,2) not null default 0,
  balance_due          numeric(12,2) not null default 0,
  notes                text,
  payment_instructions text,
  status               text not null default 'draft',
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  unique(user_id, invoice_number)
);
create index invoices_user_id_idx on public.invoices(user_id);
create index invoices_customer_id_idx on public.invoices(customer_id);
create index invoices_status_idx on public.invoices(status);
create index invoices_due_date_idx on public.invoices(due_date);
create index invoices_balance_due_idx on public.invoices(balance_due);

create table public.invoice_items (
  id          uuid primary key default gen_random_uuid(),
  invoice_id  uuid not null references public.invoices(id) on delete cascade,
  user_id     uuid not null references auth.users(id) on delete cascade,
  item_name   text not null,
  description text,
  quantity    numeric(12,2) not null default 1,
  unit_price  numeric(12,2) not null default 0,
  line_total  numeric(12,2) not null default 0,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now()
);
create index invoice_items_invoice_id_idx on public.invoice_items(invoice_id);
create index invoice_items_user_id_idx on public.invoice_items(user_id);

create table public.payments (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  invoice_id     uuid not null references public.invoices(id) on delete cascade,
  amount         numeric(12,2) not null,
  payment_date   date not null,
  payment_method text,
  reference_note text,
  created_at     timestamptz not null default now()
);
create index payments_user_id_idx on public.payments(user_id);
create index payments_invoice_id_idx on public.payments(invoice_id);

create table public.reminder_settings (
  id                        uuid primary key default gen_random_uuid(),
  user_id                   uuid not null unique references auth.users(id) on delete cascade,
  remind_before_days        integer not null default 3,
  remind_on_due_date        boolean not null default true,
  remind_after_days         integer not null default 3,
  enable_push_notifications  boolean not null default true,
  enable_local_notifications boolean not null default true,
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now()
);

create table public.user_devices (
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
create index user_devices_user_id_idx on public.user_devices(user_id);
create index user_devices_is_active_idx on public.user_devices(is_active);

create table public.reminder_logs (
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
create index reminder_logs_user_id_idx on public.reminder_logs(user_id);
create index reminder_logs_invoice_id_idx on public.reminder_logs(invoice_id);

-- Enable RLS on all tables
alter table public.business_profiles enable row level security;
alter table public.customers enable row level security;
alter table public.quotations enable row level security;
alter table public.quotation_items enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_items enable row level security;
alter table public.payments enable row level security;
alter table public.reminder_settings enable row level security;
alter table public.user_devices enable row level security;
alter table public.reminder_logs enable row level security;

-- business_profiles
create policy "Users manage own profile"
  on public.business_profiles for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- customers
create policy "Users manage own customers"
  on public.customers for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- quotations
create policy "Users manage own quotations"
  on public.quotations for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- quotation_items
create policy "Users manage own quotation items"
  on public.quotation_items for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- invoices
create policy "Users manage own invoices"
  on public.invoices for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- invoice_items
create policy "Users manage own invoice items"
  on public.invoice_items for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- payments
create policy "Users manage own payments"
  on public.payments for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- reminder_settings
create policy "Users manage own reminder settings"
  on public.reminder_settings for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- user_devices
create policy "Users manage own devices"
  on public.user_devices for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- reminder_logs
create policy "Users manage own reminder logs"
  on public.reminder_logs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

