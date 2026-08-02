import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_spacing.dart';
import '../../../app/themes/app_typography.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/widgets/app_bars/app_gradient_header.dart';
import '../../../core/widgets/empty_states/error_state.dart';
import '../../../core/widgets/loading/app_loading_indicator.dart';
import '../../authentication/presentation/screens/login_page.dart';
import '../../authentication/providers/auth_providers.dart';
import '../../customers/providers/customer_providers.dart';
import '../../dashboard/models/dashboard_state.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../demo_data/providers/demo_data_providers.dart';
import '../models/diagnostics_snapshot.dart';
import '../models/printer_config.dart';
import '../models/settings_data.dart';
import '../providers/settings_providers.dart';
import '../widgets/bottom_sheet_editor.dart';
import '../widgets/danger_zone_card.dart';
import '../widgets/developer_card.dart';
import '../widgets/developer_status_card.dart';
import '../widgets/printer_status_card.dart';
import '../widgets/settings_fade_in.dart';
import '../widgets/settings_info_page.dart';
import '../widgets/settings_info_tile.dart';
import '../widgets/settings_navigation_tile.dart';
import '../widgets/settings_search_delegate.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_switch_tile.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_value_tile.dart';
import 'about_page.dart';
import 'developer_tools_page.dart';
import 'merchant_profile_page.dart';
import 'payment_settings_page.dart';
import 'printer_settings_page.dart';
import 'security_privacy_page.dart';

/// `GlobalKey`s for every top-level Settings section — lets Settings
/// Search scroll straight to a section it matched (see
/// `SettingsSearchDelegate`) via `Scrollable.ensureVisible`. Module-level
/// (not per-build-instance state) since Settings Home is mounted once for
/// the lifetime of the tab (kept alive by `MainShellPage`'s
/// `IndexedStack`) and a `GlobalKey` only needs to be a stable Dart object,
/// not rebuilt state.
final Map<String, GlobalKey> _settingsSectionKeys = {
  for (final title in const [
    'Business',
    'POS Settings',
    'Printer',
    'Payment',
    'Inventory',
    'Customers',
    'Notifications',
    'Security',
    'Backup & Sync',
    'Application',
    'Support',
    'Danger Zone',
  ])
    title: GlobalKey(debugLabel: title),
};

/// The full Settings Search index — every entry maps to something real:
/// either a section on this page (scrolled to via [_settingsSectionKeys])
/// or a page that already exists. Deliberately not exhaustive down to
/// every single tile — the most commonly searched settings plus every
/// section name, so a search always lands somewhere useful.
final List<SettingsSearchEntry> _settingsSearchEntries = [
  const SettingsSearchEntry(label: 'Business', sectionTitle: 'Business'),
  const SettingsSearchEntry(
      label: 'Business Address', sectionTitle: 'Business'),
  const SettingsSearchEntry(label: 'Tax Information', sectionTitle: 'Business'),
  const SettingsSearchEntry(label: 'Currency', sectionTitle: 'Business'),
  const SettingsSearchEntry(label: 'Language', sectionTitle: 'Business'),
  const SettingsSearchEntry(label: 'Time Zone', sectionTitle: 'Business'),
  SettingsSearchEntry(
      label: 'Merchant Profile',
      pageBuilder: (_) => const MerchantProfilePage()),
  SettingsSearchEntry(
      label: 'Store Information',
      pageBuilder: (_) => const MerchantProfilePage()),
  const SettingsSearchEntry(
      label: 'POS Settings', sectionTitle: 'POS Settings'),
  const SettingsSearchEntry(
      label: 'Default Payment Method', sectionTitle: 'POS Settings'),
  const SettingsSearchEntry(
      label: 'Receipt Settings', sectionTitle: 'POS Settings'),
  const SettingsSearchEntry(label: 'Printer', sectionTitle: 'Printer'),
  SettingsSearchEntry(
      label: 'Bluetooth Printer',
      pageBuilder: (_) => const PrinterSettingsPage()),
  SettingsSearchEntry(
      label: 'Test Print', pageBuilder: (_) => const PrinterSettingsPage()),
  const SettingsSearchEntry(label: 'Paper Size', sectionTitle: 'Printer'),
  const SettingsSearchEntry(label: 'Payment', sectionTitle: 'Payment'),
  SettingsSearchEntry(
      label: 'Payment Diagnostics',
      pageBuilder: (_) => const PaymentSettingsPage()),
  const SettingsSearchEntry(label: 'Inventory', sectionTitle: 'Inventory'),
  const SettingsSearchEntry(
      label: 'Low Stock Threshold', sectionTitle: 'Inventory'),
  const SettingsSearchEntry(label: 'Barcode Format', sectionTitle: 'Inventory'),
  const SettingsSearchEntry(label: 'Customers', sectionTitle: 'Customers'),
  const SettingsSearchEntry(
      label: 'Loyalty Enabled', sectionTitle: 'Customers'),
  const SettingsSearchEntry(
      label: 'Notifications', sectionTitle: 'Notifications'),
  const SettingsSearchEntry(
      label: 'Low Stock Alerts', sectionTitle: 'Notifications'),
  const SettingsSearchEntry(
      label: 'Daily Sales Report', sectionTitle: 'Notifications'),
  const SettingsSearchEntry(label: 'Security', sectionTitle: 'Security'),
  const SettingsSearchEntry(label: 'Change Password', sectionTitle: 'Security'),
  const SettingsSearchEntry(label: 'Biometric Login', sectionTitle: 'Security'),
  const SettingsSearchEntry(label: 'PIN Lock', sectionTitle: 'Security'),
  const SettingsSearchEntry(label: 'Session Timeout', sectionTitle: 'Security'),
  const SettingsSearchEntry(
      label: 'Privacy Settings', sectionTitle: 'Security'),
  const SettingsSearchEntry(
      label: 'Backup & Sync', sectionTitle: 'Backup & Sync'),
  const SettingsSearchEntry(
      label: 'Manual Sync', sectionTitle: 'Backup & Sync'),
  const SettingsSearchEntry(
      label: 'Export Settings', sectionTitle: 'Backup & Sync'),
  const SettingsSearchEntry(
      label: 'Import Settings', sectionTitle: 'Backup & Sync'),
  const SettingsSearchEntry(label: 'Application', sectionTitle: 'Application'),
  const SettingsSearchEntry(label: 'Theme', sectionTitle: 'Application'),
  const SettingsSearchEntry(label: 'Dark Mode', sectionTitle: 'Application'),
  const SettingsSearchEntry(label: 'Accent Color', sectionTitle: 'Application'),
  const SettingsSearchEntry(label: 'Font Size', sectionTitle: 'Application'),
  const SettingsSearchEntry(label: 'Animations', sectionTitle: 'Application'),
  const SettingsSearchEntry(label: 'Support', sectionTitle: 'Support'),
  const SettingsSearchEntry(label: 'Help Center', sectionTitle: 'Support'),
  const SettingsSearchEntry(label: 'Contact Support', sectionTitle: 'Support'),
  const SettingsSearchEntry(label: 'Report Bug', sectionTitle: 'Support'),
  SettingsSearchEntry(label: 'About', pageBuilder: (_) => const AboutPage()),
  SettingsSearchEntry(
      label: 'Developer Tools', pageBuilder: (_) => const DeveloperToolsPage()),
  const SettingsSearchEntry(label: 'Logout', sectionTitle: 'Danger Zone'),
];

