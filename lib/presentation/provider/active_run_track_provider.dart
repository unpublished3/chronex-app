import 'dart:async';
import 'package:chronex/model/ble_uuids.dart';
import 'package:chronex/model/pace.dart';
import 'package:chronex/model/run_session.dart';
import 'package:chronex/model/run_state.dart';
import 'package:chronex/model/sensor_data.dart';
import 'package:chronex/presentation/provider/bluetooth_provider.dart';
import 'package:chronex/storage/profile_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RunStateNotifier extends Notifier<RunState> {
  RunSession? _session;
  StreamSubscription? _motionSub;
  StreamSubscription? _heartRateSub;
  Timer? _timer;
  double userWeight = 70; // fallback value, used for calories calc
  @override
  RunState build() {
    // cleanup when provider is disposed
    ref.onDispose(() {
      _motionSub?.cancel();
      _heartRateSub?.cancel();
      _timer?.cancel();
    });

    return RunState(
      time: const Duration(hours: 0, minutes: 0, seconds: 0),
      distance: 0,
      pace: Pace(secondsPerKilometer: 0),
      cadence: 0,
      calories: 0,
      heartrate: 0,
      temp: 0,
      isRunning: false,
      isPaused: false,
    );
  }

  void _startStreams({
    required Stream<List<int>> motionStream,
    required Stream<List<int>> heartRateStream,
  }) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(time: _session?.elapsed);
    });

    _motionSub = motionStream.listen((bytes) {
      if (bytes.length < 8) return;
      final session = _session;
      if (session == null) return;
      final motion = MotionData.fromBytes(bytes);
      session.updateMotion(motion);
      state = state.copyWith(
        distance: session.distanceKm,
        pace: session.pace,
        cadence: session.cadence,
        calories: _calculateCalories(session),
      );
    });

    _heartRateSub = heartRateStream.listen((bytes) {
      if (bytes.length < 2) return;
      final hr = HeartRateData.fromBytes(bytes);
      _session?.updateHeartRate(hr);
      state = state.copyWith(heartrate: hr.bpm);
    });
  }

  void startRun(BluetoothNotifier ble) async {
    state = state.copyWith(isRunning: true, isPaused: false);
    final profile = await ProfileManager().getProfile();
    if (profile != null) userWeight = profile.weight;

    _session = RunSession();

    //Get streams from ble provider
    final motionStream = ble.subscribeTo(BleUuids.motion).map((c) => c.value);
    final heartRateStream = ble
        .subscribeTo(BleUuids.heartRate)
        .map((c) => c.value);
    _startStreams(motionStream: motionStream, heartRateStream: heartRateStream);
  }

  int _calculateCalories(RunSession session) {
    const double met = 8.0;
    final hours = session.elapsed.inSeconds / 3600;
    return (met * userWeight * hours).round();
  }

  void pauseRun() {
    _session?.pause();
    _motionSub?.cancel();
    _heartRateSub?.cancel();
    _timer?.cancel();
    state = state.copyWith(isPaused: true, isRunning: false);
  }

  void resumeRun(BluetoothNotifier ble) {
    state = state.copyWith(isRunning: true, isPaused: false);
    if (_session == null) return;
    _session?.resume();
    final motionStream = ble.subscribeTo(BleUuids.motion).map((c) => c.value);
    final heartRateStream = ble
        .subscribeTo(BleUuids.heartRate)
        .map((c) => c.value);
    _startStreams(motionStream: motionStream, heartRateStream: heartRateStream);
  }

  void stopRun() {
    _motionSub?.cancel();
    _heartRateSub?.cancel();
    _timer?.cancel();
    _session = null;
    state = state.copyWith(isPaused: false, isRunning: false);
  }
}

final runStateProvider = NotifierProvider<RunStateNotifier, RunState>(() {
  return RunStateNotifier();
});
