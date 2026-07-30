/// Mirrors the `users/{uid}` profile shape returned by every `/auth`
/// endpoint (see `backend/src/modules/auth/auth.service.js` and
/// docs/03_DATABASE_DESIGN.md § 4.10) — uid/email/displayName/role/status/
/// createdAt/updatedAt.
///
/// No `merchantId` field: it isn't returned by any `/auth` endpoint yet —
/// merchant creation is a separate, not-yet-wired flow
/// (`POST /merchant/applications`). Add it here once that's connected.
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String role;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      role: json['role'] as String,
      status: json['status'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': role,
        'status': status,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };
}