/// Settings Home — replaces the Phase 1 placeholder (Phase 7). Every
/// section below either reads/writes real, locally-persisted preferences
/// via [SettingsController]/[ThemeController], or reads another feature's
/// already-public provider read-only (Dashboard's merchant/store,
/// Customers' stats, Authentication's signed-in user) — never a new write
/// path into any restricted feature.
///
/// Several preferences are genuinely persisted but not yet wired to any
/// downstream behavior, because doing so would require modifying a
/// restricted feature (Billing/Inventory/Receipt/Authentication/...) this
/// module must not touch. Each such tile's subtitle says so explicitly
/// (e.g. Notifications, Security, Application's accent color/font size)
/// rather than silently implying it already works.
class SettingsHomePage extends ConsumerWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.valueOrNull?.uid));
    if (uid == null) return const AppFullScreenLoader();

    final settingsAsync = ref.watch(settingsControllerProvider(uid));

    return switch (settingsAsync) {
      AsyncLoading() when !settingsAsync.hasValue =>
        const Center(child: AppLoadingIndicator()),
      AsyncError() when !settingsAsync.hasValue => ErrorState(
          message: 'Could not load Settings.',
          onRetry: () => ref.invalidate(settingsControllerProvider(uid)),
        ),
      _ => _SettingsHomeBody(uid: uid, settings: settingsAsync.value!),
    };
  }
}

class _SettingsHomeBody extends ConsumerWidget {
  const _SettingsHomeBody({required this.uid, required this.settings});

