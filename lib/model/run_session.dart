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
  double _cadenceSum = 0;
  int _cadenceCount = 0;
  int _currentHeartRate = 0;
  double _strideLength = 0.78; 
  DateTime? _lastMotionTime;

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
    final heightMeters = (profile.height ?? 170) / 100;
    // different formulae according to the gender
    if (profile.gender?.toLowerCase() == "female") {
      return heightMeters * 0.413;
    }
    return heightMeters * 0.415;
  }

  void updateMotion(MotionData data) {
    final now = DateTime.now();
    if (_lastMotionTime != null) {
      final seconds = now.difference(_lastMotionTime!).inMilliseconds / 1000.0;
      final deltaSteps = (data.steps - _lastStepCount).clamp(0, 9999);
      _totalSteps += deltaSteps;
      if (seconds > 0.5) {
        _currentCadence = (deltaSteps / seconds) * 60.0;
        _cadenceSum += _currentCadence;
        _cadenceCount++;
      }
    } else {
      _totalSteps += data.steps.clamp(0, 9999);
      _currentCadence = 0;
    }
    _lastStepCount = data.steps;
    _lastMotionTime = now;
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
    _lastMotionTime = DateTime.now();
  }

  Duration get elapsed {
    final totalElapsed = DateTime.now().difference(startTime);
    return totalElapsed - _pausedDuration;
  }

  double get distanceKm => (_totalSteps * _strideLength) / 1000;
  int get totalSteps => _totalSteps;
  Pace get pace {
    if (distanceKm == 0) return Pace(secondsPerKilometer: 0);
    final secondsPerKm = elapsed.inSeconds / distanceKm;
    return Pace(secondsPerKilometer: secondsPerKm.round());
  }

  double get cadence => _currentCadence;
  double get avgCadence => _cadenceCount > 0 ? _cadenceSum / _cadenceCount : 0;
  int get heartRate => _currentHeartRate;
}
