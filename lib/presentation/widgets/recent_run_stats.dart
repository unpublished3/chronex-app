import 'package:flutter/material.dart';
import 'package:chronex/base/extensions/sizedbox_extension.dart';
import 'package:chronex/base/theme/s_text_theme.dart';
import 'package:chronex/base/theme/app_color.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecentRunStats extends StatefulWidget {
  final String monthname;
  final int day;
  final int year;
  final double recentdistance;
  final String recenttime;
  final String recentpace;
  final int? recentheartbeat;
  const RecentRunStats({
    super.key,
    required this.monthname,
    required this.day,
    required this.year,
    required this.recentdistance,
    required this.recenttime,
    required this.recentpace,
    required this.recentheartbeat,
  });

  @override
  State<RecentRunStats> createState() => _RecentRunStatsState();
}

class _RecentRunStatsState extends State<RecentRunStats> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 365.w,
      height: 120.h,
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColor.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.monthname} ${widget.day.toString()}, ${widget.year.toString()}',
                  style: STextTheme.text24,
                ),
                Text(
                  '${widget.recentdistance.toStringAsFixed(2)} km',
                  style: STextTheme.text24.copyWith(color: AppColor.primary),
                ),
              ],
            ),
          ),
          20.sBHh,
          DefaultTextStyle(
            style: STextTheme.text20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(widget.recenttime),
                const Text('.'),
                Text(widget.recentpace),
                const Text('.'),
                Text(widget.recentheartbeat != null ? '${widget.recentheartbeat} bpm' : '--- bpm'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
