# QuoSwift — Manual Test Plan

**Version:** v1 — Core Flow (FCM excluded)  
**Date:** 2 May 2026  
**Tester:** _______________  
**Device / OS:** _______________

> Work through each block **in order**. A block must fully pass before the next block can be meaningfully tested (see dependency table at the bottom). Mark each row ✅ Pass / ❌ Fail / ⏭ Skip.

---

## Block 1 — Authentication

| # | Action | Expected result | Status |
|---|--------|----------------|--------|
| 1.1 | Open app with no existing session | Splash → Login screen | |
| 1.2 | Tap **Register** → enter name, email, strong password → submit | Redirects to Business Setup screen | |
| 1.3 | Kill app → reopen | Splash → Business Setup (session persisted, no re-login prompt) | |
| 1.4 | Complete Business Setup: enter business name, select currency → **Save** | Redirects to Dashboard | |
| 1.5 | Kill app → reopen | Splash → Dashboard directly (session + profile both found) | |
| 1.6 | Settings → **Sign out** | Redirects to Login, session cleared | |
| 1.7 | Login with correct email + password | Redirects to Dashboard | |
| 1.8 | Login with wrong password | Error snackbar shown, stays on Login screen | |
| 1.9 | Tap **Forgot Password** → enter registered email → submit | Success message shown (no crash) | |

---

## Block 2 — Business Profile & Settings

| # | Action | Expected result | Status |
|---|--------|----------------|--------|
| 2.1 | Settings → **Business Profile** | All fields pre-filled with previously saved data | |
| 2.2 | Change business name → **Save** | Snackbar confirms save; name reflects across app | |
| 2.3 | Tap logo area → pick an image | Thumbnail appears; logo URL saved to Supabase Storage | |
| 2.4 | Settings → **Numbering** → set Invoice prefix `INV-`, next number `5` → Save | Saved; next new invoice will be `INV-0005` | |
| 2.5 | Settings → **Default Notes** → enter invoice notes → **Save** | Saved (verify in Supabase: `default_invoice_notes` column updated) | |
| 2.6 | Settings → **Reminder Settings** → toggle on, set 3 days before → **Save** | Saved without error | |

---

## Block 3 — Customers

| # | Action | Expected result | Status |
|---|--------|----------------|--------|
| 3.1 | Open **Customers** tab with no data | Empty state: "No customers yet" with **Add** button | |
| 3.2 | Add customer: name, email, phone, address → **Save** | Card appears in customer list | |
| 3.3 | Tap customer card | Detail screen shows all entered data correctly | |
| 3.4 | Edit customer → change phone number → **Save** | Updated phone shown in detail screen | |
| 3.5 | Add 3 more customers (total 4) | All 4 cards appear in list | |
| 3.6 | Archive one customer via menu | Customer removed from active list (not deleted) | |
| 3.7 | Show archived (toggle/filter if available) | Archived customer reappears | |
| 3.8 | Restore archived customer | Customer back in active list | |

---

## Block 4 — Quotations

| # | Action | Expected result | Status |
|---|--------|----------------|--------|
| 4.1 | Open **Quotations** tab with no data | Empty state: "No quotations yet" | |
| 4.2 | New quotation → select customer, add 2 line items → **Save** | Number auto-assigned `Q-0001`; card appears in list | |
| 4.3 | Open quotation detail | Customer name, line items, subtotal, total all correct | |
| 4.4 | Edit → change quantity on a line item → **Save** | Total recalculates correctly | |
| 4.5 | Create a 2nd quotation | Numbered `Q-0002`; both cards in list | |
| 4.6 | Change status to **Sent** | Status pill updates in list and detail | |
| 4.7 | Change status to **Accepted** | Status pill updates | |
| 4.8 | 3-dot menu → **Export / Print PDF** | OS print preview opens; business name, line items, total visible | |
| 4.9 | 3-dot menu → **Share PDF** | OS share sheet opens with PDF file attached | |
| 4.10 | 3-dot menu → **WhatsApp** | WhatsApp opens (or URL launcher) with pre-filled message | |

---

## Block 5 — Invoices

