# features/billing/

The Billing/POS engine — search-or-scan product entry, the shopping cart, and the totals
breakdown (Phase 3, see docs/22_DEVELOPMENT_ROADMAP.md). Payment/checkout, receipts, printers,
Surfboard payment processing, customers, discount coupons, and tax configuration are all
explicitly out of scope this phase — this feature ends at "products can be added to a bill", the
Checkout button stays disabled.

Follows the same flat structure `features/dashboard/`/`features/inventory/` established (not the
older `data/domain/presentation` shape used elsewhere in `features/`):

```
billing/
├── models/         # CartItemModel (per-line subtotal/tax/discount/total), BillingState
│                   # (cart + search/scan sub-state), BillingFailure
├── repositories/   # BillingRepository (interface) + impl — a thin wrapper around
│                   # InventoryRepository.listProducts; Billing never re-implements Inventory's
│                   # search/filter logic or talks to the backend directly
├── controllers/    # BillingController (plain Notifier<BillingState> — the cart is always
│                   # synchronously available, only search/barcode lookups are async)
├── providers/      # Riverpod DI wiring — `.autoDispose.family<..., String>` keyed by Firebase
│                   # uid (see docs/22_DEVELOPMENT_ROADMAP.md, cross-user isolation fix) —
│                   # never a global singleton, so one merchant's in-progress sale can never be
│                   # observed under another account's session
├── widgets/        # CartItemTile, BillingSummaryCard, SearchSuggestionsList,
│                   # ProductNotFoundBanner
└── pages/          # BillingPage (tab root), BarcodeScannerPage (mobile_scanner, EAN-13/EAN-8/
                    # UPC-A/UPC-E/Code128/Code39)
```

Barcode scanning uses `mobile_scanner` — the camera/controller lifecycle and scan-deduplication
timing live in `BarcodeScannerPage` (a hardware/widget-lifecycle concern), but every decoded code
is handed straight to `BillingController.addProductByBarcode`, which is the only place that
decides found/not-found/already-in-cart.
