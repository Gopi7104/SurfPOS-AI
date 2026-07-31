import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/providers/auth_providers.dart';
import '../controllers/payment_controller.dart';
import '../models/payment_state.dart';
import '../repositories/payment_repository.dart';
import '../repositories/payment_repository_impl.dart';

/// DI wiring for the Payments feature — the only place these concrete
/// classes are constructed (see docs/07_CODING_RULES.md § 3).
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});

/// Keyed by Firebase uid — never a global singleton, so one merchant's
/// in-progress checkout can never be observed under another account's
/// session, same pattern as `billingControllerProvider`.
final paymentControllerProvider = NotifierProvider.autoDispose
    .family<PaymentController, PaymentState, String>(
  PaymentController.new,
);
