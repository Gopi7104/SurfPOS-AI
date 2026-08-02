import 'merchant_profile_draft.dart';
import 'printer_config.dart';

enum DefaultPaymentMethod {
  card,
  cash,
  other;

  String get label => switch (this) {
        DefaultPaymentMethod.card => 'Card',
        DefaultPaymentMethod.cash => 'Cash',
        DefaultPaymentMethod.other => 'Other',
      };
}

enum BarcodeFormat {
  ean13,
  upc,
  code128;

  String get label => switch (this) {
        BarcodeFormat.ean13 => 'EAN-13',
        BarcodeFormat.upc => 'UPC',
        BarcodeFormat.code128 => 'CODE-128',
      };
}

enum ImageUploadQuality {
  low,
  medium,
  high;

  String get label => switch (this) {
        ImageUploadQuality.low => 'Low',
        ImageUploadQuality.medium => 'Medium',
        ImageUploadQuality.high => 'High',
      };
}

enum AccentColorOption {
  blueberry,
  creamSoda,
  forest,
  slate;

  String get label => switch (this) {
        AccentColorOption.blueberry => 'Blueberry',
        AccentColorOption.creamSoda => 'Cream Soda',
        AccentColorOption.forest => 'Forest',
        AccentColorOption.slate => 'Slate',
      };
}

enum FontSizeOption {
  small,
  medium,
  large;

  String get label => switch (this) {
        FontSizeOption.small => 'Small',
        FontSizeOption.medium => 'Medium',
        FontSizeOption.large => 'Large',
      };
}

/// Every merchant-configurable Settings preference this module owns,
/// persisted as one JSON blob via [SettingsLocalStorage] — same
/// read-modify-write-the-whole-thing shape `CustomerLocalStorage`/
/// `ProductImageLocalStorage` already use. [ThemeRepository] owns theme
/// mode separately (see its own header comment) — everything else lives
/// here.
///
/// Several fields below are genuinely persisted and displayed but have no
/// downstream system wired to react to them yet, because doing so would
/// require modifying a restricted feature (Billing/Inventory/Receipt/
/// Authentication/...) this module must not touch. Each such field says so
/// explicitly rather than silently pretending to be fully wired — see
/// `SettingsHomePage`'s header comment for the complete list.
class SettingsData {
  const SettingsData({
    this.merchantProfile = const MerchantProfileDraft(),
    this.businessAddress,
    this.taxNumber,
    this.businessHours,
    this.currencyCode = 'USD',
    this.timeZone,
    this.defaultPaymentMethod = DefaultPaymentMethod.card,
    this.autoPrintReceipt = false,
    this.printCustomerCopy = true,
    this.printMerchantCopy = false,
    this.openCashDrawer = false,
    this.roundCashPayments = false,
    this.taxIncludedPricing = false,
    this.barcodeBeepOnScan = true,
    this.printerPaperSize = PrinterPaperSize.mm58,
    this.lowStockThreshold = 5,
    this.autoSku = true,
    this.barcodeFormat = BarcodeFormat.ean13,
    this.defaultTaxPercent = 0,
    this.defaultDiscountPercent = 0,
    this.imageUploadQuality = ImageUploadQuality.medium,
    this.loyaltyEnabled = false,
    this.collectPhoneNumber = true,
    this.collectEmail = false,
    this.birthdayRewards = false,
    this.marketingConsent = false,
    this.lowStockAlerts = true,
    this.dailySalesReport = false,
    this.weeklyReport = false,
    this.paymentFailureAlerts = true,
    this.systemNotifications = true,
    this.pinLockEnabled = false,
    this.pinCode,
    this.biometricLoginEnabled = false,
    this.autoLogoutEnabled = false,
    this.sessionTimeoutMinutes = 15,
    this.lastSyncedAt,
    this.accentColor = AccentColorOption.blueberry,
    this.fontSize = FontSizeOption.medium,
    this.animationsEnabled = true,
  });

  final MerchantProfileDraft merchantProfile;

  // Business
  final String? businessAddress;
  final String? taxNumber;
  final String? businessHours;

