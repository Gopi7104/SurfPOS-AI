import '../../merchant/data/models/merchant_application.dart';
import 'business_summary.dart';
import 'merchant_profile_model.dart';
import 'store_profile_model.dart';

/// The value [DashboardController] produces — wrapped in Riverpod's
/// `AsyncValue` for loading/error handling (see [DashboardController]).
/// [hasMerchant] is what distinguishes the "Empty" case (no merchant
/// application submitted yet) from a fully-loaded dashboard; [merchant]/
/// [store] are only populated once Surfboard has assigned a merchantId/
/// storeId (i.e. the application has progressed far enough for those to
/// exist) — both `null` simply means "not yet", not an error.
class DashboardState {
  const DashboardState({
    required this.hasMerchant,
    required this.lastSyncedAt,
    this.applicationId,
    this.applicationStatus,
    this.merchant,
    this.store,
    this.businessSummary = const BusinessSummary(),
  });

  final bool hasMerchant;
  final DateTime lastSyncedAt;
  final String? applicationId;
  final ApplicationStatus? applicationStatus;
  final MerchantProfileModel? merchant;
  final StoreProfileModel? store;
  final BusinessSummary businessSummary;
}
