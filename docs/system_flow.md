# QuoSwift — System Architecture & Sequence Flows

End-to-end logic flows for the production app. All diagrams are Mermaid
(renders natively on GitHub and most Markdown viewers).

---

## 1. High-level component map

```mermaid
flowchart LR
  subgraph Mobile["Flutter App (Android / iOS)"]
    UI[Screens & Widgets]
    RV[Riverpod Providers]
    REPO[Repositories<br/>Supabase + Mock]
    FCM[FirebaseMessagingService]
    LOCAL[LocalNotificationService]
    PDF[DocumentPdfService<br/>+ Share/WhatsApp]
  end

  subgraph Supabase["Supabase Cloud"]
    AUTH[(GoTrue Auth)]
    DB[(Postgres + RLS)]
    STORAGE[(Storage<br/>logos)]
    FN[Edge Function<br/>send-reminders]
    CRON[(pg_cron + pg_net)]
  end

  subgraph Google["Google / Firebase"]
    OAUTH[OAuth2<br/>Service Account]
    FCMAPI[FCM HTTP v1 API]
    APNS[Apple APNs]
  end

  UI --> RV --> REPO
  REPO -->|REST + Realtime| AUTH
  REPO -->|REST + Realtime + RLS| DB
  REPO -->|upload| STORAGE
  FCM -->|register token| REPO
  PDF -->|share_plus / printing| UI

  CRON -->|HTTP POST + X-Cron-Secret| FN
  FN -->|service-role read| DB
  FN -->|JWT exchange| OAUTH
  OAUTH -->|access_token| FN
  FN -->|send v1| FCMAPI
  FCMAPI --> APNS
  FCMAPI -.push.-> FCM
  APNS -.push.-> FCM
  FCM --> LOCAL
```

---

## 2. App startup & session resume

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant M as main.dart
  participant FB as Firebase
  participant FMS as FirebaseMessagingService
  participant LNS as LocalNotificationService
  participant SB as Supabase
  participant App as App (Riverpod root)
  participant Splash as SplashScreen
  participant Router as GoRouter

  U->>M: Launch app
  M->>FB: Firebase.initializeApp()
  M->>FMS: registerBackgroundHandler()<br/>init() (channels + iOS opts)
  M->>LNS: init() (timezone + channels)
  M->>SB: Supabase.initialize(url, anonKey)
  M->>App: runApp(ProviderScope)
  App->>Splash: route '/'
  Splash->>SB: authSessionProvider.first
  alt session != null
    Splash->>Router: go('/dashboard')
    App->>FMS: requestPermissionAndGetToken()
    FMS-->>App: fcmToken
    App->>SB: upsert user_devices(fcm_token, platform)
    App->>FMS: registerHandlers(onOpenedApp → /invoices/:id)
  else session == null
    Splash->>Router: go('/login')
  end
```

---

## 3. Authentication — sign-in / sign-up / forgot password

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant Login as LoginScreen
  participant Auth as authServiceProvider
  participant SB as Supabase Auth
  participant Router as GoRouter
  participant BP as businessProfileProvider

  U->>Login: email + password → Sign in
  Login->>Auth: signIn(email, password)
  Auth->>SB: signInWithPassword(...)
  alt success
    SB-->>Auth: Session(jwt, user)
    Auth-->>Login: ok
    Login->>BP: invalidate (refetch)
    BP->>SB: select business_profiles where user_id=auth.uid()
    alt profile exists
      Router->>Router: go('/dashboard')
    else no profile
      Router->>Router: go('/setup')
    end
  else error
    SB-->>Auth: AuthException
    Auth-->>Login: rethrow
    Login->>U: SnackBar(error.message)
  end
```

---

## 4. Customer / Quotation / Invoice CRUD (representative flow)

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant Form as QuotationFormScreen
  participant QP as quotationsProvider (Riverpod)
  participant Repo as SupabaseQuotationRepository
  participant SB as Supabase Postgres (RLS)
  participant List as QuotationsScreen

  U->>Form: Fill header + line items → Save
  Form->>Repo: create(quotation)
  Repo->>SB: select quotation_prefix, quotation_next_number<br/>from business_profiles where user_id=auth.uid()
  SB-->>Repo: Q-, 17
  Repo->>SB: insert quotations (number=Q-0017, ...) returning *
  Repo->>SB: insert quotation_items(...)
  Repo->>SB: update business_profiles set quotation_next_number=18
  SB-->>Repo: row
  Repo-->>Form: Quotation
  Form->>QP: invalidate
  QP->>SB: stream quotations where user_id=auth.uid()
  SB-->>QP: live rows
  QP-->>List: AsyncData(list)
  List-->>U: card appears (animated)
