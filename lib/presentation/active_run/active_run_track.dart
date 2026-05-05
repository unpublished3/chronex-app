import 'package:chronex/presentation/provider/bluetooth_provider.dart';
import 'package:flutter/material.dart';
import 'package:chronex/base/extensions/sizedbox_extension.dart';
import 'package:chronex/presentation/provider/active_run_track_provider.dart';
import 'package:chronex/base/theme/app_color.dart';
import 'package:chronex/base/theme/s_text_theme.dart';
import 'package:chronex/presentation/widgets/run_track_stats.dart';
import 'package:chronex/presentation/widgets/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ActiveRunTrack extends ConsumerStatefulWidget {
  const ActiveRunTrack({super.key});

  @override
  ConsumerState<ActiveRunTrack> createState() => _ActiveRunTrackState();
}

class _ActiveRunTrackState extends ConsumerState<ActiveRunTrack> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ble = ref.read(bluetoothProvider.notifier);
      ref.read(runStateProvider.notifier).startRun(ble);
    });
  }

  @override
  Widget build(BuildContext context) {
    final run = ref.watch(runStateProvider);
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(color: AppColor.primary),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 30.0, 0.0, 0.0),
                child: Text(
                  'Run in progress',
                  style: STextTheme.text26.copyWith(color: AppColor.white),
                ),
              ),
            ),
            30.sBHh,
            Text(
              '${run.time.inHours.toString().padLeft(2, '0')}:${run.time.inMinutes.remainder(60).toString().padLeft(2, '0')}:${run.time.inSeconds.remainder(60).toString().padLeft(2, '0')}',
              style: STextTheme.text60.copyWith(color: AppColor.white),
            ),
            Text(
              'duration',
              style: STextTheme.text24.copyWith(color: AppColor.green),
            ),
            40.sBHh,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RunTrackStats(
                  icon: Icons.location_on,
                  title: 'Distance',
                  value: run.distance.toStringAsFixed(2),
                  unit: 'km',
                ),
                RunTrackStats(
                  icon: Icons.flash_on,
                  title: 'Pace',
                  value: run.pace.toString(),
                  unit: 'min/km',
                ),
              ],
            ),
            20.sBHh,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RunTrackStats(
                  icon: Icons.directions_run,
                  title: 'Cadence',
                  value: run.cadence.toString(),
                  unit: 'spm',
                ),
                RunTrackStats(
                  icon: Icons.local_fire_department,
                  title: 'Calories',
                  value: run.calories.toString(),
                  unit: 'kcal',
                ),
              ],
            ),
            20.sBHh,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RunTrackStats(
                  icon: Icons.favorite,
                  title: 'Heart rate',
                  value: run.heartrate.toString(),
                  unit: 'bpm',
                ),
                RunTrackStats(
                  icon: Icons.thermostat,
                  title: 'Temperature',
                  value: run.temp.toString(),
                  unit: '°C',
                ),
              ],
            ),
            50.sBHh,
            if (run.isRunning)
              AppButton(
                onPressed: () {
                  ref.read(runStateProvider.notifier).pauseRun();
                },
                title: 'Pause Run',
                leadingIcon: const Icon(
                  Icons.pause,
                  color: AppColor.primary,
                  size: 25.0,
                ),
                color: Colors.grey.shade100,
                titleColor: AppColor.primary,
                width: 360.w,
                height: 75.h,
                fontSize: 20.0,
              ),
            if (run.isPaused)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AppButton(
                    onPressed: () {
                      final ble = ref.read(bluetoothProvider.notifier);
                      ref.read(runStateProvider.notifier).resumeRun(ble);
                    },
                    title: 'Resume Run',
                    leadingIcon: const Icon(
                      Icons.play_arrow,
                      color: AppColor.primary,
                      size: 25.0,
                    ),
                    color: Colors.grey.shade100,
                    titleColor: AppColor.primary,
                    width: 175.w,
                    height: 75.h,
                    fontSize: 20.0,
                  ),
                  AppButton(
                    onPressed: () {
                      // Navigate to summary page and add the saved run to hive(also call the loadStats() function to keep provider updated).
                      ref.read(runStateProvider.notifier).stopRun();
                    },
                    title: 'Finish Run',
                    leadingIcon: const Icon(
                      Icons.stop,
                      color: AppColor.primary,
                      size: 25.0,
                    ),
                    color: Colors.grey.shade100,
                    titleColor: AppColor.primary,
                    width: 175.w,
                    height: 75.h,
                    fontSize: 20.0,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