  final String uid;
  final SettingsData settings;

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _confirmThen(BuildContext context, String title, String message,
      VoidCallback action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('Confirm', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) action();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsControllerProvider(uid).notifier);
    final dashboard = ref.watch(dashboardControllerProvider(uid)).valueOrNull;
    final themeMode = ref.watch(themeControllerProvider).valueOrNull;
    final printerConnected =
        ref.watch(printerConnectionProvider).valueOrNull ?? false;
    final customerStats = ref.watch(customerStatsProvider(uid)).valueOrNull;
    final storageUsage =
        ref.watch(settingsStorageUsageProvider(uid)).valueOrNull;
    final diagnosticsAsync = ref.watch(diagnosticsControllerProvider(uid));
    final diagnostics = diagnosticsAsync.valueOrNull;
    final user = ref.watch(authControllerProvider).valueOrNull;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(settingsControllerProvider(uid).notifier).manualSync(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 2),
        children: [
          AppGradientHeader(
            child: Row(
              children: [
                Expanded(
                  child: Text('Settings',
                      style: AppTypography.headingLG
                          .copyWith(color: AppColors.white)),
                ),
                Material(
                  color: AppColors.white.withValues(alpha: 0.16),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _openSettingsSearch(context),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(LucideIcons.search,
                          size: 18, color: AppColors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SettingsFadeIn(
              enabled: settings.animationsEnabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (user != null) ...[
                    Text(
                        user.displayName?.isNotEmpty == true
                            ? user.displayName!
                            : 'Account',
                        style: AppTypography.headingSM),
                    Text(user.email, style: AppTypography.caption),
                    const SizedBox(height: AppSpacing.sm + 4),
                  ],

                  // ---------------------------------------------------------
                  // 1. Business
                  // ---------------------------------------------------------
                  SettingsSection(
                      key: _settingsSectionKeys['Business'],
                      title: 'Business',
                      children: [
                        SettingsNavigationTile(
                          title: 'Merchant Profile',
                          icon: LucideIcons.building2,
                          subtitle: settings.merchantProfile.businessName ??
                              dashboard?.merchant?.name,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const MerchantProfilePage())),
                        ),
                        SettingsNavigationTile(
                          title: 'Store Information',
                          icon: LucideIcons.store,
                          subtitle: dashboard?.store?.name,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const MerchantProfilePage())),
                        ),
                        SettingsNavigationTile(
                          title: 'Business Address',
                          icon: LucideIcons.mapPin,
                          valueLabel: settings.businessAddress ?? 'Not set',
                          onTap: () async {
                            final value = await _editTextDialog(context,
                                title: 'Business Address',
                                initialValue: settings.businessAddress);
                            if (value != null) {
                              controller.updateBusinessAddress(value);
                            }
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Tax Information',
                          icon: LucideIcons.receipt,
                          valueLabel: settings.taxNumber ?? 'Not set',
                          onTap: () async {
                            final value = await _editTextDialog(context,
                                title: 'Tax Number',
                                initialValue: settings.taxNumber);
                            if (value != null) {
                              controller.updateTaxNumber(value);
                            }
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Business Hours',
                          icon: LucideIcons.clock,
                          valueLabel: settings.businessHours ?? 'Not set',
                          onTap: () async {
                            final value = await _editTextDialog(context,
                                title: 'Business Hours',
                                initialValue: settings.businessHours,
                                hint: 'e.g. Mon–Fri 9am–6pm');
                            if (value != null) {
                              controller.updateBusinessHours(value);
                            }
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Currency',
                          icon: LucideIcons.dollarSign,
                          valueLabel: settings.currencyCode,
                          onTap: () async {
                            final value = await _editTextDialog(context,
                                title: 'Currency Code',
                                initialValue: settings.currencyCode);
                            if (value != null && value.isNotEmpty) {
                              controller.updateCurrencyCode(value);
                            }
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Language',
                          icon: LucideIcons.languages,
                          valueLabel: 'English',
                          onTap: () =>
                              Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const SettingsInfoPage(
                              title: 'Language',
                              icon: LucideIcons.languages,
                              summary:
                                  'SurfPOS AI is currently available in English only.',
                              requirements: [
                                'Adding another language requires real localization infrastructure (flutter_localizations + intl + translated .arb resource files) — none of that exists in this app yet.',
                                'Every screen would also need to read translated strings instead of the hardcoded English text it uses today.',
                              ],
                            ),
                          )),
                        ),
                        SettingsNavigationTile(
                          title: 'Time Zone',
                          icon: LucideIcons.globe,
                          valueLabel: settings.timeZone ?? 'Not set',
                          onTap: () async {
                            final value = await _editTextDialog(context,
                                title: 'Time Zone',
                                initialValue: settings.timeZone);
                            if (value != null) controller.updateTimeZone(value);
                          },
                        ),
                      ]),
                  const SizedBox(height: AppSpacing.sm + 4),

                  // ---------------------------------------------------------
                  // 2. POS Settings
                  // ---------------------------------------------------------
                  SettingsSection(
                      key: _settingsSectionKeys['POS Settings'],
                      title: 'POS Settings',
                      children: [
                        SettingsNavigationTile(
                          title: 'Default Payment Method',
                          icon: LucideIcons.creditCard,
                          valueLabel: settings.defaultPaymentMethod.label,
                          onTap: () async {
                            final value =
                                await _selectOptionDialog<DefaultPaymentMethod>(
                              context,
                              title: 'Default Payment Method',
                              options: DefaultPaymentMethod.values,
                              current: settings.defaultPaymentMethod,
                              labelOf: (o) => o.label,
                            );
                            if (value != null) {
                              controller.updateDefaultPaymentMethod(value);
                            }
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Receipt Settings',
                          icon: LucideIcons.receiptText,
                          subtitle: 'Auto print, customer/merchant copies',
                          onTap: () =>
                              _showReceiptSettingsSheet(context, ref, settings),
                        ),
                        SettingsSwitchTile(
                          title: 'Beep on Scan',
                          icon: LucideIcons.scanLine,
                          value: settings.barcodeBeepOnScan,
                          onChanged: controller.toggleBarcodeBeepOnScan,
                        ),
                        SettingsSwitchTile(
                          title: 'Open Cash Drawer',
                          icon: LucideIcons.archive,
                          value: settings.openCashDrawer,
                          onChanged: controller.toggleOpenCashDrawer,
                        ),
                        SettingsSwitchTile(
                          title: 'Round Cash Payments',
                          icon: LucideIcons.circleDollarSign,
                          value: settings.roundCashPayments,
                          onChanged: controller.toggleRoundCashPayments,
                        ),
                        SettingsSwitchTile(
                          title: 'Tax Included Pricing',
                          icon: LucideIcons.percent,
                          value: settings.taxIncludedPricing,
                          onChanged: controller.toggleTaxIncludedPricing,
                        ),
                      ]),
                  const SizedBox(height: AppSpacing.sm + 4),

                  // ---------------------------------------------------------
                  // 3. Printer
                  // ---------------------------------------------------------
                  SettingsSection(
                      key: _settingsSectionKeys['Printer'],
                      title: 'Printer',
                      children: [
                        PrinterStatusCard(
                          status: printerConnected
                              ? PrinterConnectionStatus.connected
                              : PrinterConnectionStatus.notConnected,
                        ),
                        SettingsNavigationTile(
                          title: 'Bluetooth Printer',
                          icon: LucideIcons.bluetooth,
                          valueLabel:
                              printerConnected ? 'Connected' : 'Not connected',
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const PrinterSettingsPage())),
                        ),
                        const SettingsTile(
                          title: 'Network Printer',
                          icon: LucideIcons.wifi,
                          subtitle: 'Not supported yet',
                          enabled: false,
                        ),
                        SettingsNavigationTile(
                          title: 'Test Print',
                          icon: LucideIcons.printer,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const PrinterSettingsPage())),
                        ),
                        SettingsNavigationTile(
                          title: 'Paper Size',
                          icon: LucideIcons.ruler,
                          valueLabel: settings.printerPaperSize.label,
                          onTap: () async {
                            final value =
                                await _selectOptionDialog<PrinterPaperSize>(
                              context,
                              title: 'Paper Size',
                              options: PrinterPaperSize.values,
                              current: settings.printerPaperSize,
                              labelOf: (o) => o.label,
                            );
                            if (value != null) {
                              controller.updatePrinterPaperSize(value);
                            }
                          },
                        ),
                        SettingsInfoTile(
                          label: 'Receipt Width',
                          value:
                              '${settings.printerPaperSize.charactersPerLine} characters',
                        ),
                        SettingsInfoTile(
                          label: 'Printer Status',
                          value: printerConnected
                              ? 'Connected'
                              : 'No printer connected',
                        ),
                      ]),
                  const SizedBox(height: AppSpacing.sm + 4),

                  // ---------------------------------------------------------
                  // 4. Payment
                  // ---------------------------------------------------------
                  SettingsSection(
                      key: _settingsSectionKeys['Payment'],
                      title: 'Payment',
                      children: [
                        SettingsInfoTile(
                            label: 'Merchant Status',
                            value: dashboard?.applicationStatus?.label ??
                                'Unknown'),
                        SettingsInfoTile(
                            label: 'Store Status',
                            value: dashboard?.store?.status),
                        const SettingsInfoTile(
                            label: 'Terminal Status', value: 'Not available'),
                        if (diagnostics != null)
                          SettingsInfoTile(
                              label: 'Connection Status',
                              value: diagnostics.backendStatus.label),
                        SettingsNavigationTile(
                          title: 'Payment Diagnostics',
                          icon: LucideIcons.activity,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const PaymentSettingsPage())),
                        ),
                      ]),
                  const SizedBox(height: AppSpacing.sm + 4),

