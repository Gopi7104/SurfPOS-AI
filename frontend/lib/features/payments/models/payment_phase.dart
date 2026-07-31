/// The Checkout status screen's phase — drives which animated indicator,
/// progress step, and action buttons (Retry/Cancel) are shown.
///
/// Surfboard's hosted Payment Page flow (see `PaymentRepository`'s header
/// comment) has no physical terminal hardware — there is no "Card Inserted"
/// state to observe, only the order/payment status enum Surfboard itself
/// exposes. [waitingForPayment] is this flow's equivalent of "waiting for
/// the terminal": the customer is completing card entry on Surfboard's own
/// hosted page.
enum PaymentPhase {
  creatingPayment,
  waitingForPayment,
  processing,
  approved,
  declined,
  cancelled,
  timedOut,
  error;

  /// Terminal phases end polling — once reached, a phase never changes on
  /// its own again (matches `web-guides/payment-lifecycle.md`'s "once a
  /// payment reaches a terminal state, it is final").
  bool get isTerminal => switch (this) {
        approved || declined || cancelled || timedOut || error => true,
        creatingPayment || waitingForPayment || processing => false,
      };

  bool get canRetry => switch (this) {
        declined || cancelled || timedOut || error => true,
        _ => false,
      };
}
