/// The 9 confirmed Surfboard application-status values (see
/// docs/08_ARCHITECTURE_DECISIONS.md § ADR-026 and
/// `backend/src/modules/merchant/merchantApplication.service.js`).
/// `unknown` is a defensive fallback for a value the client doesn't
/// recognize yet — never thrown, so an unexpected backend value degrades
/// gracefully rather than crashing the wizard.
enum ApplicationStatus {
  applicationInitiated,
  applicationStarted,
  applicationSubmitted,
  applicationPendingInformation,
  applicationSigned,
  applicationRejected,
  applicationCompleted,
  applicationExpired,
  merchantCreated,
  unknown;

  static ApplicationStatus fromWire(String? value) {
    return switch (value) {
      'APPLICATION_INITIATED' => ApplicationStatus.applicationInitiated,
      'APPLICATION_STARTED' => ApplicationStatus.applicationStarted,
      'APPLICATION_SUBMITTED' => ApplicationStatus.applicationSubmitted,
      'APPLICATION_PENDING_INFORMATION' => ApplicationStatus.applicationPendingInformation,
      'APPLICATION_SIGNED' => ApplicationStatus.applicationSigned,
      'APPLICATION_REJECTED' => ApplicationStatus.applicationRejected,
      'APPLICATION_COMPLETED' => ApplicationStatus.applicationCompleted,
      'APPLICATION_EXPIRED' => ApplicationStatus.applicationExpired,
      'MERCHANT_CREATED' => ApplicationStatus.merchantCreated,
      _ => ApplicationStatus.unknown,
    };
  }

  String get wireValue => switch (this) {
        ApplicationStatus.applicationInitiated => 'APPLICATION_INITIATED',
        ApplicationStatus.applicationStarted => 'APPLICATION_STARTED',
        ApplicationStatus.applicationSubmitted => 'APPLICATION_SUBMITTED',
        ApplicationStatus.applicationPendingInformation => 'APPLICATION_PENDING_INFORMATION',
        ApplicationStatus.applicationSigned => 'APPLICATION_SIGNED',
        ApplicationStatus.applicationRejected => 'APPLICATION_REJECTED',
        ApplicationStatus.applicationCompleted => 'APPLICATION_COMPLETED',
        ApplicationStatus.applicationExpired => 'APPLICATION_EXPIRED',
        ApplicationStatus.merchantCreated => 'MERCHANT_CREATED',
        ApplicationStatus.unknown => 'UNKNOWN',
      };

  /// Short, user-facing label for the result/status screen.
  String get label => switch (this) {
        ApplicationStatus.applicationInitiated => 'Application started — complete your KYB form',
        ApplicationStatus.applicationStarted => 'KYB form in progress',
        ApplicationStatus.applicationSubmitted => 'Submitted — under review',
        ApplicationStatus.applicationPendingInformation => 'Additional information needed',
        ApplicationStatus.applicationSigned => 'Signed — pending compliance review',
        ApplicationStatus.applicationRejected => 'Application rejected',
        ApplicationStatus.applicationCompleted => 'Approved — setting up your merchant account',
        ApplicationStatus.applicationExpired => 'Application expired',
        ApplicationStatus.merchantCreated => 'Your merchant account is live',
        ApplicationStatus.unknown => 'Status unavailable',
      };
}

/// Mirrors the `merchantApplications/{uid}` tracking record returned by
/// `POST/GET /merchant/applications` and `GET /merchant/applications/:id/status`
/// (see `backend/src/modules/merchant/merchantApplication.service.js`).
class MerchantApplication {
  const MerchantApplication({
    required this.applicationId,
    required this.merchantId,
    required this.storeId,
    required this.applicationStatus,
    required this.applicationUrl,
    required this.shortLinkUrl,
    required this.submittedAt,
    required this.updatedAt,
  });

  final String applicationId;
  final String? merchantId;
  final String? storeId;
  final ApplicationStatus applicationStatus;
  final String? applicationUrl;
  final String? shortLinkUrl;
  final DateTime submittedAt;
  final DateTime updatedAt;

  factory MerchantApplication.fromJson(Map<String, dynamic> json) {
    return MerchantApplication(
      applicationId: json['applicationId'] as String,
      merchantId: json['merchantId'] as String?,
      storeId: json['storeId'] as String?,
      applicationStatus: ApplicationStatus.fromWire(json['applicationStatus'] as String?),
      applicationUrl: json['applicationUrl'] as String?,
      shortLinkUrl: json['shortLinkUrl'] as String?,
      submittedAt: DateTime.fromMillisecondsSinceEpoch(json['submittedAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    );
  }

  Map<String, dynamic> toJson() => {
        'applicationId': applicationId,
        'merchantId': merchantId,
        'storeId': storeId,
        'applicationStatus': applicationStatus.wireValue,
        'applicationUrl': applicationUrl,
        'shortLinkUrl': shortLinkUrl,
        'submittedAt': submittedAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };
}
