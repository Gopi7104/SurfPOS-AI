import 'package:surfpos_ai/features/merchant/data/models/merchant_application.dart';
import 'package:surfpos_ai/features/dashboard/models/dashboard_state.dart';
import 'package:surfpos_ai/features/dashboard/models/merchant_profile_model.dart';
import 'package:surfpos_ai/features/dashboard/models/store_profile_model.dart';
import 'package:surfpos_ai/features/dashboard/repositories/dashboard_repository.dart';

/// Configurable [DashboardRepository] test double — mirrors
/// `test/features/merchant/fakes/fake_merchant_onboarding_repository.dart`'s
/// shape: defaults to a no-op, overridable per test, never touches network.
class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({Future<DashboardState> Function()? loadDashboard})
      : _loadDashboard = loadDashboard ?? (() async => testDashboardState(hasMerchant: false));

  final Future<DashboardState> Function() _loadDashboard;

  @override
  Future<DashboardState> loadDashboard() => _loadDashboard();
}

DashboardState testDashboardState({
  bool hasMerchant = true,
  String? applicationId = 'app-1',
  ApplicationStatus? applicationStatus = ApplicationStatus.merchantCreated,
  MerchantProfileModel? merchant = const MerchantProfileModel(
    id: 'm-1',
    name: 'Blue Wave Surf Shop',
    companyId: '5560360793',
    email: 'merchant@example.com',
    phoneNumber: '+46701234567',
    mccCode: '5941',
    countryCode: 'SE',
  ),
  StoreProfileModel? store = const StoreProfileModel(
    id: 's-1',
    merchantId: 'm-1',
    name: 'Main Street Store',
    status: 'ACTIVE',
  ),
}) {
  return DashboardState(
    hasMerchant: hasMerchant,
    lastSyncedAt: DateTime.utc(2026, 1, 1, 12),
    applicationId: hasMerchant ? applicationId : null,
    applicationStatus: hasMerchant ? applicationStatus : null,
    merchant: hasMerchant ? merchant : null,
    store: hasMerchant ? store : null,
  );
}
