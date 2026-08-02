import 'package:flutter_test/flutter_test.dart';
import 'package:surfpos_ai/features/customers/models/loyalty.dart';
import 'package:surfpos_ai/features/customers/models/membership_tier.dart';

void main() {
  group('pointsEarnedForAmount', () {
    test('earns one point per whole currency unit, rounded down', () {
      expect(pointsEarnedForAmount(42.99), 42);
      expect(pointsEarnedForAmount(1), 1);
    });

    test('zero, negative, or non-finite amounts earn no points', () {
      expect(pointsEarnedForAmount(0), 0);
      expect(pointsEarnedForAmount(-10), 0);
      expect(pointsEarnedForAmount(double.nan), 0);
      expect(pointsEarnedForAmount(double.infinity), 0);
    });
  });

  group('nextTierProgress', () {
    test('a brand-new Silver customer progresses toward Gold', () {
      final progress = nextTierProgress(0);

      expect(progress?.tier, MembershipTier.gold);
      expect(progress?.pointsToGo, 1000);
      expect(progress?.progress, 0.0);
    });

    test('progress is proportional partway through a tier', () {
      final progress = nextTierProgress(2500);

      expect(progress?.tier, MembershipTier.platinum);
      expect(progress?.pointsToGo, 2500);
      expect(progress?.progress, closeTo(0.375, 0.001));
    });

    test('a Diamond customer (top tier) has no further progress to show', () {
      expect(nextTierProgress(15000), isNull);
      expect(nextTierProgress(50000), isNull);
    });
  });
}
