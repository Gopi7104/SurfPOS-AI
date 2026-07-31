import '../models/dashboard_state.dart';

abstract class DashboardRepository {
  /// Composes the caller's merchant application (Firebase-tracked) with a
  /// live Merchant/Store profile read from Surfboard once those ids exist.
  /// Never hardcoded — every field comes from a real backend response.
  Future<DashboardState> loadDashboard();
}
