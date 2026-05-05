import 'package:chronex/presentation/provider/home_stats_provider.dart';
import 'package:chronex/presentation/provider/recent_runs_provider.dart';
import 'package:flutter/material.dart';
import 'package:chronex/base/extensions/sizedbox_extension.dart';
import 'package:chronex/base/theme/s_text_theme.dart';
import 'package:chronex/presentation/widgets/recent_run_stats.dart';
import 'package:chronex/base/theme/app_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  @override
  void initState() {
    super.initState();
    ref.read(recentRunsProvider.notifier).getAllRuns();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(homePageStatsProvider);
    final runs = ref.watch(recentRunsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.sBHh,
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFF9BF7AC)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_run, color: AppColor.primary, size: 24.sp),
                  8.sBWw,
                  Text('Total Runs: ${stats.totalRuns.toString()}', style: STextTheme.text20.copyWith(color: AppColor.primary)),
                ],
              ),
              12.sBHh,
              Text('Keep up the great work! Every run counts.', style: STextTheme.text16.copyWith(color: AppColor.primary)),
            ],
          ),
        ),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: runs.length,
          itemBuilder: (context, index) {
            final run = runs[index];
            final date = run.completionDate;
            final monthName = DateFormat.MMMM().tryParse(date.toString());
            return RecentRunStats(
              monthname: monthName?.toString() ?? '',
              day: run.completionDate?.day ?? 0,
              year: run.completionDate?.year ?? 0,
              recentdistance: run.distance ?? 0,
              recenttime:
                  '${run.duration?.inHours.toString().padLeft(2, '0') ?? '00'}:${run.duration?.inMinutes.remainder(60).toString().padLeft(2, '0') ?? '00'}',
              recentpace: run.pace?.toString() ?? '0',
              recentheartbeat: run.heartRate ?? 0,
            );
          },
        ),
      ],
    );
  }
}
