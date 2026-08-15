# Personal Expense Tracker — Product & Technical Specification

**Status:** Draft v1.0
**Author:** Product spec for a single-user iOS app
**Owner:** Personal app — one user (App Store distribution, no multi-tenant backend required)

---

## 1. Overview

A personal, photo-first expense tracking app for iPhone. Every purchase — cash,
card, or online — gets logged with a photo of the receipt, invoice, or order
confirmation. The photo is retained permanently as the audit record; the app
extracts and indexes vendor, line items, amounts, and currency so that
everything is searchable and categorized without the user re-typing data by
hand.

### 1.1 Goals

1. **Capture everything.** No purchase should be too small or too fast to log
   — cash, card swipe, tap-to-pay, or an online checkout screenshot.
2. **Photo is the source of truth.** The original image is never altered or
   deleted; it's the audit trail if a number is ever questioned later.
3. **Structured data comes out of the photo automatically.** OCR extracts
   vendor, date, line items, and total so the user mostly confirms rather than
   types.
4. **One ledger, many currencies.** Every expense is logged in the currency it
   actually happened in, and everything rolls up into a home-currency view.
5. **Fast enough to use every time.** The capture flow must be faster than the
   user's temptation to skip logging a purchase.

### 1.2 Non-goals (v1)

- Multi-user / shared households / family accounts.
- Bank account linking or automatic transaction import (Plaid-style). May be
  considered later as a convenience *cross-check*, not a replacement for
  photo capture.
- Business/tax filing features (though the audit trail should make manual tax
  prep easier).
- Android. iOS only.

---

## 2. Core Principles

- **Local-first, private.** This is one person's financial data. Primary
  storage lives on-device; sync is for backup/multi-device convenience, not a
  shared backend.
- **Immutable audit trail.** Once a photo is attached to an expense, the
  original file is never overwritten or destroyed by an edit. Corrections to
  extracted data create a revision, not a photo replacement.
- **Currency-honest.** An expense is stored in the currency it was paid in.
  Conversion to a home/reporting currency is a display-layer calculation
  using the exchange rate at time of purchase, never a mutation of the
  original amount.
- **One unified feed regardless of source.** Cash, physical card, virtual
  card, and online/app purchases all land in the same list, filterable by
  source — there is no separate "online purchases" silo.

---

## 3. Feature Requirements

### 3.1 Capture

- **Camera capture** — primary entry point. Opens directly to camera from the
  home screen / app icon quick action / widget.
  - Multi-page receipts: attach 2+ photos to a single expense (e.g., long
    grocery receipt, invoice + payment confirmation).
  - Edge detection & auto-crop, perspective correction (like a document
    scanner), with a manual override.
  - Flash/low-light handling for crumpled receipts.
- **Import from Photos / Files** — for order confirmation emails saved as
  screenshots, PDFs forwarded from email, or receipts already in the photo
  library.
- **Screenshot capture for online purchases** — a share-sheet extension so
  the user can share a checkout confirmation screen (Amazon, Uber Eats,
  airline booking, etc.) directly into the app from Safari/Mail/any app.
- **No-photo fallback** — manual entry is always available (e.g., a cash tip
  with no receipt), but the app nudges toward attaching *something* (a photo
  of the item, a screenshot, or at minimum a typed note) since photo-first is
  the whole point of the app.
- **Voice-assisted quick add** (stretch) — Siri Shortcut / App Intent: "Log
  a $12 coffee at Blue Bottle" creates a draft expense pending photo/receipt.

### 3.2 Photo Repository & Audit Trail

- Every photo is stored **full-resolution, unedited**, alongside a
  perspective-corrected working copy used for OCR and thumbnails.
- Each photo record carries: capture timestamp, device, GPS location (if
  permitted), and a content hash (SHA-256) computed at capture time.
- Photos are **never deleted automatically**. Deleting an expense soft-deletes
  it (recoverable for 30 days) rather than immediately purging the image.
