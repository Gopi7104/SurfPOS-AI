# features/payments/

Checkout's Surfboard payment integration (Phase 4, see docs/22_DEVELOPMENT_ROADMAP.md). Creates a
real Surfboard order/payment, monitors its status, and displays success/failure. Receipts,
printing, customers, and loyalty are all explicitly out of scope this phase.

Follows the same flat structure `features/dashboard/`/`features/inventory/`/`features/billing/`
established (not the older `data/domain/presentation` shape used elsewhere in `features/`):

```
payments/
├── models/         # PaymentPhase (UI status enum), PaymentState, CheckoutItem (the only shape
│                   # sent to the backend — productId/quantity, never a price), CheckoutResultModel,
│                   # OrderStatusModel, PaymentFailure
├── repositories/   # PaymentRepository (interface) + impl — calls this app's own `/payments`
│                   # backend API; never talks to Surfboard directly (see
│                   # docs/15_SURFBOARD_INTEGRATION.md § 1)
├── controllers/    # PaymentController — owns the whole Create → Poll → Terminal-state lifecycle,
│                   # including the polling Timer itself
├── providers/      # Riverpod DI wiring — `.autoDispose.family<..., String>` keyed by Firebase
│                   # uid, same cross-user isolation pattern every controller in this app follows
├── widgets/        # PaymentSummaryDialog, PaymentProgressSteps, PaymentStatusIndicator
└── pages/          # PaymentStatusPage (starts checkout on mount, reflects PaymentController's
                    # state until a terminal phase is reached)
```

This app has never registered a physical Surfboard card terminal — Checkout instead registers a
software-only **online terminal** (`onlineTerminalMode: "PaymentPage"`) per store, once, entirely
server-side. The customer completes card entry on Surfboard's own hosted Payment Page, opened via
`url_launcher` in the device's own browser (deliberately not an embedded WebView, so the customer
sees a real, trusted address bar) — this app never collects a card number itself. Meanwhile
`PaymentController` polls `GET /payments/checkout/:orderId/status` every 2 seconds until the
payment reaches a terminal state (`approved`/`declined`/`cancelled`) or times out.
