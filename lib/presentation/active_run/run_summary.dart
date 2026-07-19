import 'package:chronex/base/extensions/sizedbox_extension.dart';
import 'package:chronex/base/theme/app_color.dart';
import 'package:chronex/base/theme/s_text_theme.dart';
import 'package:chronex/model/pace.dart';
import 'package:chronex/model/run.dart';
import 'package:chronex/navigation/app_router_path.dart';
import 'package:chronex/presentation/widgets/app_button.dart';
import 'package:chronex/presentation/widgets/run_track_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RunSummary extends StatelessWidget {
  final Run run;
  const RunSummary({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    final pace = Pace(secondsPerKilometer: run.avgSecondsPerKm ?? 0);
    final dateStr = DateFormat('MMM dd, yyyy – HH:mm').format(run.completedAt ?? DateTime.now());

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(color: AppColor.primary),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),
              const Icon(Icons.check_circle, color: AppColor.green, size: 72),
              16.sBHh,
              Text('Run Complete!', style: STextTheme.text26.copyWith(color: AppColor.white)),
              8.sBHh,
              Text(dateStr, style: STextTheme.text16.copyWith(color: Colors.white70)),
              40.sBHh,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RunTrackStats(
                    icon: Icons.location_on,
                    title: 'Distance',
                    value: run.distance?.toStringAsFixed(2) ?? '0.00',
                    unit: 'km',
                  ),
                  RunTrackStats(
                    icon: Icons.flash_on,
                    title: 'Pace',
                    value: pace.toString(),
                    unit: 'min/km',
                  ),
                ],
              ),
              20.sBHh,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RunTrackStats(
                    icon: Icons.timer,
                    title: 'Duration',
                    value: '${run.runTime.inHours.toString().padLeft(2, '0')}:'
                        '${run.runTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
                        '${run.runTime.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                    unit: '',
                  ),
                  RunTrackStats(
                    icon: Icons.directions_run,
                    title: 'Avg Cadence',
                    value: run.avgCadence?.toString() ?? '0',
                    unit: 'spm',
                  ),
                ],
              ),
              20.sBHh,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RunTrackStats(
                    icon: Icons.local_fire_department,
                    title: 'Calories',
                    value: run.calories?.toString() ?? '0',
                    unit: 'kcal',
                  ),
                  RunTrackStats(
                    icon: Icons.favorite,
                    title: 'Heart Rate',
                    value: run.heartRate?.toString() ?? '0',
                    unit: 'bpm',
                  ),
                ],
              ),
              const Spacer(flex: 2),
              AppButton(
                onPressed: () {
                  context.go(AppRouterPath.home);
                },
                title: 'Done',
                color: Colors.grey.shade100,
                titleColor: AppColor.primary,
                width: 200.w,
                height: 60.h,
              ),
              40.sBHh,
            ],
          ),
        ),
      ),
    );
  }
}
