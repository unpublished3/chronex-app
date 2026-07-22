import 'dart:async';

import 'package:chronex/model/ble_uuids.dart';
import 'package:chronex/model/pace.dart';
import 'package:chronex/model/pace_split_data.dart';
import 'package:chronex/model/run.dart';
import 'package:chronex/model/run_session.dart';
import 'package:chronex/model/run_state.dart';
import 'package:chronex/model/sensor_data.dart';
import 'package:chronex/presentation/provider/bluetooth_provider.dart';
import 'package:chronex/presentation/provider/home_stats_provider.dart';
import 'package:chronex/presentation/provider/recent_runs_provider.dart';
import 'package:chronex/storage/pace_split_manager.dart';
import 'package:chronex/storage/profile_manager.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

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
      steps: 0,
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
        steps: session.totalSteps,
      );
    });

    _heartRateSub = heartRateStream.listen((bytes) {
      if (bytes.length < 2) return;
      final hr = HeartRateData.fromBytes(bytes);
      _session?.updateHeartRate(hr);
      state = state.copyWith(heartrate: hr.bpm);
    });
  }

  Future<void> startRun(BluetoothNotifier ble) async {
    final bleState = ref.read(bluetoothProvider).valueOrNull;
    if (bleState?.connectionState != BluetoothConnectionState.connected) {
      throw Exception('Cannot start run: no BLE device connected');
    }

    await ble.writeTo(BleUuids.control, [0x01]);
    state = state.copyWith(isRunning: true, isPaused: false);

    final profile = await ProfileManager().getProfile();
    if (profile != null) userWeight = profile.weight ?? 70;

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
    ref
        .read(bluetoothProvider.notifier)
        .writeTo(BleUuids.control, [0x00])
        .catchError((_) {});
  }

  void resumeRun(BluetoothNotifier ble) {
    ble.writeTo(BleUuids.control, [0x01]);
    state = state.copyWith(isRunning: true, isPaused: false);
    if (_session == null) return;
    _session?.resume();
    final motionStream = ble.subscribeTo(BleUuids.motion).map((c) => c.value);
    final heartRateStream = ble
        .subscribeTo(BleUuids.heartRate)
        .map((c) => c.value);
    _startStreams(motionStream: motionStream, heartRateStream: heartRateStream);
  }

  Future<Run> stopRun() async {
    _motionSub?.cancel();
    _heartRateSub?.cancel();
    _timer?.cancel();

    try {
      await ref.read(bluetoothProvider.notifier).writeTo(BleUuids.control, [
        0x00,
      ]);
    } catch (_) {}

    final session = _session;
    if (session == null) {
      state = state.copyWith(isPaused: false, isRunning: false);
      throw Exception('No active run session');
    }

    final elapsedSec = session.elapsed.inSeconds;
    final dist = session.distanceKm;
    final avgPaceSec = dist > 0 ? (elapsedSec / dist).round() : 0;

    final run = Run(
      timeSec: elapsedSec,
      distance: dist,
      avgSecondsPerKm: avgPaceSec,
      avgCadence: session.avgCadence.round(),
      calories: _calculateCalories(session),
      heartRate: session.heartRate > 0 ? session.heartRate : null,
      completedAt: DateTime.now(),
    );

    final box = Hive.box('runBox');
    await box.add(run); // run.key is populated after this

    // Save pace splits + percentile as a separate record, linked via run.key.
    await _savePaceSplitData(run, session, avgPaceSec);

    ref.read(homePageStatsProvider.notifier).loadStats();
    ref.read(recentRunsProvider.notifier).getRecentRuns();

    _session = null;
    state = state.copyWith(isPaused: false, isRunning: false);

    return run;
  }

  Future<void> _savePaceSplitData(
    Run run,
    RunSession session,
    int avgPaceSec,
  ) async {
    final box = Hive.box('runBox');
    final allRuns = box.values.whereType<Run>();
    final pastPaces = allRuns
        .map((r) => r.avgSecondsPerKm ?? 0)
        .where((p) => p > 0)
        .toList();

    int percentile = 50;
    if (pastPaces.isNotEmpty && avgPaceSec > 0) {
      // Lower seconds/km = faster. Percentile = % of runs this one beat.
      final slowerCount = pastPaces.where((p) => p > avgPaceSec).length;
      percentile = ((slowerCount / pastPaces.length) * 100).round();
    }

    await PaceSplitManager().savePaceSplit(
      PaceSplitData(
        runKey: run.key,
        splits: session.paceSplits,
        percentile: percentile,
      ),
    );
  }

  void resetRun() {
    _motionSub?.cancel();
    _heartRateSub?.cancel();
    _timer?.cancel();
    _session = null;
    state = state.copyWith(
      time: const Duration(hours: 0, minutes: 0, seconds: 0),
      distance: 0,
      pace: Pace(secondsPerKilometer: 0),
      cadence: 0,
      calories: 0,
      heartrate: 0,
      steps: 0,
      isRunning: false,
      isPaused: false,
    );
  }
}

final runStateProvider = NotifierProvider<RunStateNotifier, RunState>(() {
  return RunStateNotifier();
});
