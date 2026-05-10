/// Estimates Pirate Chain wallet birthday heights from approximate dates.
///
/// Pirate targets a 60 second block time, so date-based estimates use
/// 1,440 blocks per day. Keep this centralized so onboarding and settings do
/// not drift apart.
class BirthdayHeightEstimator {
  const BirthdayHeightEstimator._();

  static const int blocksPerDay = 1440;
  static const int minYear = 2018;
  static final DateTime pirateGenesisUtc = DateTime.utc(2018, 8, 29);

  static int estimateForMonth({
    required int year,
    required int month,
    int? latestHeight,
  }) {
    final selected = DateTime.utc(year, month, 1);
    if (selected.isBefore(pirateGenesisUtc)) {
      return 1;
    }

    final daysFromGenesis = selected.difference(pirateGenesisUtc).inDays;
    final estimate = (daysFromGenesis * blocksPerDay) + 1;
    if (latestHeight != null) {
      return estimate.clamp(1, latestHeight);
    }
    return estimate < 1 ? 1 : estimate;
  }
}
