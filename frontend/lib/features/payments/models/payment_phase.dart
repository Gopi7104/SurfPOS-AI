/// The Checkout status screen's phase — drives which animated indicator,
/// progress step, and action buttons (Retry/Cancel) are shown.
///
/// Surfboard's hosted Payment Page flow (see `PaymentRepository`'s header
/// comment) has no physical terminal hardware — there is no "Card Inserted"
/// state to observe, only the order/payment status enum Surfboard itself
/// exposes. [waitingForCustomer] is this flow's equivalent of "waiting for
/// the terminal": the customer is completing card entry on Surfboard's own
/// hosted page.
///
/// Names match Phase 5's production payment state machine spec verbatim
/// (Creating Payment, Waiting For Customer, Payment Processing, Payment
/// Successful, Payment Failed, Payment Cancelled, Payment Expired). [error]
/// is preserved alongside those 7 — a network/backend failure creating,
/// retrying, or polling the payment is a distinct case from a Surfboard
/// decline ([paymentFailed]) and dropping it would regress the existing,
/// working error-handling path (see `PaymentController`).
enum PaymentPhase {
  creatingPayment,
  waitingForCustomer,
  paymentProcessing,
  paymentSuccessful,
  paymentFailed,
  paymentCancelled,
  paymentExpired,
  error;

  /// Terminal phases end polling — once reached, a phase never changes on
  /// its own again (matches `web-guides/payment-lifecycle.md`'s "once a
  /// payment reaches a terminal state, it is final").
  bool get isTerminal => switch (this) {
        paymentSuccessful ||
        paymentFailed ||
        paymentCancelled ||
        paymentExpired ||
        error =>
          true,
        creatingPayment || waitingForCustomer || paymentProcessing => false,
      };

  bool get canRetry => switch (this) {
        paymentFailed || paymentCancelled || paymentExpired || error => true,
        _ => false,
      };
}