```

---

## 5. Quotation → Invoice conversion

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant Detail as QuotationDetailScreen
  participant QRepo as SupabaseQuotationRepository
  participant IRepo as SupabaseInvoiceRepository
  participant SB as Postgres

  U->>Detail: Tap "Convert to Invoice"
  Detail->>QRepo: convertToInvoice(quotationId)
  QRepo->>SB: select quotation + items
  QRepo->>IRepo: create(Invoice.fromQuotation(...))
  IRepo->>SB: allocate invoice number (INV-####)
  IRepo->>SB: insert invoices + invoice_items
  IRepo-->>QRepo: Invoice
  QRepo->>SB: update quotations set status='accepted'
  QRepo-->>Detail: Invoice
  Detail->>Detail: go('/invoices/:newId')
```

---

## 6. Record payment

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant Dialog as RecordPaymentDialog
  participant PRepo as SupabasePaymentRepository
  participant SB as Postgres
  participant IList as invoicesProvider

  U->>Dialog: amount + method + date → Save
  Dialog->>PRepo: record(payment)
  PRepo->>SB: insert payments(invoice_id, amount, ...)
  PRepo->>SB: update invoices<br/>set amount_paid = amount_paid + :amt,<br/>balance_due = total - amount_paid,<br/>status = case when balance_due=0 then 'paid' when amount_paid>0 then 'partial' else status end
  SB-->>PRepo: updated invoice
  PRepo-->>Dialog: ok
  Dialog->>IList: invalidate → realtime stream re-emits
  IList-->>U: status pill switches to PAID / PARTIAL
```

---

## 7. PDF export & share

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant Menu as DocumentActionsMenu
  participant PDF as DocumentPdfService
  participant Share as DocumentShareService
  participant OS as OS Sheet

  U->>Menu: Tap Export / Share / WhatsApp
  Menu->>PDF: buildInvoicePdf(invoice, businessProfile)
  PDF-->>Menu: Uint8List bytes
  alt Export / Print
    Menu->>Share: previewPdf(bytes)
    Share->>OS: Printing.layoutPdf(...)
  else Share
    Menu->>Share: sharePdf(bytes, fileName)
    Share->>OS: SharePlus.share(XFile pdf)
  else WhatsApp
    Menu->>Share: openWhatsApp(phone, message)
    Share->>OS: url_launcher(wa.me/...)
  end
  OS-->>U: Share sheet / print preview
```

---

## 8. FCM token lifecycle (sign-in → token refresh → sign-out)

```mermaid
sequenceDiagram
  autonumber
  participant App as App shell
  participant Auth as authSessionProvider
  participant Reg as fcmTokenRegistrationProvider
  participant FMS as FirebaseMessagingService
  participant FCM as Firebase Cloud Messaging
  participant Repo as SupabaseUserDeviceRepository
  participant DB as user_devices table

  App->>Auth: watch session
  Auth-->>Reg: Session(user)
  Reg->>FMS: requestPermissionAndGetToken()
  FMS->>FCM: getAPNSToken() (iOS only, polled)
  FMS->>FCM: getToken()
  FCM-->>FMS: fcmToken
  FMS-->>Reg: token
  Reg->>Repo: registerToken(token, platform: ios/android)
  Repo->>DB: upsert on conflict(fcm_token)<br/>set is_active=true, user_id=auth.uid()

  Note over FMS,FCM: Later — FCM rotates token
  FCM-->>FMS: onTokenRefresh
  FMS-->>Reg: tokenStream emits new token
  Reg->>Repo: registerToken(newToken)
  Repo->>DB: upsert (old row stays, new row added)

  Note over App,DB: User signs out
  Auth-->>Reg: Session(null)
  Reg->>FMS: deleteToken()
  Reg->>Repo: deactivateToken(lastToken)
  Repo->>DB: update set is_active=false where fcm_token=:t
```

---

## 9. Daily reminder dispatch (the big one)

