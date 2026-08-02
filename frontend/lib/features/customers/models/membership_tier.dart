/// Loyalty membership tier — always *derived* from
/// [CustomerModel.lifetimePoints], never stored separately, so it can never
/// drift out of sync with the points that earned it. Thresholds are a
/// simple, documented placeholder scheme (no loyalty-program spec exists
/// yet) — easy to tune in one place later without touching any caller.
enum MembershipTier {
  silver,
  gold,
  platinum,
  diamond;

  String get label => switch (this) {
        MembershipTier.silver => 'Silver',
        MembershipTier.gold => 'Gold',
        MembershipTier.platinum => 'Platinum',
        MembershipTier.diamond => 'Diamond',
      };

  static MembershipTier fromLifetimePoints(int points) {
    if (points >= 15000) return MembershipTier.diamond;
    if (points >= 5000) return MembershipTier.platinum;
    if (points >= 1000) return MembershipTier.gold;
    return MembershipTier.silver;
  }
}
