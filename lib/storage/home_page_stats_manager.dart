import 'package:chronex/model/pace.dart';
import 'package:chronex/model/run.dart';
import 'package:chronex/model/run_stats.dart';
import 'package:chronex/storage/hive_manager.dart';

class HomePageStatsManager {
  HomePageStatsManager._();
  static final HomePageStatsManager _instance = HomePageStatsManager._();
  factory HomePageStatsManager() => _instance;
  final HiveManager _hiveManager = HiveManager('runBox');
  Future<RunStats> calculateStats() async {
    final List<Run> runs = (await _hiveManager.readAll())
        .whereType<Run>()
        .toList();
    if (runs.isEmpty) {
      return RunStats(
        totalRuns: 0,
        totalDistance: 0,
        totalTime: Duration.zero,
        avgPace: Pace(secondsPerKilometer: 0),
      );
    }
    double totalDistance = 0;
    int totalSeconds = 0;

    for (final run in runs) {
      totalDistance += run.distance ?? 0;
      totalSeconds += run.timeSec ?? 0;
    }
    final avgPaceSec = totalDistance > 0 ? (totalSeconds / totalDistance).round() : 0;
    return RunStats(
      totalRuns: runs.length,
      totalDistance: totalDistance,
      totalTime: Duration(seconds: totalSeconds),
      avgPace: Pace(secondsPerKilometer: avgPaceSec),
    );
  }
}