```mermaid
sequenceDiagram
  autonumber
  participant Cron as pg_cron (01:00 UTC)
  participant Net as pg_net.http_post
  participant Fn as Edge Function<br/>send-reminders
  participant DB as Postgres (service role)
  participant OAuth as oauth2.googleapis.com
  participant FCM as fcm.googleapis.com/v1
  participant Device as User device

  Cron->>Net: SELECT cron.schedule('0 1 * * *', ...)
  Net->>Fn: POST /functions/v1/send-reminders<br/>X-Cron-Secret: ****
  Fn->>Fn: validate header == CRON_SECRET (env)
  Fn->>DB: select * from reminder_settings<br/>where enable_push_notifications = true

  loop for each user
    Fn->>DB: select invoices where user_id=:u<br/>and status in ('sent','partial','overdue')
    Fn->>Fn: filter by due_date in {today+N, today, today-M}
    Fn->>DB: select fcm_token from user_devices<br/>where user_id=:u and is_active=true
  end

  alt has candidates
    Fn->>DB: select * from reminder_logs<br/>where invoice_id in (...) and reminder_type=...<br/>and date_trunc('day', created_at) = today
    Fn->>Fn: skip already-sent (idempotency)

    Fn->>Fn: build service-account JWT (RS256)
    Fn->>OAuth: POST token (grant=jwt-bearer)
    OAuth-->>Fn: access_token (1h)

    loop for each (invoice, device)
      Fn->>FCM: POST projects/quoswift-1c795/messages:send<br/>Authorization: Bearer access_token<br/>{ token, notification, data }
      alt 200 OK
        FCM-->>Fn: { name }
        FCM-->>Device: push (data: invoice_id, type)
        Fn->>DB: insert reminder_logs(status='sent', sent_at=now)
      else 404 UNREGISTERED
        FCM-->>Fn: error
        Fn->>DB: update user_devices set is_active=false where fcm_token=:t
        Fn->>DB: insert reminder_logs(status='failed', error_message='UNREGISTERED')
      else other error
        FCM-->>Fn: error
        Fn->>DB: insert reminder_logs(status='failed', error_message=msg)
      end
    end
  end

  Fn-->>Net: { scanned, sent, failed, skipped }
```

---

## 10. Push received → user taps notification

```mermaid
sequenceDiagram
  autonumber
  participant Device as Device OS
  participant FBSDK as firebase_messaging
  participant FMS as FirebaseMessagingService
  participant LNS as LocalNotificationService
  participant App as App (foreground)
  participant Router as GoRouter

  alt App foregrounded
    Device->>FBSDK: data + notification payload
    FBSDK-->>FMS: onMessage stream
    FMS->>LNS: show local heads-up notification
    LNS-->>Device: banner displayed
  else App backgrounded
    Device->>FBSDK: payload (handled natively)
    FBSDK-->>Device: system tray notification
  else App terminated
    Device->>FBSDK: payload, app launches
    FBSDK-->>FMS: getInitialMessage()
  end

  Note over Device,Router: User taps banner
  Device->>FBSDK: tap event
  FBSDK-->>FMS: onMessageOpenedApp / getInitialMessage
  FMS->>App: callback(message.data['invoice_id'])
  App->>Router: go('/invoices/' + invoice_id)
  Router-->>App: InvoiceDetailScreen
```

---

## 11. Realtime list updates (RLS-scoped subscription)

```mermaid
sequenceDiagram
  autonumber
  participant Screen as InvoicesScreen
  participant Provider as invoicesProvider (Stream)
  participant Repo as SupabaseInvoiceRepository
  participant Realtime as Supabase Realtime
  participant DB as Postgres

  Screen->>Provider: ref.watch
  Provider->>Repo: watchAll()
  Repo->>Realtime: from('invoices').stream(primaryKey: id).eq('user_id', uid)
  Realtime->>DB: subscribe to changes filtered by RLS
  DB-->>Realtime: INSERT / UPDATE / DELETE events for this user only
  Realtime-->>Repo: List<Map>
  Repo-->>Provider: List<Invoice>
  Provider-->>Screen: AsyncData → rebuild
```

---

## 12. RLS enforcement (every read/write)

```mermaid
flowchart TB
  Req[Flutter request<br/>+ user JWT] --> Auth{auth.uid<br/>extracted from JWT}
  Auth --> Policy{RLS policy:<br/>user_id = auth.uid}
  Policy -->|allow| Row[(Row visible / writable)]
  Policy -->|deny| Empty[Returns empty / 401]
```

---

## Sprint completion summary (production-ready)

| Sprint | Status | Notes |
| ------ | ------ | ----- |
| 1 — Backend & Auth | ✅ | Supabase init, RLS on all tables, session-resume on splash |
| 2 — Core CRUD | ✅ | Customers, Quotations, Invoices, Payments — all Supabase-backed |
| 3 — Business Logic | ✅ | Q→I conversion, prefix numbering, reminder settings, real dashboard |
| 4 — PDF & Share | ✅ | `pdf` + `printing` + `share_plus` + WhatsApp deep-link |
| 5 — Reminders / FCM | ✅ | Native init (Android+iOS), token registration, Edge Function + pg_cron |
| 6 — Polish & QA | ✅ | All settings wired to Supabase, shimmer skeletons, empty/error states, `flutter analyze` clean |

### Outstanding **operator** actions (not code)
1. Add `GoogleService-Info.plist` to Xcode Runner target.
2. Upload APNs `.p8` key in Firebase console → Cloud Messaging.
3. Run `supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat ~/Downloads/...adminsdk...json)"`.
4. Run `cron.schedule('daily-reminders', '0 1 * * *', …)` SQL block (Step 6 of Edge Function README).
