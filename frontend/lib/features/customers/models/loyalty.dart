import 'membership_tier.dart';

/// SurfPOS's loyalty point-earning rule (Phase CRM-1) — deliberately the
/// simplest possible scheme per the brief ("Do not build redemption yet.
/// Only earning and tracking."): one point per whole currency unit spent,
/// rounded down. Kept in this one place so the rule can be tuned later
/// without hunting down every call site — see
/// `CustomerRepositoryImpl.recordPurchase`, the only place this is called.
int pointsEarnedForAmount(double amount) =>
    amount.isFinite && amount > 0 ? amount.floor() : 0;

/// The lifetime-points threshold a tier starts at — the inverse of
/// [MembershipTier.fromLifetimePoints], kept next to it so the two can
/// never drift out of sync.
int _tierThreshold(MembershipTier tier) => switch (tier) {
      MembershipTier.silver => 0,
      MembershipTier.gold => 1000,
      MembershipTier.platinum => 5000,
      MembershipTier.diamond => 15000,
    };

/// Powers the Loyalty section's "Reward Progress" bar — how close a
/// customer is to their next membership tier. `null` means they're already
/// at the top tier (Diamond), so there's nothing further to show progress
/// toward.
({MembershipTier tier, int pointsToGo, double progress})? nextTierProgress(
    int lifetimePoints) {
  const tiersInOrder = [
    MembershipTier.gold,
    MembershipTier.platinum,
    MembershipTier.diamond,
  ];

  for (final tier in tiersInOrder) {
    final threshold = _tierThreshold(tier);
    if (lifetimePoints < threshold) {
      final previousThreshold =
          _tierThreshold(MembershipTier.values[tier.index - 1]);
      final span = threshold - previousThreshold;
      final progress = span == 0
          ? 1.0
          : ((lifetimePoints - previousThreshold) / span).clamp(0.0, 1.0);
      return (
        tier: tier,
        pointsToGo: threshold - lifetimePoints,
        progress: progress
      );
    }
  }
  return null;
}
