# Supabase V1 Integration Guide – QuoInv App

This guide walks you step-by-step through creating a new Supabase project, creating all tables, enabling Row-Level Security (RLS), and wiring the Flutter app to your live backend.

---

## 1. Create a New Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and sign in (or register).
2. Click **New project**.
3. Fill in:
   - **Organization** – your personal or team organisation
   - **Project name** – e.g. `quoinv-prod`
   - **Database password** – generate a strong password and save it safely
   - **Region** – choose the region closest to your users (e.g. `Southeast Asia (Singapore)` for Malaysian users)
4. Click **Create new project** and wait ~2 minutes for provisioning.

---

## 2. Get Your Project Credentials

From your project dashboard, go to **Settings → API**:

| Value | Where to find it |
|-------|-----------------|
| `SUPABASE_URL` | Project URL field, e.g. `https://xxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | `anon` `public` key under "Project API keys" |

You will need both values in Step 6.

---

## 3. Create the Database Tables

Open **SQL Editor** in the Supabase Dashboard and run the SQL below in order.

### 3.1 business_profiles

```sql
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
```

### 3.2 customers

```sql
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
```

### 3.3 quotations

```sql
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
```

### 3.4 quotation_items

```sql
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
```

### 3.5 invoices

```sql
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
```

### 3.6 invoice_items

```sql
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
```

### 3.7 payments

```sql
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
```

### 3.8 reminder_settings

```sql
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
```

### 3.9 user_devices

```sql
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
```

### 3.10 reminder_logs

```sql
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
```

---

## 4. Enable Row-Level Security (RLS)

RLS ensures every user can only read and write their own data. Run this SQL in the **SQL Editor**:

```sql
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
```

---

## 5. Configure Supabase Auth

1. In the Supabase Dashboard, go to **Authentication → Providers**.
2. **Email** provider is enabled by default. Keep it on.
3. Under **Authentication → Email Templates**, customise the Confirm Email and Reset Password templates to match your brand if desired.
4. Under **Authentication → URL Configuration**, set:
   - **Site URL** – your app's deep-link base URL (e.g. `io.quoinv.app://`)
   - **Redirect URLs** – add `io.quoinv.app://login-callback`

---

## 6. Add Supabase to the Flutter App

### 6.1 Add environment variables

Create `lib/core/env/env.dart` (never commit real keys – use `--dart-define` or a `.env` approach):

```dart
// lib/core/env/env.dart
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
```

Run the app with:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### 6.2 Initialise Supabase in `main.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/env/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: App()));
}

/// Convenience getter – use anywhere in the app.
SupabaseClient get supabase => Supabase.instance.client;
```

### 6.3 Add a Supabase client provider

```dart
// lib/shared/providers/supabase_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((_) {
  return Supabase.instance.client;
});
```

---

## 7. Implement Supabase Repository Classes

For each entity, create a `Supabase*Repository` that implements the same abstract interface. The rest of the app keeps working unchanged – you only swap the provider wire-up.

### Example – SupabaseBusinessProfileRepository

```dart
// lib/data/supabase/supabase_business_profile_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/business_profile.dart';
import '../repositories/business_profile_repository.dart';

class SupabaseBusinessProfileRepository implements BusinessProfileRepository {
  SupabaseBusinessProfileRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'business_profiles';

  @override
  Future<BusinessProfile?> fetch() async {
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', _client.auth.currentUser!.id)
        .maybeSingle();
    return data == null ? null : _fromMap(data);
  }

  @override
  Future<BusinessProfile> save(BusinessProfile profile) async {
    final map = _toMap(profile);
    final data = await _client
        .from(_table)
        .upsert(map, onConflict: 'user_id')
        .select()
        .single();
    return _fromMap(data);
  }

  @override
  Stream<BusinessProfile?> watch() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', _client.auth.currentUser!.id)
        .map((rows) => rows.isEmpty ? null : _fromMap(rows.first));
  }

  Map<String, dynamic> _toMap(BusinessProfile p) => {
        'id': p.id,
        'user_id': _client.auth.currentUser!.id,
        'business_name': p.businessName,
        'phone': p.phone,
        'email': p.email,
        'address': p.address,
        'logo_url': p.logoUrl,
        'currency': p.currency,
        'payment_instructions': p.paymentInstructions,
        'default_quotation_notes': p.defaultQuotationNotes,
        'default_invoice_notes': p.defaultInvoiceNotes,
        'quotation_prefix': p.quotationPrefix,
        'invoice_prefix': p.invoicePrefix,
        'quotation_next_number': p.quotationNextNumber,
        'invoice_next_number': p.invoiceNextNumber,
        'timezone': p.timezone,
        'updated_at': DateTime.now().toIso8601String(),
      };

  BusinessProfile _fromMap(Map<String, dynamic> m) => BusinessProfile(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        businessName: m['business_name'] as String,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        address: m['address'] as String?,
        logoUrl: m['logo_url'] as String?,
        currency: m['currency'] as String? ?? 'MYR',
        paymentInstructions: m['payment_instructions'] as String?,
        defaultQuotationNotes: m['default_quotation_notes'] as String?,
        defaultInvoiceNotes: m['default_invoice_notes'] as String?,
        quotationPrefix: m['quotation_prefix'] as String? ?? 'Q-',
        invoicePrefix: m['invoice_prefix'] as String? ?? 'INV-',
        quotationNextNumber: m['quotation_next_number'] as int? ?? 1,
        invoiceNextNumber: m['invoice_next_number'] as int? ?? 1,
        timezone: m['timezone'] as String? ?? 'Asia/Kuala_Lumpur',
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? ''),
        updatedAt: DateTime.tryParse(m['updated_at'] as String? ?? ''),
      );
}
```

Follow the same pattern for `SupabaseCustomerRepository`, `SupabaseInvoiceRepository`, `SupabaseQuotationRepository`, and `SupabasePaymentRepository`.

---

## 8. Swap Providers from Mock to Supabase

When you are ready to go live, update `lib/shared/providers/repository_providers.dart` and `lib/shared/providers/business_profile_provider.dart`:

```dart
// lib/shared/providers/business_profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase/supabase_business_profile_repository.dart';
import '../models/business_profile.dart';
import 'supabase_provider.dart';