  /// Display-only preference, editable here — not derived from a live
  /// Surfboard currency field (`MerchantProfileModel` has none); "Future-
  /// ready" per the Phase 7 brief, not yet read by Billing/Reports.
  final String currencyCode;
  final String? timeZone;

  // POS
  final DefaultPaymentMethod defaultPaymentMethod;
  final bool autoPrintReceipt;
  final bool printCustomerCopy;
  final bool printMerchantCopy;
  final bool openCashDrawer;
  final bool roundCashPayments;
  final bool taxIncludedPricing;
  final bool barcodeBeepOnScan;
  final PrinterPaperSize printerPaperSize;

  // Inventory
  final int lowStockThreshold;
  final bool autoSku;
  final BarcodeFormat barcodeFormat;
  final double defaultTaxPercent;
  final double defaultDiscountPercent;
  final ImageUploadQuality imageUploadQuality;

  // Customers
  final bool loyaltyEnabled;
  final bool collectPhoneNumber;
  final bool collectEmail;
  final bool birthdayRewards;
  final bool marketingConsent;

  // Notifications — preference-only: this app has no push-notification
  // delivery mechanism wired up yet, so these control nothing downstream
  // today. Persisted so the day one exists, it can just read this.
  final bool lowStockAlerts;
  final bool dailySalesReport;
  final bool weeklyReport;
  final bool paymentFailureAlerts;
  final bool systemNotifications;

  // Security — preference-only: PIN/biometric/auto-logout aren't enforced
  // anywhere in the app yet (that would mean adding a gate inside
  // Authentication, out of scope here). [pinCode] is a plain string in
  // secure storage, not hashed — acceptable at this app's current "single
  // local preference blob" trust level, revisit if this ever gates a real
  // security boundary.
  final bool pinLockEnabled;
  final String? pinCode;
  final bool biometricLoginEnabled;
  final bool autoLogoutEnabled;
  final int sessionTimeoutMinutes;

  // Backup & Sync
  final DateTime? lastSyncedAt;

  // Application — preference-only: this app's screens read fixed
  // `AppColors`/`AppTypography` constants directly rather than
  // `Theme.of(context)`, so accent color/font size are persisted but don't
  // yet visibly re-theme already-built screens (see `AppTheme`'s own
  // "only place ThemeData is constructed" rule). Theme *mode*
  // (light/dark/system) is the one Application setting that is fully
  // wired — see [ThemeController].
  final AccentColorOption accentColor;
  final FontSizeOption fontSize;
  final bool animationsEnabled;

