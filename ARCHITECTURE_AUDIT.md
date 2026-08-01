# FoodBillX Architecture Audit

## Target architecture

Flutter widgets consume Riverpod state derived only from Isar. Repository writes
commit the entity and compact outbox intent in one Isar transaction. The sync
engine uploads dependency-ordered batches, then incrementally merges cloud
changes into Isar. Pending local records are never overwritten by a pull.

## Findings and implemented corrections

| Area | Cause and impact | Architectural correction |
|---|---|---|
| Home dashboard | It called the REST report directly, returned zero metrics offline, and displayed a hard-coded ONLINE badge. This violated the local source-of-truth rule. | Home now consumes the Isar-backed dashboard provider and the live connectivity provider. Refresh recomputes local metrics. |
| Home navigation | Settings attempted to open nonexistent tab index 7 while the shell had indices 0–6, which could crash `IndexedStack`. | Settings uses its existing route callback; shell index input is bounds checked. |
| Startup | `IndexedStack` constructed every feature and started all provider/database loads at login. | Pages are initialized lazily on first visit and retained afterward. |
| Menu search | Every keystroke triggered a full Isar read and in-memory filter. | Isar is watched once; category/search/vegetarian filters operate on the cached local snapshot. |
| Orders | Reads loaded the full collection before truncating to 50, and changes could leave the page stale. | The default query applies Isar offset/limit, listens with `watchLazy`, counts independently, and loads additional pages near the scroll boundary. |
| Customers, expenses, settings | Providers used one-time snapshots and manual reloads, so background pulls were not reflected reliably. | Providers own and dispose reactive Isar subscriptions. Local commits and cloud merges update visible state automatically. |
| Dashboard state | Billing/expense writes did not refresh metrics. Weekly values were daily values, and chart data was hard-coded. | Order/expense watches debounce local recomputation. Daily, seven-day, monthly, top-item, and recent daily trend values are derived from Isar. |
| Dashboard queries | Today and month orders were queried separately and repeatedly aggregated. | One bounded period query supplies daily, weekly, monthly, and trend metrics. |
| Billing arithmetic | `CartItem.subtotal` was already discounted, then item discounts were subtracted again. GST also ignored order-level discount allocation. | Gross subtotal, item/order discount, taxable subtotal, per-item GST, service charge, and rounded grand total now have separate definitions shared conceptually with the backend. |
| Checkout durability | PDF generation was inside the checkout failure boundary. A PDF error reported checkout failure after the order had been saved, encouraging duplicate bills. | The order commits and the cart clears before invoice rendering. PDF failure returns a warning while preserving successful checkout. |
| Invoice settings | Service charge and invoice footer were stored but absent from settings/model/invoice flows. | Both settings are editable, validated, synced, persisted, and rendered; service charge is stored on orders. |
| Invoice identity | Count-only invoice numbers collide when multiple offline devices bill on the same day. | A persistent per-install device code is included with the daily sequence. Backend-generated numbers use a collision-resistant timestamp. |
| Outbox growth | Every edit appended another operation. Create→update could send an update without a server ID; create→delete could still create cloud data. | `SyncOutbox` compacts intents transactionally: updates merge, local-only updates remain creates, and create→delete cancels cloud work. |
| Relationship sync | Offline category/customer/menu IDs were sent where MongoDB ObjectIds were required. | Sync runs dependency phases and resolves local IDs from Isar after parent creates receive server IDs. Category ID assignment also updates dependent local menu rows. |
| Batch sync | Mobile pushed one REST request per operation despite an existing batch API. | Operations upload in dependency-aware batches of 25; backend limits batches to 100. |
| Retry duplicates | A successful create followed by a lost response could create duplicates on retry. | Stable operation IDs and expiring server receipts make retries idempotent; natural unique keys provide a second guard. |
| Retry visibility | Five failed attempts became permanently ineligible while UI could still imply completion. | Queued work remains retryable. Sync status reports remaining operations as a warning and watches the outbox count reactively. |
| Incremental pull | Every sync fully reseeded collections, wasting bandwidth and risking pending local overwrites. Orders were never pulled. | `/sync/pull?since=` uses a server watermark, includes orders, and merges only changed records. Pending local intent wins; synced records accept server state without relying on skewed device clocks. |
| Deletions | Hard-deleted cloud records could never disappear from another device. | Backend writes sync tombstones for hard deletes; incremental pulls remove corresponding synced local rows. Soft-deleted categories are handled through `isActive`. |
| Connectivity | The stream emitted only after a connectivity change, leaving initial UI/sync status unknown. | It emits the initial interface state and distinct subsequent changes. Network interface availability is a trigger; failed HTTP remains the authority on actual reachability. |
| API configuration | Android used a developer-specific LAN IP, preventing production/device portability. | `API_BASE_URL` is a compile-time setting; Android emulator and same-origin web defaults remain development fallbacks. |
| Settings lifecycle | Controllers could initialize before settings arrived and never update. Dialog controllers were retained after closing. | Settings populate once when local data arrives; change-PIN dialog controllers are disposed on completion. |
| PIN validation | Change-PIN accepted any four characters and unlimited rapid failures. | PIN persistence requires four digits and the notifier applies a five-attempt/30-second in-session lockout. |
| Duplicate abstractions | Two unrelated `ApiClient` classes, fake secure storage, and an unused user model created misleading architecture. | Unused duplicate client/storage/user files were removed; one sync-facing API client remains. |
| Backend order creation | Menu items were fetched in an N+1 loop, discounts differed from mobile, and count-based order numbers could race. | Menu items/settings load in parallel, calculations match mobile, service charge is persisted, and IDs are collision resistant. |
| Sync validation | Malformed timestamps/batches were accepted and unknown result omissions could silently strand operations. | Controller validates timestamps, array shape and batch size; each operation returns an explicit success/error result. |

## Module audit summary

- **PIN / routing:** local PIN creation, confirmation, entry, change, lock, and
  redirect flows remain intact. Router paths remain `/pin` and `/home`.
- **Home shell:** all seven existing modules remain; lazy construction reduces
  login work without changing tab identity or retained page state.
- **Billing:** menu/category selection, cart quantity, customer association,
  payment choice, checkout, local order persistence, loyalty update, PDF and
  sharing remain available offline.
- **Menu:** category and item CRUD, availability, search, filters, list/grid
  layouts and dialogs remain Isar-first and reactive.
- **Customers:** CRUD, search, card uniqueness, loyalty assignment and visit
  statistics remain local-first and syncable.
- **Expenses:** expense/category CRUD, filters, totals, and category management
  remain local-first and reactive.
- **Orders:** history, search, payment filtering and incremental scrolling use
  local data only.
- **Insights:** revenue, counts, expenses, profit, top sellers and trend charts
  are derived from local orders/expenses.
- **Settings:** business, invoice, tax, service charge, footer, PIN and sync
  status are local-first.
- **Backend:** REST modules remain for web/future clients. Batch push,
  incremental pull, receipts and tombstones support mobile synchronization.

## Deliberate compatibility boundary

The current product has a local owner PIN but no backend User, Business, Branch,
or membership model and no login routes. Inventing tenant identity during this
incremental pass would either expose data under a fake default tenant or lock
existing installations out. The data/sync boundaries are now ready for tenant
keys, but cloud authentication and tenant migration must be introduced as a
versioned deployment with an account-provisioning decision and migration plan.
Until then, the backend must be deployed only in a trusted/private environment;
it is not safe as a public multi-tenant API.

## Runtime configuration

For a physical device or production build, pass the backend explicitly:

```powershell
flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

Android emulator development defaults to `http://10.0.2.2:5000/api/v1`.