                  // ---------------------------------------------------------
                  // 5. Inventory
                  // ---------------------------------------------------------
                  SettingsSection(
                      key: _settingsSectionKeys['Inventory'],
                      title: 'Inventory',
                      children: [
                        SettingsNavigationTile(
                          title: 'Low Stock Threshold',
                          icon: LucideIcons.triangleAlert,
                          valueLabel: '${settings.lowStockThreshold}',
                          onTap: () async {
                            final value = await _editNumberDialog(context,
                                title: 'Low Stock Threshold',
                                initialValue: settings.lowStockThreshold);
                            if (value != null) {
                              controller.updateLowStockThreshold(value);
                            }
                          },
                        ),
                        SettingsSwitchTile(
                          title: 'Auto SKU',
                          icon: LucideIcons.hash,
                          value: settings.autoSku,
                          onChanged: controller.toggleAutoSku,
                        ),
                        SettingsNavigationTile(
                          title: 'Barcode Format',
                          icon: LucideIcons.barcode,
                          valueLabel: settings.barcodeFormat.label,
                          onTap: () async {
                            final value =
                                await _selectOptionDialog<BarcodeFormat>(
                              context,
                              title: 'Barcode Format',
                              options: BarcodeFormat.values,
                              current: settings.barcodeFormat,
                              labelOf: (o) => o.label,
                            );
                            if (value != null) {
                              controller.updateBarcodeFormat(value);
                            }
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Default Tax',
                          icon: LucideIcons.percent,
                          valueLabel: '${settings.defaultTaxPercent}%',
                          onTap: () async {
                            final value = await _editPercentDialog(context,
                                title: 'Default Tax %',
                                initialValue: settings.defaultTaxPercent);
                            if (value != null) {
                              controller.updateDefaultTaxPercent(value);
                            }
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Default Discount',
                          icon: LucideIcons.tag,
                          valueLabel: '${settings.defaultDiscountPercent}%',
                          onTap: () async {
                            final value = await _editPercentDialog(context,
                                title: 'Default Discount %',
                                initialValue: settings.defaultDiscountPercent);
                            if (value != null) {
                              controller.updateDefaultDiscountPercent(value);
                            }
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Image Upload Quality',
                          icon: LucideIcons.image,
                          valueLabel: settings.imageUploadQuality.label,
                          onTap: () async {
                            final value =
                                await _selectOptionDialog<ImageUploadQuality>(
                              context,
                              title: 'Image Upload Quality',
                              options: ImageUploadQuality.values,
                              current: settings.imageUploadQuality,
                              labelOf: (o) => o.label,
                            );
                            if (value != null) {
                              controller.updateImageUploadQuality(value);
                            }
                          },
                        ),
                      ]),
                  const SizedBox(height: AppSpacing.sm + 4),

                  // ---------------------------------------------------------
                  // 6. Customers
                  // ---------------------------------------------------------
                  SettingsSection(
                      key: _settingsSectionKeys['Customers'],
                      title: 'Customers',
                      children: [
                        SettingsSwitchTile(
                          title: 'Loyalty Enabled',
                          icon: LucideIcons.star,
                          value: settings.loyaltyEnabled,
                          onChanged: controller.toggleLoyaltyEnabled,
                        ),
                        SettingsSwitchTile(
                          title: 'Collect Phone Number',
                          icon: LucideIcons.phone,
                          value: settings.collectPhoneNumber,
                          onChanged: controller.toggleCollectPhoneNumber,
                        ),
                        SettingsSwitchTile(
                          title: 'Collect Email',
                          icon: LucideIcons.mail,
                          value: settings.collectEmail,
                          onChanged: controller.toggleCollectEmail,
                        ),
                        SettingsSwitchTile(
                          title: 'Birthday Rewards',
                          icon: LucideIcons.cake,
                          value: settings.birthdayRewards,
                          onChanged: controller.toggleBirthdayRewards,
                        ),
                        SettingsSwitchTile(
                          title: 'Marketing Consent',
                          icon: LucideIcons.megaphone,
                          value: settings.marketingConsent,
                          onChanged: controller.toggleMarketingConsent,
                        ),
                      ]),
                  const SizedBox(height: AppSpacing.sm + 4),

                  // ---------------------------------------------------------
                  // 7. Notifications
                  // ---------------------------------------------------------
                  SettingsSection(
                      key: _settingsSectionKeys['Notifications'],
                      title: 'Notifications',
                      children: [
                        SettingsSwitchTile(
                          title: 'Low Stock Alerts',
                          icon: LucideIcons.bellRing,
                          subtitle: 'Preference only — not yet delivered',
                          value: settings.lowStockAlerts,
                          onChanged: controller.toggleLowStockAlerts,
                        ),
                        SettingsSwitchTile(
                          title: 'Daily Sales Report',
                          icon: LucideIcons.calendarDays,
                          subtitle: 'Preference only — not yet delivered',
                          value: settings.dailySalesReport,
                          onChanged: controller.toggleDailySalesReport,
                        ),
                        SettingsSwitchTile(
                          title: 'Weekly Report',
                          icon: LucideIcons.calendarRange,
                          subtitle: 'Preference only — not yet delivered',
                          value: settings.weeklyReport,
                          onChanged: controller.toggleWeeklyReport,
                        ),
                        SettingsSwitchTile(
                          title: 'Payment Failure Alerts',
                          icon: LucideIcons.circleAlert,
                          subtitle: 'Preference only — not yet delivered',
                          value: settings.paymentFailureAlerts,
                          onChanged: controller.togglePaymentFailureAlerts,
                        ),
                        SettingsSwitchTile(
                          title: 'System Notifications',
                          icon: LucideIcons.bell,
                          subtitle: 'Preference only — not yet delivered',
                          value: settings.systemNotifications,
                          onChanged: controller.toggleSystemNotifications,
                        ),
                      ]),
                  const SizedBox(height: AppSpacing.sm + 4),

                  // ---------------------------------------------------------
                  // 8. Security
                  // ---------------------------------------------------------
                  SettingsSection(
                      key: _settingsSectionKeys['Security'],
                      title: 'Security',
                      children: [
                        SettingsNavigationTile(
                          title: 'Change Password',
                          icon: LucideIcons.lock,
                          onTap: () =>
                              _changePassword(context, ref, user?.email),
                        ),
                        SettingsSwitchTile(
                          title: 'Biometric Login',
                          icon: LucideIcons.fingerprint,
                          subtitle: 'Preference only — not yet enforced',
                          value: settings.biometricLoginEnabled,
                          onChanged: controller.toggleBiometricLoginEnabled,
                        ),
                        SettingsSwitchTile(
                          title: 'PIN Lock',
                          icon: LucideIcons.keyRound,
                          subtitle: 'Preference only — not yet enforced',
                          value: settings.pinLockEnabled,
                          onChanged: (value) async {
                            if (value) {
                              final pin = await _editTextDialog(context,
                                  title: 'Set a PIN', hint: '4–6 digits');
                              if (pin == null || pin.isEmpty) return;
                              await controller.updatePinCode(pin);
                            }
                            controller.togglePinLockEnabled(value);
                          },
                        ),
                        SettingsSwitchTile(
                          title: 'Auto Logout',
                          icon: LucideIcons.logOut,
                          subtitle: 'Preference only — not yet enforced',
                          value: settings.autoLogoutEnabled,
                          onChanged: controller.toggleAutoLogoutEnabled,
                        ),
                        SettingsNavigationTile(
                          title: 'Session Timeout',
                          icon: LucideIcons.timer,
                          valueLabel: '${settings.sessionTimeoutMinutes} min',
                          onTap: () async {
                            final value = await _editNumberDialog(context,
                                title: 'Session Timeout (minutes)',
                                initialValue: settings.sessionTimeoutMinutes);
                            if (value != null) {
                              controller.updateSessionTimeoutMinutes(value);
                            }
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Privacy Settings',
                          icon: LucideIcons.shield,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      SecurityPrivacyPage(settings: settings))),
                        ),
                        const SettingsInfoTile(
                            label: 'Connected Devices',
                            value: 'This device only'),
                      ]),
                  const SizedBox(height: AppSpacing.sm + 4),

                  // ---------------------------------------------------------
                  // 9. Backup & Sync
                  // ---------------------------------------------------------
                  SettingsSection(
                      key: _settingsSectionKeys['Backup & Sync'],
                      title: 'Backup & Sync',
                      children: [
                        SettingsInfoTile(
                          label: 'Last Sync Time',
                          value: settings.lastSyncedAt == null
                              ? 'Never'
                              : _formatDateTime(settings.lastSyncedAt!),
                        ),
                        SettingsNavigationTile(
                          title: 'Manual Sync',
                          icon: LucideIcons.refreshCw,
                          onTap: () async {
                            final success = await controller.manualSync();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(success
                                    ? 'Synced.'
                                    : 'Could not sync. Check your connection.')));
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Export Settings',
                          icon: LucideIcons.cloudUpload,
                          subtitle:
                              'Cloud backup isn\'t available — share a local export instead',
                          onTap: () => _exportSettings(context, settings),
                        ),
                        SettingsNavigationTile(
                          title: 'Import Settings',
                          icon: LucideIcons.cloudDownload,
                          subtitle: 'Restore preferences from an exported file',
                          onTap: () => _importSettings(context, ref, uid),
                        ),
                        SettingsInfoTile(
                          label: 'Offline Data',
                          value: customerStats == null
                              ? '—'
                              : '${customerStats.totalCustomers} customers cached locally',
                        ),
                        SettingsInfoTile(
                          label: 'Storage Usage',
                          value: storageUsage == null
                              ? '—'
                              : '$storageUsage bytes',
                        ),
                      ]),
                  const SizedBox(height: AppSpacing.sm + 4),

                  // ---------------------------------------------------------
                  // 10. Application
                  // ---------------------------------------------------------
                  SettingsSection(
                      key: _settingsSectionKeys['Application'],
                      title: 'Application',
                      children: [
                        SettingsNavigationTile(
                          title: 'Theme',
                          icon: LucideIcons.palette,
                          valueLabel:
                              _themeModeLabel(themeMode ?? ThemeMode.system),
                          onTap: () async {
                            final value = await _selectOptionDialog<ThemeMode>(
                              context,
                              title: 'Theme',
                              options: ThemeMode.values,
                              current: themeMode ?? ThemeMode.system,
                              labelOf: _themeModeLabel,
                            );
                            if (value != null) {
                              ref
                                  .read(themeControllerProvider.notifier)
                                  .setThemeMode(value);
                            }
                          },
                        ),
                        SettingsInfoTile(
                          label: 'Dark Mode',
                          value:
                              (themeMode ?? ThemeMode.system) == ThemeMode.dark
                                  ? 'On'
                                  : (themeMode ?? ThemeMode.system) ==
                                          ThemeMode.system
                                      ? 'Follows system'
                                      : 'Off',
                        ),
                        SettingsNavigationTile(
                          title: 'Accent Color',
                          icon: LucideIcons.paintbrush,
                          subtitle:
                              'Preference only — not yet applied app-wide',
                          valueLabel: settings.accentColor.label,
                          onTap: () async {
                            final value =
                                await _selectOptionDialog<AccentColorOption>(
                              context,
                              title: 'Accent Color',
                              options: AccentColorOption.values,
                              current: settings.accentColor,
                              labelOf: (o) => o.label,
                            );
                            if (value != null) {
                              controller.updateAccentColor(value);
                            }
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Font Size',
                          icon: LucideIcons.caseSensitive,
                          subtitle:
                              'Preference only — not yet applied app-wide',
                          valueLabel: settings.fontSize.label,
                          onTap: () async {
                            final value =
                                await _selectOptionDialog<FontSizeOption>(
                              context,
                              title: 'Font Size',
                              options: FontSizeOption.values,
                              current: settings.fontSize,
                              labelOf: (o) => o.label,
                            );
                            if (value != null) controller.updateFontSize(value);
                          },
                        ),
                        SettingsSwitchTile(
                          title: 'Animations',
                          icon: LucideIcons.sparkles,
                          value: settings.animationsEnabled,
                          onChanged: controller.toggleAnimationsEnabled,
                        ),
                        SettingsValueTile(
                            label: 'Version', value: diagnostics?.appVersion),
                        SettingsValueTile(
                            label: 'Build Number',
                            value: diagnostics?.buildNumber),
                        SettingsNavigationTile(
                          title: 'Licenses',
                          icon: LucideIcons.scrollText,
                          onTap: () => showLicensePage(
                              context: context, applicationName: 'SurfPOS AI'),
                        ),
                      ]),
                  const SizedBox(height: AppSpacing.sm + 4),

                  // ---------------------------------------------------------
                  // 11. Support
                  // ---------------------------------------------------------
                  SettingsSection(
                      key: _settingsSectionKeys['Support'],
                      title: 'Support',
                      children: [
                        SettingsNavigationTile(
                          title: 'Help Center',
                          icon: LucideIcons.circleHelp,
                          onTap: () =>
                              Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const SettingsInfoPage(
                              title: 'Help Center',
                              icon: LucideIcons.circleHelp,
                              summary:
                                  'No in-app help articles have been published yet.',
                              requirements: [
                                'Requires writing and shipping real help content — there\'s nothing to show honestly today.',
                                'Use Contact Support in the meantime for anything you\'re stuck on.',
                              ],
                            ),
                          )),
                        ),
                        SettingsNavigationTile(
                          title: 'FAQ',
                          icon: LucideIcons.messageCircleQuestion,
                          onTap: () =>
                              Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const SettingsInfoPage(
                              title: 'FAQ',
                              icon: LucideIcons.messageCircleQuestion,
                              summary:
                                  'No frequently-asked-questions content has been published yet.',
                              requirements: [
                                'Requires writing and shipping real FAQ content — there\'s nothing to show honestly today.',
                                'Use Contact Support in the meantime for anything you\'re stuck on.',
                              ],
                            ),
                          )),
                        ),
                        SettingsNavigationTile(
                          title: 'Privacy Policy',
                          icon: LucideIcons.fileLock,
                          onTap: () =>
                              Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const SettingsInfoPage(
                              title: 'Privacy Policy',
                              icon: LucideIcons.fileLock,
                              summary:
                                  'No privacy policy has been published for this app yet.',
                              requirements: [
                                'Requires drafting and publishing a real privacy policy — this app must not display placeholder legal text as if it were official.',
                              ],
                            ),
                          )),
                        ),
                        SettingsNavigationTile(
                          title: 'Terms',
                          icon: LucideIcons.fileText,
                          onTap: () =>
                              Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const SettingsInfoPage(
                              title: 'Terms of Service',
                              icon: LucideIcons.fileText,
                              summary:
                                  'No terms of service have been published for this app yet.',
                              requirements: [
                                'Requires drafting and publishing real terms — this app must not display placeholder legal text as if it were official.',
                              ],
                            ),
                          )),
                        ),
                        SettingsNavigationTile(
                          title: 'Contact Support',
                          icon: LucideIcons.headset,
                          valueLabel: AboutPage.supportEmailAddress,
                          onTap: () => _launchUrl(
                            context,
                            Uri(
                              scheme: 'mailto',
                              path: AboutPage.supportEmailAddress,
                              query: 'subject=SurfPOS AI Support',
                            ),
                          ),
                        ),
                        SettingsNavigationTile(
                          title: 'Report Bug',
                          icon: LucideIcons.bug,
                          onTap: () => _launchUrl(
                              context,
                              Uri.parse(
                                  '${AboutPage.repositoryUrl}/issues/new')),
                        ),
                        SettingsNavigationTile(
                          title: 'Feature Request',
                          icon: LucideIcons.lightbulb,
                          onTap: () => _launchUrl(
                              context,
                              Uri.parse(
                                  '${AboutPage.repositoryUrl}/issues/new')),
                        ),
                        SettingsNavigationTile(
                          title: 'About',
                          icon: LucideIcons.badgeInfo,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const AboutPage())),
                        ),
                        SettingsNavigationTile(
                          title: 'Developer Tools',
                          icon: LucideIcons.terminal,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const DeveloperToolsPage())),
                        ),
                      ]),
                  const SizedBox(height: AppSpacing.sm + 4),

                  // ---------------------------------------------------------
                  // 12. Developer (development builds only)
                  // ---------------------------------------------------------
                  if (AppEnvironment.current.isDevelopment) ...[
                    _DeveloperDiagnosticsGroup(uid: uid),
                    const SizedBox(height: AppSpacing.sm),
                    DeveloperCard(title: 'Developer', children: [
                      SettingsValueTile(
                          label: 'API Base URL',
                          value: diagnostics?.apiBaseUrl),
                      SettingsInfoTile(
                          label: 'Current Environment',
                          value: diagnostics?.environment),
                      SettingsNavigationTile(
                        title: 'View Logs',
                        onTap: () =>
                            Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const SettingsInfoPage(
                            title: 'View Logs',
                            icon: LucideIcons.terminal,
                            summary:
                                'There\'s no in-app log viewer today — backend logs go to the server console (pino), and the Flutter app doesn\'t buffer its own logs for on-device viewing.',
                            requirements: [
                              'Requires adding an in-memory/on-disk log buffer to the app and a viewer screen for it — real infrastructure work, not a toggle.',
                              'Use "Export Debug Report" below for a shareable snapshot in the meantime.',
                            ],
                          ),
                        )),
                      ),
                      SettingsNavigationTile(
                          title: 'Copy Device Info',
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const DeveloperToolsPage()))),
                      SettingsNavigationTile(
                          title: 'Export Debug Report',
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const DeveloperToolsPage()))),
                      SettingsNavigationTile(
                          title: 'Reset Demo Data',
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const DeveloperToolsPage()))),
                      Builder(builder: (context) {
                        final demoData =
                            ref.watch(demoDataControllerProvider(uid));
                        final hasDemoData = demoData.valueOrNull != null;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SettingsNavigationTile(
                              title: 'Generate Demo Business',
                              icon: LucideIcons.sparkles,
                              enabled: !demoData.isLoading,
                              subtitle: hasDemoData
                                  ? 'Regenerates the Dashboard\'s demo dataset'
                                  : 'Populate the Dashboard with a realistic demo business',
                              onTap: () => _generateDemoData(
                                  context, ref, uid, dashboard),
                            ),
                            SettingsNavigationTile(
                              title: 'Clear Demo Data',
                              icon: LucideIcons.trash2,
                              iconColor: AppColors.error,
                              iconBackground: AppColors.errorContainer,
                              enabled: hasDemoData && !demoData.isLoading,
                              subtitle: hasDemoData
                                  ? null
                                  : 'No demo data generated yet',
                              onTap: () => _confirmThen(
                                context,
                                'Clear demo data?',
                                'Removes the generated demo business data from '
                                    'this device. Never affects real merchant data.',
                                () => _clearDemoData(context, ref, uid),
                              ),
                            ),
                          ],
                        );
                      }),
                      const SettingsTile(
                          title: 'Test Payment',
                          subtitle:
                              'Use the 🧪 Test Payment button on Checkout'),
                      SettingsNavigationTile(
                        title: 'Connection Diagnostics',
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const DeveloperToolsPage())),
                      ),
                    ]),
                    const SizedBox(height: AppSpacing.sm + 4),
                  ],

                  // ---------------------------------------------------------
                  // 13. Danger Zone
                  // ---------------------------------------------------------
                  DangerZoneCard(
                      key: _settingsSectionKeys['Danger Zone'],
                      children: [
                        SettingsNavigationTile(
                          title: 'Clear Cache',
                          icon: LucideIcons.trash2,
                          iconColor: AppColors.error,
                          iconBackground: AppColors.errorContainer,
                          onTap: () => _confirmThen(
                            context,
                            'Clear cache?',
                            'Clears this device\'s saved Settings data.',
                            controller.clearCache,
                          ),
                        ),
                        SettingsNavigationTile(
                          title: 'Reset Settings',
                          icon: LucideIcons.rotateCcw,
                          iconColor: AppColors.error,
                          iconBackground: AppColors.errorContainer,
                          onTap: () => _confirmThen(
                            context,
                            'Reset settings?',
                            'Resets every Settings preference on this device back to defaults.',
                            controller.resetToDefaults,
                          ),
                        ),
                        SettingsNavigationTile(
                          title: 'Delete Local Data',
                          icon: LucideIcons.databaseZap,
                          iconColor: AppColors.error,
                          iconBackground: AppColors.errorContainer,
                          onTap: () => _confirmThen(
                            context,
                            'Delete local data?',
                            'Clears this device\'s saved Settings data. Does not affect '
                                'your Customers list, Inventory, or any online account data.',
                            controller.clearCache,
                          ),
                        ),
                        SettingsNavigationTile(
                          title: 'Logout',
                          icon: LucideIcons.logOut,
                          iconColor: AppColors.error,
                          iconBackground: AppColors.errorContainer,
                          onTap: () => _confirmThen(
                              context,
                              'Log out?',
                              'You\'ll need to sign in again.',
                              () => _handleLogout(context, ref)),
                        ),
                        SettingsNavigationTile(
                          title: 'Delete Account',
                          icon: LucideIcons.userX,
                          iconColor: AppColors.error,
                          iconBackground: AppColors.errorContainer,
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Account'),
                              content: const Text(
                                  'Account deletion isn\'t available in the app yet — '
                                  'contact support to delete your account.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK')),
                              ],
                            ),
                          ),
                        ),
                      ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(
      BuildContext context, WidgetRef ref, String? email) async {
    if (email == null) return;
    await ref
        .read(passwordResetControllerProvider.notifier)
        .sendResetEmail(email);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password reset email sent to $email.')),
    );
  }

  /// Builds an in-memory [DemoBusinessSnapshot] and persists it to this
  /// module's own local blob — never touches `InventoryRepository`/
  /// `CustomerRepository`/any real repository. See [DemoDataController]'s
  /// header comment.
  Future<void> _generateDemoData(BuildContext context, WidgetRef ref,
      String uid, DashboardState? dashboard) async {
    await ref.read(demoDataControllerProvider(uid).notifier).generate(
          merchantName: dashboard?.merchant?.name,
          storeName: dashboard?.store?.name,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Demo business data generated. Check the Dashboard.')),
    );
  }

  Future<void> _clearDemoData(
      BuildContext context, WidgetRef ref, String uid) async {
    await ref.read(demoDataControllerProvider(uid).notifier).clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo data cleared.')),
    );
  }

  void _showReceiptSettingsSheet(
      BuildContext context, WidgetRef ref, SettingsData settings) {
    final controller = ref.read(settingsControllerProvider(uid).notifier);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final current =
              ref.watch(settingsControllerProvider(uid)).valueOrNull ??
                  settings;
          return BottomSheetEditor(
            title: 'Receipt Settings',
            actionLabel: 'Done',
            onAction: () => Navigator.of(sheetContext).pop(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsSwitchTile(
                  title: 'Auto Print Receipt',
                  value: current.autoPrintReceipt,
                  onChanged: controller.toggleAutoPrintReceipt,
                ),
                SettingsSwitchTile(
                  title: 'Print Customer Copy',
                  value: current.printCustomerCopy,
                  onChanged: controller.togglePrintCustomerCopy,
                ),
                SettingsSwitchTile(
                  title: 'Print Merchant Copy',
                  value: current.printMerchantCopy,
                  onChanged: controller.togglePrintMerchantCopy,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openSettingsSearch(BuildContext context) {
    showSearch<void>(
      context: context,
      delegate: SettingsSearchDelegate(
        entries: _settingsSearchEntries,
        onSectionSelected: (title) => _scrollToSection(title),
      ),
    );
  }

  void _scrollToSection(String title) {
    final key = _settingsSectionKeys[title];
    final sectionContext = key?.currentContext;
    if (sectionContext == null) return;
    Scrollable.ensureVisible(sectionContext,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _exportSettings(
      BuildContext context, SettingsData settings) async {
    await SharePlus.instance.share(ShareParams(
      text: jsonEncode(settings.toJson()),
      subject: 'SurfPOS AI Settings Export',
    ));
  }

  Future<void> _importSettings(
      BuildContext context, WidgetRef ref, String uid) async {
    final pasteController = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Settings'),
        content: TextField(
          controller: pasteController,
          maxLines: 6,
          decoration: const InputDecoration(
              hintText: 'Paste a previously exported Settings JSON here'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(pasteController.text.trim()),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty || !context.mounted) return;

    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      final parsed = SettingsData.fromJson(json);
      await ref
          .read(settingsControllerProvider(uid).notifier)
          .importSettings(parsed);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings imported.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('That doesn\'t look like a valid Settings export.')),
      );
    }
  }

  Future<void> _launchUrl(BuildContext context, Uri uri) async {
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System',
      };

  String _formatDateTime(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// The Developer section's diagnostic cards — Backend, Surfboard, Firebase
/// (from [DiagnosticsController]) and Printer (from [printerConnectionProvider]),
/// each a [DeveloperStatusCard]. "Last checked" is UI-only presentation
/// state stamped locally whenever a diagnostics refresh resolves — this
/// module has no persisted last-checked timestamp to read, so it isn't
/// invented as fake data, only shown once a real refresh has happened.
class _DeveloperDiagnosticsGroup extends ConsumerStatefulWidget {
  const _DeveloperDiagnosticsGroup({required this.uid});

  final String uid;

  @override
  ConsumerState<_DeveloperDiagnosticsGroup> createState() =>
      _DeveloperDiagnosticsGroupState();
}

class _DeveloperDiagnosticsGroupState
    extends ConsumerState<_DeveloperDiagnosticsGroup> {
  DateTime? _lastChecked;

  void _refresh() {
    ref.read(diagnosticsControllerProvider(widget.uid).notifier).refresh();
    ref.invalidate(printerConnectionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final diagnosticsAsync =
        ref.watch(diagnosticsControllerProvider(widget.uid));
    ref.listen(diagnosticsControllerProvider(widget.uid), (previous, next) {
      if (next.hasValue) setState(() => _lastChecked = DateTime.now());
    });
    final diagnostics = diagnosticsAsync.valueOrNull;
    final printerConnected =
        ref.watch(printerConnectionProvider).valueOrNull ?? false;
    final refreshing = diagnosticsAsync.isLoading && diagnosticsAsync.hasValue;
    final checkedLabel =
        _lastChecked == null ? null : _formatTime(_lastChecked!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeveloperStatusCard(
          title: 'Backend',
          status: diagnostics?.backendStatus ?? ServiceStatus.unknown,
          latency: diagnostics?.backendResponseTime == null
              ? null
              : '${diagnostics!.backendResponseTime!.inMilliseconds} ms',
          lastChecked: checkedLabel,
          isRefreshing: refreshing,
          onRefresh: _refresh,
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        DeveloperStatusCard(
          title: 'Surfboard',
          status: diagnostics?.surfboardStatus ?? ServiceStatus.unknown,
          lastChecked: checkedLabel,
          isRefreshing: refreshing,
          onRefresh: _refresh,
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        DeveloperStatusCard(
          title: 'Firebase',
          status: diagnostics?.firebaseStatus ?? ServiceStatus.unknown,
          lastChecked: checkedLabel,
          isRefreshing: refreshing,
          onRefresh: _refresh,
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        DeveloperStatusCard(
          title: 'Printer',
          status: printerConnected
              ? ServiceStatus.connected
              : ServiceStatus.disconnected,
          onRefresh: _refresh,
        ),
      ],
    );
  }
}

String _formatTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

Future<String?> _editTextDialog(
  BuildContext context, {
  required String title,
  String? initialValue,
  String? hint,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<int?> _editNumberDialog(
  BuildContext context, {
  required String title,
  required int initialValue,
}) async {
  final text = await _editTextDialog(context,
      title: title, initialValue: '$initialValue');
  if (text == null) return null;
  return int.tryParse(text) ?? initialValue;
}

Future<double?> _editPercentDialog(
  BuildContext context, {
  required String title,
  required double initialValue,
}) async {
  final text = await _editTextDialog(context,
      title: title, initialValue: '$initialValue');
  if (text == null) return null;
  return double.tryParse(text) ?? initialValue;
}

Future<T?> _selectOptionDialog<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T current,
  required String Function(T) labelOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => BottomSheetEditor(
      title: title,
      child: RadioGroup<T>(
        groupValue: current,
        onChanged: (value) => Navigator.of(context).pop(value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final option in options)
              RadioListTile<T>(
                value: option,
                contentPadding: EdgeInsets.zero,
                title: Text(labelOf(option), style: AppTypography.bodyMD),
                activeColor: AppColors.primary,
              ),
          ],
        ),
      ),
    ),
  );
}