| # | Action | Expected result | Status |
|---|--------|----------------|--------|
| 5.1 | Open **Invoices** tab with no data | Empty state: "No invoices yet" | |
| 5.2 | New invoice → select customer, add line items, set due date → **Save** | Number `INV-0005` (from Block 2.4 numbering); card in list | |
| 5.3 | Open invoice detail | All fields correct; status = **Draft** | |
| 5.4 | Change status to **Sent** | Status pill = SENT | |
| 5.5 | Edit due date to yesterday → save → reopen | Status auto-computes to **Overdue** | |
| 5.6 | 3-dot menu → **Export / Print PDF** | OS print preview with correct invoice data | |
| 5.7 | 3-dot menu → **Share PDF** | OS share sheet with PDF attached | |
| 5.8 | Create a 2nd invoice | Numbered `INV-0006` | |

---

## Block 6 — Quotation → Invoice Conversion

> Requires Block 4 to have at least one **Accepted** quotation.

| # | Action | Expected result | Status |
|---|--------|----------------|--------|
| 6.1 | Open an **Accepted** quotation | **Convert to Invoice** button visible | |
| 6.2 | Tap **Convert to Invoice** | New invoice created (e.g. `INV-0007`); navigates to invoice detail | |
| 6.3 | Check converted invoice | Customer, line items, total match original quotation exactly | |
| 6.4 | Go back to original quotation | Status is now **Accepted** / converted (not editable to a new invoice again) | |

---

## Block 7 — Payments

> Requires Block 5 to have at least one **Sent** invoice.

| # | Action | Expected result | Status |
|---|--------|----------------|--------|
| 7.1 | Open a **Sent** invoice | **Record Payment** button visible | |
| 7.2 | Record partial payment (e.g. 50% of total) | Status → **Partial**; `amount_paid` and `balance_due` update | |
| 7.3 | Reopen invoice detail | Amount paid + balance due displayed correctly | |
| 7.4 | Record remaining balance | Status → **Paid**; `balance_due` = 0 | |
| 7.5 | Check invoice in list | Status pill = PAID | |

---

## Block 8 — Dashboard

> Run last — validates all data flows into the summary correctly.

| # | Action | Expected result | Status |
|---|--------|----------------|--------|
| 8.1 | Open **Dashboard** | Revenue, outstanding, and overdue figures reflect real data from Blocks 4–7 | |
| 8.2 | Verify a just-paid invoice is reflected | Revenue figure includes the payment recorded in Block 7 | |
| 8.3 | Pull down to refresh | Numbers update without error | |
| 8.4 | Recent activity section | Shows latest invoices / quotations in correct chronological order | |

---

## Block 9 — UX & Edge Cases

| # | Action | Expected result | Status |
|---|--------|----------------|--------|
| 9.1 | Kill app mid-form fill → reopen | Form resets cleanly; no crash; no stale data shown | |
| 9.2 | Submit any form with required fields empty | Inline validation errors shown; form does not submit | |
| 9.3 | Enter a very long customer name (100+ chars) | UI wraps correctly; no overflow or clipping | |
| 9.4 | Turn off WiFi → open Invoices list | Error state shown with **Try again** button | |
| 9.5 | Tap **Try again** with WiFi restored | List loads correctly; shimmer then real data | |
| 9.6 | Rapidly switch between all 5 bottom-nav tabs | No crashes, no blank screens, no duplicate navigation | |
| 9.7 | Press back on a form with unsaved changes | Navigates back without crash; no data corruption | |

---

## Block Dependency Map

```
Block 1 (Auth)
    └── Block 2 (Settings / Profile)
            └── Block 3 (Customers)
                    ├── Block 4 (Quotations)
                    │       └── Block 6 (Q → Invoice conversion)
                    └── Block 5 (Invoices)
                            └── Block 7 (Payments)
                                    └── Block 8 (Dashboard)

Block 9 (UX edge cases) — can be run alongside any block
```

---

## Bugs Found

| # | Block | Screen | Steps to reproduce | Expected | Actual | Severity |
|---|-------|--------|--------------------|----------|--------|----------|
| | | | | | | |
| | | | | | | |

> **Severity:** 🔴 Blocker / 🟠 Major / 🟡 Minor / 🟢 Cosmetic
