import 'package:chronex/base/extensions/sizedbox_extension.dart';
import 'package:chronex/base/theme/app_color.dart';
import 'package:chronex/base/theme/s_text_theme.dart';
import 'package:chronex/model/pace.dart';
import 'package:chronex/presentation/widgets/app_button.dart';
import 'package:chronex/presentation/widgets/summary_page_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RunSummary extends ConsumerStatefulWidget {
  const RunSummary({super.key});

  @override
  ConsumerState<RunSummary> createState() => _RunSummaryState();
}

class _RunSummaryState extends ConsumerState<RunSummary> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.sp, 24.sp, 0, 0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Run Summary",
                    style: STextTheme.text36.copyWith(color: AppColor.white),
                  ),
                  Text(
                    "Great effort! Here is how you did",
                    style: STextTheme.text20.copyWith(color: AppColor.green),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 120.h,
            margin: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100.withAlpha(42),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const MainStatsSummaryWidget(
                  icon: Icons.timer,
                  title: "Total Time",
                  value: "1:23:23", // fix here later
                ),
                Container(
                  height: 85.h,
                  width: 2.w,
                  decoration: BoxDecoration(
                    color: AppColor.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const MainStatsSummaryWidget(
                  icon: Icons.location_on,
                  title: "Distance",
                  value: "105",
                  unit: "km",
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SummaryPageStats(
                icon: Icons.flash_on,
                title: 'Avg Pace',
                value: Pace(
                  secondsPerKilometer: 300,
                ).toString(), // dummy data change with provider
                unit: 'min/km',
              ),
              const SummaryPageStats(
                icon: Icons.directions_run,
                title: 'Avg Cadence',
                value: '123', // dummy data chage with provider
                unit: 'spm',
              ),
              const SummaryPageStats(
                icon: Icons.favorite,
                title: 'Avg HR',
                value: '123', // dummy data chage with provider
                unit: 'bpm',
              ),
            ],
          ),
          AppButton(
            onPressed: () {
              // Route to Home page
            },
            title: 'Back to Home',
            titleColor: AppColor.primary,
            leadingIcon: const Icon(
              Icons.home,
              color: AppColor.primary,
              size: 25.0,
            ),
            color: Colors.grey.shade100,
            width: 360.w,
            height: 75.h,
            fontSize: 20.0,
          ),
        ],
      ),
    );
  }
}

class MainStatsSummaryWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? unit;

  const MainStatsSummaryWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.unit,
  });

  @override
  State<MainStatsSummaryWidget> createState() => _MainStatsSummaryWidgetState();
}

class _MainStatsSummaryWidgetState extends State<MainStatsSummaryWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.0.sp),
      child: Column(
        children: [
          5.sBHh,
          Row(
            children: [
              Icon(widget.icon, color: AppColor.white),
              3.sBWw,
              Text(
                widget.title,
                style: STextTheme.text24.copyWith(color: AppColor.green),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.value,
                style: STextTheme.text36.copyWith(color: AppColor.white),
              ),
              if (widget.unit != null) ...[
                12.sBWw,
                Text(
                  widget.unit!,
                  style: STextTheme.text24.copyWith(color: AppColor.green),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
