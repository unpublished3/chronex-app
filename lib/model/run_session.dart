import 'package:chronex/model/pace.dart';
import 'package:chronex/model/sensor_data.dart';
import 'package:chronex/model/user_profile.dart';
import 'package:chronex/storage/profile_manager.dart';

class RunSession {
  final DateTime startTime;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStart;
  int _lastStepCount = 0;
  int _totalSteps = 0;
  double _currentCadence = 0;
  int _currentHeartRate = 0;
  double _strideLength = 0.78; // a default fallback until profile loads

  RunSession() : startTime = DateTime.now() {
    _initStrideLength();
  }

  Future<void> _initStrideLength() async {
    final profile = await ProfileManager().getProfile();
    if (profile != null) {
      _strideLength = _calculateStrideLength(profile);
    }
  }

  double _calculateStrideLength(UserProfile profile) {
    // height should be in meters to calc stride length
    final heightMeters = profile.height / 100;
    // different formulae according to the gender
    if (profile.gender.toLowerCase() == "female") {
      return heightMeters * 0.413;
    }
    return heightMeters * 0.415;
  }

  void updateMotion(MotionData data) {
    if (_lastStepCount > 0) {
      _totalSteps += (data.steps - _lastStepCount).clamp(0, 9999);
    }
    _lastStepCount = data.steps;
    _currentCadence = data.cadence;
  }

  void updateHeartRate(HeartRateData data) {
    _currentHeartRate = data.bpm;
  }

  void pause() {
    _pauseStart = DateTime.now();
  }

  void resume() {
    if (_pauseStart != null) {
      _pausedDuration += DateTime.now().difference(_pauseStart!);
      _pauseStart = null;
    }
  }

  Duration get elapsed {
    final totalElapsed = DateTime.now().difference(startTime);
    return totalElapsed - _pausedDuration;
  }

  double get distanceKm => (_totalSteps * _strideLength) / 1000;
  Pace get pace {
    if (distanceKm == 0) return Pace(secondsPerKilometer: 0);
    final secondsPerKm = elapsed.inSeconds / distanceKm;
    return Pace(secondsPerKilometer: secondsPerKm.round());
  }

  double get cadence => _currentCadence;
  int get heartRate => _currentHeartRate;
}
