import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_wallet/core/services/birthday_height_estimator.dart';

void main() {
  group('BirthdayHeightEstimator', () {
    test('uses 60 second Pirate blocks for 2026 dates', () {
      final height = BirthdayHeightEstimator.estimateForMonth(
        year: 2026,
        month: 4,
      );

      expect(height, 3991681);
    });

    test('clamps future estimates to the latest known tip', () {
      final height = BirthdayHeightEstimator.estimateForMonth(
        year: 2026,
        month: 6,
        latestHeight: 4000000,
      );

      expect(height, 4000000);
    });

    test('returns genesis for pre-genesis dates', () {
      final height = BirthdayHeightEstimator.estimateForMonth(
        year: 2018,
        month: 1,
      );

      expect(height, 1);
    });
  });
}
