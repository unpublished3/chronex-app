import 'package:hive/hive.dart';

part 'pace_split_data.g.dart';

/// Stored separately from [Run] (own Hive box, own typeId) so the core run
/// record stays lean. Linked back to its Run via [runKey], which is that
/// Run's Hive box key (see stopRun() in active_run_track_provider.dart).
@HiveType(typeId: 2)
class PaceSplitData extends HiveObject {
  @HiveField(0)
  final int runKey; // matches the linked Run's Hive key (auto-assigned by box.add)

  @HiveField(1)
  final List<double> splits; // seconds per km, in km order (index 0 = first km)

  @HiveField(2)
  final int percentile; // 0-100, this run's pace percentile vs run history

  PaceSplitData({
    required this.runKey,
    required this.splits,
    required this.percentile,
  });
}
