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

  // Smoothing & Cadence tracking
  double _smoothedCadence = 0.0;
  double _cadenceSum = 0.0;
  int _cadenceCount = 0;

  int _currentHeartRate = 0;
  bool _hasValidHr = false;

  double _accumulatedDistanceKm = 0.0;
  double _baseStrideLength = 0.78;

  DateTime? _lastMotionTime;

  final List<Map<String, dynamic>> _recentSamples = [];

  final List<double> _splitSeconds = [];
  int _lastSplitKmFloor = 0;
  Duration _lastSplitElapsed = Duration.zero;

  RunSession() : startTime = DateTime.now() {
    _initStrideLength();
  }

  Future<void> _initStrideLength() async {
    final profile = await ProfileManager().getProfile();
    if (profile != null) {
      _baseStrideLength = _calculateBaseStrideLength(profile);
    }
  }

  double _calculateBaseStrideLength(UserProfile profile) {
    final heightMeters = (profile.height ?? 170) / 100;
    return (profile.gender?.toLowerCase() == "female") ? heightMeters * 0.413 : heightMeters * 0.415;
  }

  double get _currentDynamicStride {
    if (_smoothedCadence < 110) return _baseStrideLength;

    double scaleFactor = 1.0 + ((_smoothedCadence - 110) * 0.0064);
    scaleFactor = scaleFactor.clamp(1.0, 1.5);

    return _baseStrideLength * scaleFactor;
  }

  void updateMotion(MotionData data) {
    final now = DateTime.now();
    final deltaSteps = (data.steps - _lastStepCount).clamp(0, 9999);

    if (_lastMotionTime != null) {
      final seconds = now.difference(_lastMotionTime!).inMilliseconds / 1000.0;

      if (deltaSteps > 0) {
        if (seconds >= 3.0 && seconds <= 12.0) {
          double instantCadence = (deltaSteps / seconds) * 60.0;

          instantCadence = instantCadence.clamp(0.0, 200.0);

          const double alpha = 0.3;
          if (_smoothedCadence == 0.0) {
            _smoothedCadence = instantCadence;
          } else {
            _smoothedCadence = (instantCadence * alpha) + (_smoothedCadence * (1.0 - alpha));
          }
          _cadenceSum += _smoothedCadence;
          _cadenceCount++;
        }

        final addedKm = (deltaSteps * _currentDynamicStride) / 1000.0;
        _accumulatedDistanceKm += addedKm;

        _addSample(now, _accumulatedDistanceKm);

        _totalSteps += deltaSteps;
      }
    } else {
      // First motion update
      final initialSteps = deltaSteps.clamp(0, 9999);
      if (initialSteps > 0) {
        _totalSteps += initialSteps;
        _accumulatedDistanceKm += (initialSteps * _baseStrideLength) / 1000.0;
        _addSample(now, _accumulatedDistanceKm);
      }
    }

    _lastStepCount = data.steps;
    _lastMotionTime = now;

    _checkForSplit();
  }

  void _addSample(DateTime timestamp, double distanceKm) {
    _recentSamples.add({'time': timestamp, 'distance': distanceKm});
    final cutoff = timestamp.subtract(const Duration(seconds: 30));
    _recentSamples.removeWhere((s) => (s['time'] as DateTime).isBefore(cutoff));
  }

  void _checkForSplit() {
    final currentKmFloor = distanceKm.floor();
    if (currentKmFloor > _lastSplitKmFloor) {
      final splitDuration = elapsed - _lastSplitElapsed;
      _splitSeconds.add(splitDuration.inSeconds.toDouble());
      _lastSplitKmFloor = currentKmFloor;
      _lastSplitElapsed = elapsed;
    }
  }

  void updateHeartRate(HeartRateData data) {
    if (data.bpm > 0) {
      _currentHeartRate = data.bpm;
      if (data.bpm > 90 && cadence > 160) {
        _currentHeartRate = data.bpm - 25;
      }
      _hasValidHr = true;
    }
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

  double get distanceKm => _accumulatedDistanceKm;
  int get totalSteps => _totalSteps;

  /// Smooth Pace derived over the last 15-second window
  Pace get pace {
    if (_recentSamples.length < 2) return Pace(secondsPerKilometer: 0);

    final oldest = _recentSamples.first;
    final newest = _recentSamples.last;

    final double deltaDistance = newest['distance'] - oldest['distance'];
    final double deltaSeconds = (newest['time'] as DateTime).difference(oldest['time'] as DateTime).inMilliseconds / 1000.0;

    if (deltaDistance <= 0 || deltaSeconds <= 0) return Pace(secondsPerKilometer: 0);

    final secondsPerKm = deltaSeconds / deltaDistance;
    return Pace(secondsPerKilometer: secondsPerKm.round().clamp(0, 3600));
  }

  Pace get avgPace {
    final totalSeconds = elapsed.inSeconds;
    if (_accumulatedDistanceKm <= 0 || totalSeconds <= 0) {
      return Pace(secondsPerKilometer: 0);
    }
    final secondsPerKm = totalSeconds / _accumulatedDistanceKm;
    return Pace(secondsPerKilometer: secondsPerKm.round().clamp(0, 3600));
  }

  double get cadence => _smoothedCadence;
  double get avgCadence => _cadenceCount > 0 ? _cadenceSum / _cadenceCount : 0;
  int get heartRate => _hasValidHr ? _currentHeartRate : -1;
  List<double> get paceSplits => List.unmodifiable(_splitSeconds);
}