final businessProfileRepositoryProvider =
    Provider<BusinessProfileRepository>((ref) {
  return SupabaseBusinessProfileRepository(
    ref.watch(supabaseClientProvider),
  );
});
```

```dart
// lib/shared/providers/repository_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase/supabase_customer_repository.dart';
import '../../data/supabase/supabase_invoice_repository.dart';
import '../../data/supabase/supabase_quotation_repository.dart';
import '../../data/supabase/supabase_payment_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/quotation_repository.dart';
import 'supabase_provider.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return SupabaseCustomerRepository(ref.watch(supabaseClientProvider));
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return SupabaseInvoiceRepository(ref.watch(supabaseClientProvider));
});

final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  return SupabaseQuotationRepository(ref.watch(supabaseClientProvider));
});

final paymentRepositoryProvider = Provider<SupabasePaymentRepository>((ref) {
  return SupabasePaymentRepository(ref.watch(supabaseClientProvider));
});
```

---

## 9. Auth Flow Integration

### 9.1 Register

```dart
final response = await supabase.auth.signUp(
  email: email,
  password: password,
);
// After sign-up, listen for email confirmation, then create business_profile row.
```

### 9.2 Login

```dart
await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);
// On success, check whether a business_profile row exists.
// If not → navigate to BusinessSetupScreen.
// If yes  → navigate to DashboardScreen.
```

### 9.3 Listen to auth state changes

In your router or app widget:

```dart
supabase.auth.onAuthStateChange.listen((data) {
  final session = data.session;
  if (session == null) {
    // Navigate to LoginScreen
  } else {
    // Navigate to DashboardScreen (or SetupScreen if profile missing)
  }
});
```

### 9.4 Logout

```dart
await supabase.auth.signOut();
```

---

## 10. Supabase Storage (Logo Upload)

1. In the Supabase Dashboard, go to **Storage → New bucket**.
2. Name it `business-logos`, set it to **private**.
3. Add a storage policy:

```sql
-- Allow authenticated users to manage their own logos
create policy "Users manage own logos"
  on storage.objects for all
  using (
    bucket_id = 'business-logos'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'business-logos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
```

4. Upload from Flutter:

```dart
final path = '${supabase.auth.currentUser!.id}/logo.png';
await supabase.storage.from('business-logos').uploadBinary(
  path,
  imageBytes,
  fileOptions: const FileOptions(upsert: true),
);
final logoUrl = supabase.storage.from('business-logos').getPublicUrl(path);
```

---

## 11. Checklist Before Go Live

- [ ] Replace all mock repository providers with Supabase implementations
- [ ] Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` via `--dart-define` in CI and release builds
- [ ] Verify RLS is enabled and policies tested for each table
- [ ] Test auth flow: register → email verify → login → setup → dashboard
- [ ] Test creating a customer, quotation, invoice, and recording a payment
- [ ] Test logo upload to Supabase Storage
- [ ] Test reminder settings save and load correctly
- [ ] Configure deep-link URL scheme in iOS (`Info.plist`) and Android (`AndroidManifest.xml`) for auth redirects
- [ ] Review Supabase project settings: disable "Confirm email" for MVP testing if needed, re-enable for production

---

## Schema Version Reference

| Table | V1 | Notes |
|---|---|---|
| `auth.users` | ✅ | Managed by Supabase Auth |
| `business_profiles` | ✅ | One row per user |
| `customers` | ✅ | |
| `quotations` + `quotation_items` | ✅ | |
| `invoices` + `invoice_items` | ✅ | |
| `payments` | ✅ | |
| `reminder_settings` | ✅ | One row per user |
| `user_devices` | ✅ | FCM tokens |
| `reminder_logs` | ✅ | Audit trail |
| `saved_items` | V2 | Not required for V1 |
| `document_activity_logs` | V2 | Not required for V1 |
