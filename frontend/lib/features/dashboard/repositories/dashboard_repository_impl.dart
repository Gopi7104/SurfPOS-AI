import '../../../core/network/api_client.dart';
import '../../merchant/data/datasources/merchant_onboarding_api_service.dart';
import '../models/dashboard_state.dart';
import '../models/merchant_profile_model.dart';
import '../models/store_profile_model.dart';
import 'dashboard_repository.dart';

/// Composes three existing endpoints into one Dashboard snapshot — no new
/// backend surface needed, this is exactly the "orchestrate multiple API
/// calls into one screen's data" job a Repository exists for:
///  1. `GET /merchant/applications` (via [MerchantOnboardingApiService]) —
///     the Firebase-tracked application: applicationId/status/merchantId/
///     storeId.
///  2. `GET /merchant` — live Merchant profile from Surfboard, once a
///     merchantId exists.
///  3. `GET /stores/:storeId` — live Store profile from Surfboard, once a
///     storeId exists.
class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required ApiClient apiClient,
    required MerchantOnboardingApiService merchantApplicationApi,
  })  : _apiClient = apiClient,
        _merchantApplicationApi = merchantApplicationApi;

  final ApiClient _apiClient;
  final MerchantOnboardingApiService _merchantApplicationApi;

  @override
  Future<DashboardState> loadDashboard() async {
    final applications = await _merchantApplicationApi.list();

    if (applications.isEmpty) {
      return DashboardState(hasMerchant: false, lastSyncedAt: DateTime.now());
    }

    final application = applications.first;

    final merchantId = application.merchantId;
    final storeId = application.storeId;

    final merchant = merchantId == null ? null : await _fetchMerchantProfile();
    final store = storeId == null ? null : await _fetchStoreProfile(storeId);

    return DashboardState(
      hasMerchant: true,
      lastSyncedAt: DateTime.now(),
      applicationId: application.applicationId,
      applicationStatus: application.applicationStatus,
      merchant: merchant,
      store: store,
    );
  }

  Future<MerchantProfileModel?> _fetchMerchantProfile() async {
    final data = await _apiClient.get('/merchant', requiresAuth: true);
    final merchant = data['merchant'];
    return merchant is Map<String, dynamic> ? MerchantProfileModel.fromJson(merchant) : null;
  }

  Future<StoreProfileModel?> _fetchStoreProfile(String storeId) async {
    final data = await _apiClient.get('/stores/$storeId', requiresAuth: true);
    final store = data['store'];
    return store is Map<String, dynamic> ? StoreProfileModel.fromJson(store) : null;
  }
}
