import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/receipt_controller.dart';
import '../models/receipt_action_state.dart';
import '../repositories/receipt_repository.dart';
import '../repositories/receipt_repository_impl.dart';

/// DI wiring for the Receipt feature — the only place these concrete
/// classes are constructed (see docs/07_CODING_RULES.md § 3).
final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepositoryImpl();
});

/// Keyed by Firebase uid — same cross-user isolation every controller in
/// this app follows (see `paymentControllerProvider`).
final receiptControllerProvider = NotifierProvider.autoDispose
    .family<ReceiptController, ReceiptActionState, String>(
  ReceiptController.new,
);
