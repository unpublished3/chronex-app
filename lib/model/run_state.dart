import 'package:chronex/model/pace.dart';

class RunState {
  final Duration time;
  final double distance;
  final Pace pace;
  final double cadence;
  final int calories;
  final int heartrate;
  final int temp;
  bool isRunning;
  bool isPaused;
  RunState({
    required this.time,
    required this.distance,
    required this.pace,
    required this.cadence,
    required this.calories,
    required this.heartrate,
    required this.temp,
    required this.isRunning,
    required this.isPaused,
  });
  RunState copyWith({
    double? distance,
    int? calories,
    Pace? pace,
    Duration? time,
    int? heartrate,
    double? cadence,
    int? temp,
    bool? isRunning,
    bool? isPaused,
  }) {
    return RunState(
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      pace: pace ?? this.pace,
      time: time ?? this.time,
      heartrate: heartrate ?? this.heartrate,
      cadence: cadence ?? this.cadence,
      temp: temp ?? this.temp,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