- **Export bundle**: on demand, generate a zip/PDF bundle of photos + a CSV/
  JSON ledger for a date range — e.g., for a tax preparer or a dispute with a
  vendor.
- Photos are encrypted at rest (see §7 Security).

### 3.3 OCR & Auto-Extraction

- On-device OCR (Apple Vision framework `VNRecognizeTextRequest` /
  `VNDocumentCameraViewController`) extracts:
  - Vendor/merchant name
  - Transaction date & time
  - Line items (description, quantity, unit price, line total) where the
    receipt format allows
  - Subtotal, tax, tip, total
  - Currency symbol/code if present
  - Payment method hints (e.g., "VISA •••• 4821" printed on receipt)
- Extraction results are presented as an **editable confirmation form**
  before saving — never silently trusted. Low-confidence fields are
  visually flagged.
- Vendor name is matched/normalized against a personal vendor directory
  (e.g., "SQ *BLUE BOTTLE #4" → "Blue Bottle Coffee") that the user can
  correct once and have it stick going forward (see §3.4).
- Line-item level categorization: a single Target or Amazon receipt can span
  multiple categories (groceries + household + electronics) — the app should
  support splitting one receipt across categories/items rather than forcing
  one category per receipt.

### 3.4 Vendors

- Auto-created from OCR/first entry; user can edit name, default category,
  logo/icon, and home currency for that vendor.
- Once a vendor is normalized/corrected, future receipts from the same raw
  merchant string auto-map to it.
- Vendor detail view: total spend, visit count, last visit, all linked
  expenses — effectively a per-merchant statement.

### 3.5 Categorization

- Default category set (editable/extensible): Groceries, Dining & Coffee,
  Transport, Fuel, Utilities, Rent/Housing, Health & Pharmacy, Shopping,
  Electronics, Entertainment & Subscriptions, Travel, Fees & Charges, Gifts,
  Education, Business, Cash Withdrawal, Other.
- Categories are hierarchical (parent/child), e.g. Travel → Flights, Travel →
  Hotels.
- Category is assignable at the **item level**, aggregating to the receipt.
- Auto-categorization: rule-based first (vendor → default category), with an
  on-device learned suggestion over time (e.g., Create ML text classifier on
  vendor name / item description). Always user-overridable, and the override
  feeds back into future suggestions for that vendor.
- Tags (freeform, multiple per expense) for cross-cutting concerns
  reimbursable, work travel, subscriptions, recurring, etc., independent of
  category.

### 3.6 Multi-Currency

- Every expense stores: `original_amount`, `original_currency`,
  `exchange_rate_to_home` (captured at time of entry), `home_amount`
  (computed), and `home_currency` (from Settings, changeable but historical
  entries keep the rate that was in effect when logged).
- Currency is auto-detected from OCR (symbol/ISO code) with manual override;
  defaults to the last-used currency for a given vendor/location to speed up
  repeat entries.
- Exchange rates: fetched from a rates API and cached locally daily; if
  offline, the most recent cached rate is used and the expense is flagged
  "rate as of [date]" until refreshed.
- Reports can be viewed in home currency (converted) or filtered/grouped
  per-currency (e.g., "everything I spent in EUR this trip").
- Manual rate override per-expense (for cash exchanged at a specific rate,
  e.g., airport kiosk rate vs. market rate).

### 3.7 Payment Methods & Sources

- Configurable list of payment methods: Cash, and any number of named cards/
  accounts (e.g., "Amex Gold", "Chase Debit", "Revolut EUR"), each with a
  type (credit/debit/cash/wallet), last-4 digits (optional, user-entered —
  never scanned/stored in full), default currency, and color/icon for quick
  visual scanning in lists.
- Source channel, independent of payment method: In-Person, Online, In-App,
  Subscription/Recurring. Lets the user filter "all online purchases"
  regardless of which card was used.