  SettingsData copyWith({
    MerchantProfileDraft? merchantProfile,
    String? businessAddress,
    String? taxNumber,
    String? businessHours,
    String? currencyCode,
    String? timeZone,
    DefaultPaymentMethod? defaultPaymentMethod,
    bool? autoPrintReceipt,
    bool? printCustomerCopy,
    bool? printMerchantCopy,
    bool? openCashDrawer,
    bool? roundCashPayments,
    bool? taxIncludedPricing,
    bool? barcodeBeepOnScan,
    PrinterPaperSize? printerPaperSize,
    int? lowStockThreshold,
    bool? autoSku,
    BarcodeFormat? barcodeFormat,
    double? defaultTaxPercent,
    double? defaultDiscountPercent,
    ImageUploadQuality? imageUploadQuality,
    bool? loyaltyEnabled,
    bool? collectPhoneNumber,
    bool? collectEmail,
    bool? birthdayRewards,
    bool? marketingConsent,
    bool? lowStockAlerts,
    bool? dailySalesReport,
    bool? weeklyReport,
    bool? paymentFailureAlerts,
    bool? systemNotifications,
    bool? pinLockEnabled,
    String? pinCode,
    bool? biometricLoginEnabled,
    bool? autoLogoutEnabled,
    int? sessionTimeoutMinutes,
    DateTime? lastSyncedAt,
    AccentColorOption? accentColor,
    FontSizeOption? fontSize,
    bool? animationsEnabled,
  }) {
    return SettingsData(
      merchantProfile: merchantProfile ?? this.merchantProfile,
      businessAddress: businessAddress ?? this.businessAddress,
      taxNumber: taxNumber ?? this.taxNumber,
      businessHours: businessHours ?? this.businessHours,
      currencyCode: currencyCode ?? this.currencyCode,
      timeZone: timeZone ?? this.timeZone,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      printCustomerCopy: printCustomerCopy ?? this.printCustomerCopy,
      printMerchantCopy: printMerchantCopy ?? this.printMerchantCopy,
      openCashDrawer: openCashDrawer ?? this.openCashDrawer,
      roundCashPayments: roundCashPayments ?? this.roundCashPayments,
      taxIncludedPricing: taxIncludedPricing ?? this.taxIncludedPricing,
      barcodeBeepOnScan: barcodeBeepOnScan ?? this.barcodeBeepOnScan,
      printerPaperSize: printerPaperSize ?? this.printerPaperSize,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      autoSku: autoSku ?? this.autoSku,
      barcodeFormat: barcodeFormat ?? this.barcodeFormat,
      defaultTaxPercent: defaultTaxPercent ?? this.defaultTaxPercent,
      defaultDiscountPercent:
          defaultDiscountPercent ?? this.defaultDiscountPercent,
      imageUploadQuality: imageUploadQuality ?? this.imageUploadQuality,
      loyaltyEnabled: loyaltyEnabled ?? this.loyaltyEnabled,
      collectPhoneNumber: collectPhoneNumber ?? this.collectPhoneNumber,
      collectEmail: collectEmail ?? this.collectEmail,
      birthdayRewards: birthdayRewards ?? this.birthdayRewards,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
      dailySalesReport: dailySalesReport ?? this.dailySalesReport,
      weeklyReport: weeklyReport ?? this.weeklyReport,
      paymentFailureAlerts: paymentFailureAlerts ?? this.paymentFailureAlerts,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      pinLockEnabled: pinLockEnabled ?? this.pinLockEnabled,
      pinCode: pinCode ?? this.pinCode,
      biometricLoginEnabled:
          biometricLoginEnabled ?? this.biometricLoginEnabled,
      autoLogoutEnabled: autoLogoutEnabled ?? this.autoLogoutEnabled,
      sessionTimeoutMinutes:
          sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      accentColor: accentColor ?? this.accentColor,
      fontSize: fontSize ?? this.fontSize,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'merchantProfile': merchantProfile.toJson(),
        'businessAddress': businessAddress,
        'taxNumber': taxNumber,
        'businessHours': businessHours,
        'currencyCode': currencyCode,
        'timeZone': timeZone,
        'defaultPaymentMethod': defaultPaymentMethod.name,
        'autoPrintReceipt': autoPrintReceipt,
        'printCustomerCopy': printCustomerCopy,
        'printMerchantCopy': printMerchantCopy,
        'openCashDrawer': openCashDrawer,
        'roundCashPayments': roundCashPayments,
        'taxIncludedPricing': taxIncludedPricing,
        'barcodeBeepOnScan': barcodeBeepOnScan,
        'printerPaperSize': printerPaperSize.name,
        'lowStockThreshold': lowStockThreshold,
        'autoSku': autoSku,
        'barcodeFormat': barcodeFormat.name,
        'defaultTaxPercent': defaultTaxPercent,
        'defaultDiscountPercent': defaultDiscountPercent,
        'imageUploadQuality': imageUploadQuality.name,
        'loyaltyEnabled': loyaltyEnabled,
        'collectPhoneNumber': collectPhoneNumber,
        'collectEmail': collectEmail,
        'birthdayRewards': birthdayRewards,
        'marketingConsent': marketingConsent,
        'lowStockAlerts': lowStockAlerts,
        'dailySalesReport': dailySalesReport,
        'weeklyReport': weeklyReport,
        'paymentFailureAlerts': paymentFailureAlerts,
        'systemNotifications': systemNotifications,
        'pinLockEnabled': pinLockEnabled,
        'pinCode': pinCode,
        'biometricLoginEnabled': biometricLoginEnabled,
        'autoLogoutEnabled': autoLogoutEnabled,
        'sessionTimeoutMinutes': sessionTimeoutMinutes,
        'lastSyncedAt': lastSyncedAt?.millisecondsSinceEpoch,
        'accentColor': accentColor.name,
        'fontSize': fontSize.name,
        'animationsEnabled': animationsEnabled,
      };

  factory SettingsData.fromJson(Map<String, dynamic> json) {
    T enumOrDefault<T extends Enum>(List<T> values, String? name, T fallback) {
      if (name == null) return fallback;
      return values.firstWhere((v) => v.name == name, orElse: () => fallback);
    }

    return SettingsData(
      merchantProfile: json['merchantProfile'] == null
          ? const MerchantProfileDraft()
          : MerchantProfileDraft.fromJson(
              json['merchantProfile'] as Map<String, dynamic>),
      businessAddress: json['businessAddress'] as String?,
      taxNumber: json['taxNumber'] as String?,
      businessHours: json['businessHours'] as String?,
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      timeZone: json['timeZone'] as String?,
      defaultPaymentMethod: enumOrDefault(DefaultPaymentMethod.values,
          json['defaultPaymentMethod'] as String?, DefaultPaymentMethod.card),
      autoPrintReceipt: json['autoPrintReceipt'] as bool? ?? false,
      printCustomerCopy: json['printCustomerCopy'] as bool? ?? true,
      printMerchantCopy: json['printMerchantCopy'] as bool? ?? false,
      openCashDrawer: json['openCashDrawer'] as bool? ?? false,
      roundCashPayments: json['roundCashPayments'] as bool? ?? false,
      taxIncludedPricing: json['taxIncludedPricing'] as bool? ?? false,
      barcodeBeepOnScan: json['barcodeBeepOnScan'] as bool? ?? true,
      printerPaperSize: enumOrDefault(PrinterPaperSize.values,
          json['printerPaperSize'] as String?, PrinterPaperSize.mm58),
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 5,
      autoSku: json['autoSku'] as bool? ?? true,
      barcodeFormat: enumOrDefault(BarcodeFormat.values,
          json['barcodeFormat'] as String?, BarcodeFormat.ean13),
      defaultTaxPercent: (json['defaultTaxPercent'] as num?)?.toDouble() ?? 0,
      defaultDiscountPercent:
          (json['defaultDiscountPercent'] as num?)?.toDouble() ?? 0,
      imageUploadQuality: enumOrDefault(ImageUploadQuality.values,
          json['imageUploadQuality'] as String?, ImageUploadQuality.medium),
      loyaltyEnabled: json['loyaltyEnabled'] as bool? ?? false,
      collectPhoneNumber: json['collectPhoneNumber'] as bool? ?? true,
      collectEmail: json['collectEmail'] as bool? ?? false,
      birthdayRewards: json['birthdayRewards'] as bool? ?? false,
      marketingConsent: json['marketingConsent'] as bool? ?? false,
      lowStockAlerts: json['lowStockAlerts'] as bool? ?? true,
      dailySalesReport: json['dailySalesReport'] as bool? ?? false,
      weeklyReport: json['weeklyReport'] as bool? ?? false,
      paymentFailureAlerts: json['paymentFailureAlerts'] as bool? ?? true,
      systemNotifications: json['systemNotifications'] as bool? ?? true,
      pinLockEnabled: json['pinLockEnabled'] as bool? ?? false,
      pinCode: json['pinCode'] as String?,
      biometricLoginEnabled: json['biometricLoginEnabled'] as bool? ?? false,
      autoLogoutEnabled: json['autoLogoutEnabled'] as bool? ?? false,
      sessionTimeoutMinutes:
          (json['sessionTimeoutMinutes'] as num?)?.toInt() ?? 15,
      lastSyncedAt: json['lastSyncedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['lastSyncedAt'] as int),
      accentColor: enumOrDefault(AccentColorOption.values,
          json['accentColor'] as String?, AccentColorOption.blueberry),
      fontSize: enumOrDefault(FontSizeOption.values,
          json['fontSize'] as String?, FontSizeOption.medium),
      animationsEnabled: json['animationsEnabled'] as bool? ?? true,
    );
  }
}
