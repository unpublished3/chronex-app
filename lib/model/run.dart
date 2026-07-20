import 'package:hive/hive.dart';
part 'run.g.dart';

@HiveType(typeId: 1)
class Run extends HiveObject {
  @HiveField(0)
  final int? timeSec;

  @HiveField(1)
  final double? distance;

  @HiveField(2)
  final int? avgSecondsPerKm;

  @HiveField(3)
  final int? avgCadence;

  @HiveField(4)
  final int? calories;

  @HiveField(5)
  final int? heartRate;

  @HiveField(6)
  final int? temp;

  @HiveField(7)
  final DateTime? completedAt;

  Run({
    required this.timeSec,
    required this.distance,
    required this.avgSecondsPerKm,
    required this.avgCadence,
    required this.calories,
    required this.heartRate,
    this.temp,
    required this.completedAt,
  });

  Duration get runTime => Duration(seconds: timeSec ?? 0);
}