- Recurring/subscription detection: flag expenses that repeat with the same
  vendor + amount on a regular cadence, and surface an "active subscriptions"
  view.

### 3.8 Search

- Full-text search across vendor name, item descriptions, notes, and tags.
- Structured filters, combinable: date range, amount range, category
  (incl. children), vendor, payment method, source channel, currency,
  tag, "has photo" / "missing receipt".
- Saved searches / smart filters (e.g., "Groceries this month", "USD trip
  expenses > $50").
- Search results show thumbnail + amount + vendor + date; tapping opens full
  detail with the original photo.

### 3.9 Reports & Insights

- Spend by category (pie/bar), by vendor, by month/week, by payment method,
  by currency — all filterable by date range.
- Home-currency totals with an option to see "as originally spent."
- Monthly recap: total spend, top categories, top vendors, biggest single
  purchase, comparison to prior month.
- Budget thresholds per category (optional, soft alerts only — no hard
  blocking since this is a tracking app, not a budgeting-enforcement app).
- CSV/PDF export of any filtered view, plus the full photo-bundle export
  described in §3.2.

### 3.10 Sync, Backup & Multi-Device

- iCloud (CloudKit private database) sync across the user's own devices
  (iPhone + iPad), so photos and ledger are backed up off-device without
  standing up a custom backend.
- Local encrypted database is the primary store; CloudKit sync is best-effort
  and the app is fully usable offline.
- Periodic automatic export snapshot (e.g., monthly) to iCloud Drive/Files as
  a redundant backup independent of the app's own database, in case of data
  corruption.

---

## 4. Data Model

```
Expense
 - id (UUID)
 - date_time
 - vendor_id -> Vendor
 - source_channel: in_person | online | in_app | recurring
 - payment_method_id -> PaymentMethod
 - original_currency (ISO 4217)
 - original_amount (decimal)
 - exchange_rate_to_home (decimal, snapshot at entry time)
 - home_currency (ISO 4217, snapshot)
 - home_amount (decimal, computed = original_amount * rate)
 - subtotal, tax, tip (decimal, optional)
 - notes (text)
 - tags: [Tag]
 - items: [LineItem]
 - photos: [Photo]
 - status: draft | confirmed
 - created_at, updated_at
 - deleted_at (soft delete, nullable)

LineItem
 - id
 - expense_id -> Expense
 - description
 - quantity
 - unit_price
 - line_total
 - category_id -> Category

Vendor
 - id
 - display_name
 - raw_aliases: [string]   // raw OCR strings mapped to this vendor
 - default_category_id -> Category
 - default_currency
 - icon / logo
 - location (optional, lat/long + address)

Category
 - id
 - name
 - parent_id -> Category (nullable, for hierarchy)
 - icon / color

PaymentMethod
 - id
 - label
 - type: cash | credit | debit | wallet
 - last4 (optional, user-entered)
 - default_currency
 - color/icon

Photo
 - id
 - expense_id -> Expense
 - original_file_ref (full-res, immutable)
 - working_file_ref (cropped/corrected, used for OCR + display)
 - sha256_hash
 - captured_at
 - gps_lat, gps_long (optional)
 - device_info

Tag
 - id
 - name

ExchangeRateSnapshot
 - date
 - base_currency
 - rates: { currency_code: rate }
```

---

## 5. Key User Flows

### 5.1 Quick capture (the 90% path)

1. Tap camera quick-action (home screen icon long-press, widget, or in-app
   `+`).
2. Camera opens directly (no intermediate menu). Auto edge-detect and
   capture, or manual shutter.
3. App runs on-device OCR; shows a pre-filled confirmation form: vendor,
   date, total, currency, suggested category, suggested payment method
   (based on recent pattern).
4. User confirms or edits in ~2 taps for the common case ("looks right" →
   Save). Multi-item receipts show a collapsible item list with per-item
   category, editable inline.
5. Saved. Returns to the list/home screen showing the new entry at top.

### 5.2 Online purchase via share sheet

1. User completes checkout in Safari/Amazon app/Mail order-confirmation.
2. Taps Share → "Add to Expense Tracker."
3. App captures the screenshot/page as the photo, attempts to parse vendor +
   total from the shared content (URL/text if available, OCR otherwise),
   pre-fills source channel = Online.
4. Same confirm-and-save form as §5.1.

### 5.3 Cash expense, no receipt

1. Manual entry (`+` → "No receipt").
2. User enters amount, currency, vendor (free text or pick existing), category,
   payment method = Cash.
3. Optional: photo of the item itself in lieu of a receipt.
4. Save — flagged in search as "no receipt" for later reconciliation if
   desired.

### 5.4 Search & audit

1. User searches "Blue Bottle" or filters Category = Dining + Date = last
   month.
2. Result list with thumbnails; tap into any entry to see the original
   full-res photo, extracted items, and edit history.
3. Export the filtered set as a photo+CSV bundle for a specific need (e.g.,
   an expense reimbursement or a tax question).

### 5.5 Multi-currency trip

1. Before/at trip: user can set a "trip" context or simply let per-expense
   currency detection handle it.
2. Each purchase is logged in local currency (auto-detected or manually
   picked from a recent-currency list).
3. Trip/date-range report shows both "as spent" (grouped by currency) and
   home-currency total.

---

## 6. Information Architecture (Screens)

1. **Home / Ledger** — reverse-chronological unified feed of all expenses,
   grouped by day, with running month-to-date total. Filter chips at top
   (category, source, currency). Floating camera-capture button.
2. **Capture** — camera → OCR confirm form (shared by all entry paths).
3. **Expense Detail** — photo viewer (pinch-zoom, swipe multi-page), item
   breakdown, vendor, payment method, tags, notes, edit/audit history.
4. **Search** — query bar + filter panel + results list.
5. **Vendors** — directory list; vendor detail = mini-statement.
6. **Reports** — category/vendor/time breakdowns, monthly recap, budgets.
7. **Settings**
   - Currencies (home currency, rate refresh, manual rate overrides)
   - Payment methods (add/edit cards & cash)
   - Categories (add/edit/reorder hierarchy)
   - Security (Face ID lock, auto-lock timeout)
   - Backup & Export (iCloud status, manual export bundle, restore)
   - Data & Privacy (what's stored, where, delete-all)

---

## 7. Non-Functional Requirements

### 7.1 Security & Privacy

- **App lock**: Face ID/Touch ID (or passcode fallback) required to open the
  app; configurable auto-lock timeout.
- **Encryption at rest**: local database and photo store encrypted using iOS
  Data Protection (`NSFileProtectionComplete`); CloudKit private database is
  end-to-end encrypted by Apple for eligible fields.
- No third-party analytics/ad SDKs. No third-party servers receive photos or
  financial data — the only outbound network calls are to the exchange-rate
  API (amounts only, not identifying data) and Apple's CloudKit.
- Since this is a single-user personal app, App Store privacy nutrition
  label should reflect: data collected (financial info, photos) is used only
  for app functionality, linked to the user's Apple ID for iCloud sync, and
  **not shared with third parties, not used for tracking.**
- Full local delete ("Delete All Data") available in Settings, with a
  confirmation step, for a factory-reset before selling/handing off a device.

### 7.2 Performance

- Capture-to-confirmation-form should render in well under 1 second after
  photo is taken (on-device OCR, no network round-trip required to draft the
  form).
- App must be fully functional with no network connection except for
  exchange-rate refresh and iCloud sync, both of which degrade gracefully.

### 7.3 Reliability

- Photos must never be lost: write-ahead to local storage happens before any
  OCR/processing step, so a crash mid-processing never loses the captured
  image.
- Soft-delete with 30-day recovery window for accidental deletions.

### 7.4 Accessibility

- Dynamic Type support, VoiceOver labels on capture/confirm flow, sufficient
  contrast in category color-coding (not color-as-only-signal).

---

## 8. Technical Architecture (recommended)

- **Platform**: Native iOS, Swift + SwiftUI. Single-user personal app — no
  need for a cross-platform framework given App Store-only, one-user scope.
- **Local storage**: SwiftData (or Core Data if more mature tooling is
  preferred at build time) for structured data; photos stored as files in
  the app's protected container, referenced by path/UUID from the database.
- **Sync/backup**: CloudKit (private database) mirrors the local store across
  the user's own devices — no custom backend/server needed.
- **OCR**: Apple Vision (`VNRecognizeTextRequest`) + `VisionKit`
  `VNDocumentCameraViewController` for scan-quality capture and text
  recognition, fully on-device (no data leaves the phone for OCR).
- **Receipt parsing**: a lightweight on-device parser/heuristics layer on top
  of raw OCR text to segment vendor / date / line items / totals; can start
  rule-based (regex + layout heuristics) and later incorporate a small
  on-device Core ML text classifier trained on the user's own corrected
  corrections for vendor/category suggestion.
- **Currency rates**: a simple REST exchange-rate API (e.g., a service
  offering free/low-cost daily ISO 4217 rates), fetched and cached once daily;
  amounts only, no personal data sent.
- **Share Extension**: iOS Share Extension target for capturing screenshots/
  pages from other apps into the capture flow.
- **App Intents / Siri**: expose a "Log an expense" App Intent/Shortcut for
  voice/automation quick-add.
- **Widgets**: optional WidgetKit home-screen widget showing month-to-date
  spend and a camera quick-launch button.

---

## 9. App Store Considerations

- Distributed as a normal App Store app (not Enterprise/ad-hoc), even though
  only one person uses it — standard Apple Developer Program account.
- Required: Privacy Policy URL (can be a simple static page describing the
  local-first/no-third-party-sharing model from §7.1), App Privacy "nutrition
  label" disclosures, and standard App Review compliance (camera usage
  string, photo library usage string, location usage string if GPS-tagging
  photos is enabled).
- No account/login system required (no backend to authenticate against);
  iCloud handles device identity for sync.
- Consider listing as unlisted/private distribution vs. public search
  visibility if the user wants App Store distribution mechanics (TestFlight
  builds, proper signing) without public discoverability — Apple supports
  "Unlisted" apps distributed via direct link, only visible to the developer
  unless shared.

---

## 10. Phased Roadmap

**MVP (v0.1)**
- Manual + camera capture, one photo per expense, manual field entry (no
  OCR yet), single home currency, flat category list, basic reverse-chron
  list + detail view, local storage only (no CloudKit yet).

**v1.0**
- On-device OCR auto-extraction with confirm form, multi-item receipts &
  per-item categorization, vendor directory with alias-learning,
  multi-currency with rate snapshotting, full search + filters, CloudKit
  sync, Face ID lock.

**v1.1**
- Share Extension for online purchases, payment-method directory, source
  channel filters, recurring/subscription detection, reports & monthly
  recap, CSV/photo-bundle export.

**v1.2+**
- Siri/App Intents quick-add, home-screen widget, budgets/soft-alerts,
  on-device learned categorization, saved smart searches, optional bank
  statement CSV cross-check import.

---

## 11. Open Questions

1. Home currency — fixed at USD, or user-selectable in Settings with
   historical entries preserved at their original rate? (Spec above assumes
   the latter.)
2. Should GPS-tagging of photos be on by default, opt-in, or omitted
   entirely given it's an added privacy surface for a financial app?
3. Retention: keep soft-deleted items for exactly 30 days, or make this
   configurable?
4. Is an iPad-optimized layout needed at MVP, or iPhone-only with iPad
   "works as-is" scaling for v1?
