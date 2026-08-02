import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/providers/dashboard_providers.dart';
import '../models/merchant_profile_draft.dart';
import '../models/printer_config.dart';
import '../models/settings_data.dart';
import '../providers/settings_providers.dart';

/// Settings state for exactly one Firebase uid (see
/// [settingsControllerProvider] — a `.family` provider, the uid is this
/// notifier's `arg`) — never a global singleton, same cross-user isolation
/// pattern every controller in this app follows. `build()` loads the
/// persisted blob; every setter below is read-modify-write through
/// [SettingsRepository.updateSettings] and updates local state
/// optimistically so a toggle flips immediately rather than waiting on a
/// round trip that, for local storage, is already near-instant anyway.
class SettingsController
    extends AutoDisposeFamilyAsyncNotifier<SettingsData, String> {
  @override
  Future<SettingsData> build(String uid) {
    return ref.read(settingsRepositoryProvider(uid)).loadSettings();
  }

  Future<void> _update(
      SettingsData Function(SettingsData current) apply) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = apply(current);
    state = AsyncValue.data(next);
    await ref.read(settingsRepositoryProvider(arg)).updateSettings(next);
  }

  Future<void> updateMerchantProfile(MerchantProfileDraft profile) =>
      _update((s) => s.copyWith(merchantProfile: profile));

  Future<void> updateBusinessAddress(String? value) =>
      _update((s) => s.copyWith(businessAddress: value));

  Future<void> updateTaxNumber(String? value) =>
      _update((s) => s.copyWith(taxNumber: value));

  Future<void> updateBusinessHours(String? value) =>
      _update((s) => s.copyWith(businessHours: value));

  Future<void> updateCurrencyCode(String value) =>
      _update((s) => s.copyWith(currencyCode: value));

  Future<void> updateTimeZone(String? value) =>
      _update((s) => s.copyWith(timeZone: value));

  Future<void> updateDefaultPaymentMethod(DefaultPaymentMethod value) =>
      _update((s) => s.copyWith(defaultPaymentMethod: value));

  Future<void> toggleAutoPrintReceipt(bool value) =>
      _update((s) => s.copyWith(autoPrintReceipt: value));

  Future<void> togglePrintCustomerCopy(bool value) =>
      _update((s) => s.copyWith(printCustomerCopy: value));

  Future<void> togglePrintMerchantCopy(bool value) =>
      _update((s) => s.copyWith(printMerchantCopy: value));

  Future<void> toggleOpenCashDrawer(bool value) =>
      _update((s) => s.copyWith(openCashDrawer: value));

  Future<void> toggleRoundCashPayments(bool value) =>
      _update((s) => s.copyWith(roundCashPayments: value));

  Future<void> toggleTaxIncludedPricing(bool value) =>
      _update((s) => s.copyWith(taxIncludedPricing: value));

  Future<void> toggleBarcodeBeepOnScan(bool value) =>
      _update((s) => s.copyWith(barcodeBeepOnScan: value));

  Future<void> updatePrinterPaperSize(PrinterPaperSize value) =>
      _update((s) => s.copyWith(printerPaperSize: value));

  Future<void> updateLowStockThreshold(int value) =>
      _update((s) => s.copyWith(lowStockThreshold: value));

  Future<void> toggleAutoSku(bool value) =>
      _update((s) => s.copyWith(autoSku: value));

  Future<void> updateBarcodeFormat(BarcodeFormat value) =>
      _update((s) => s.copyWith(barcodeFormat: value));

  Future<void> updateDefaultTaxPercent(double value) =>
      _update((s) => s.copyWith(defaultTaxPercent: value));

  Future<void> updateDefaultDiscountPercent(double value) =>
      _update((s) => s.copyWith(defaultDiscountPercent: value));

  Future<void> updateImageUploadQuality(ImageUploadQuality value) =>
      _update((s) => s.copyWith(imageUploadQuality: value));

  Future<void> toggleLoyaltyEnabled(bool value) =>
      _update((s) => s.copyWith(loyaltyEnabled: value));

  Future<void> toggleCollectPhoneNumber(bool value) =>
      _update((s) => s.copyWith(collectPhoneNumber: value));

  Future<void> toggleCollectEmail(bool value) =>
      _update((s) => s.copyWith(collectEmail: value));

  Future<void> toggleBirthdayRewards(bool value) =>
      _update((s) => s.copyWith(birthdayRewards: value));

  Future<void> toggleMarketingConsent(bool value) =>
      _update((s) => s.copyWith(marketingConsent: value));

  Future<void> toggleLowStockAlerts(bool value) =>
      _update((s) => s.copyWith(lowStockAlerts: value));

  Future<void> toggleDailySalesReport(bool value) =>
      _update((s) => s.copyWith(dailySalesReport: value));

  Future<void> toggleWeeklyReport(bool value) =>
      _update((s) => s.copyWith(weeklyReport: value));

  Future<void> togglePaymentFailureAlerts(bool value) =>
      _update((s) => s.copyWith(paymentFailureAlerts: value));

  Future<void> toggleSystemNotifications(bool value) =>
      _update((s) => s.copyWith(systemNotifications: value));

  Future<void> togglePinLockEnabled(bool value) =>
      _update((s) => s.copyWith(pinLockEnabled: value));

  Future<void> updatePinCode(String? value) =>
      _update((s) => s.copyWith(pinCode: value));

  Future<void> toggleBiometricLoginEnabled(bool value) =>
      _update((s) => s.copyWith(biometricLoginEnabled: value));

  Future<void> toggleAutoLogoutEnabled(bool value) =>
      _update((s) => s.copyWith(autoLogoutEnabled: value));

  Future<void> updateSessionTimeoutMinutes(int value) =>
      _update((s) => s.copyWith(sessionTimeoutMinutes: value));

  Future<void> updateAccentColor(AccentColorOption value) =>
      _update((s) => s.copyWith(accentColor: value));

  Future<void> updateFontSize(FontSizeOption value) =>
      _update((s) => s.copyWith(fontSize: value));

  Future<void> toggleAnimationsEnabled(bool value) =>
      _update((s) => s.copyWith(animationsEnabled: value));

  /// "Manual Sync" in Backup & Sync — re-fetches the Dashboard's own
  /// merchant/store snapshot (read-only reuse of its already-public
  /// `refresh()`, never a Dashboard code change) and, only if that
  /// succeeds, stamps [SettingsData.lastSyncedAt] with now.
  Future<bool> manualSync() async {
    try {
      await ref.read(dashboardControllerProvider(arg).notifier).refresh();
      await _update((s) => s.copyWith(lastSyncedAt: DateTime.now()));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// "Import Settings" in Backup & Sync — replaces every preference this
  /// module owns with [data] in one write, the same `_update()` path (and
  /// therefore the same [SettingsRepository.updateSettings] call) every
  /// other setter already goes through. The caller is responsible for
  /// having parsed/validated the incoming JSON via [SettingsData.fromJson]
  /// before calling this.
  Future<void> importSettings(SettingsData data) => _update((_) => data);

  Future<void> resetToDefaults() async {
    final defaults =
        await ref.read(settingsRepositoryProvider(arg)).resetToDefaults();
    state = AsyncValue.data(defaults);
  }

  Future<void> clearCache() async {
    await ref.read(settingsRepositoryProvider(arg)).clearCache();
    final defaults =
        await ref.read(settingsRepositoryProvider(arg)).loadSettings();
    state = AsyncValue.data(defaults);
  }
}
