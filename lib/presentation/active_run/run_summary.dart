import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:chronex/base/extensions/sizedbox_extension.dart';
import 'package:chronex/base/theme/app_color.dart';
import 'package:chronex/base/theme/s_text_theme.dart';
import 'package:chronex/model/pace.dart';
import 'package:chronex/model/pace_split_data.dart';
import 'package:chronex/model/run.dart';
import 'package:chronex/model/run_recommendation_engine.dart';
import 'package:chronex/navigation/app_router_path.dart';
import 'package:chronex/presentation/widgets/app_button.dart';
import 'package:chronex/presentation/widgets/run_track_stats.dart';
import 'package:chronex/storage/pace_split_manager.dart';
import 'package:chronex/storage/profile_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Pace splits and percentile now live in their own [PaceSplitData] record
/// (own Hive box, linked by [Run.key]) rather than on [Run] itself — see
/// pace_split_data.dart / pace_split_manager.dart. This screen loads that
/// record asynchronously and degrades gracefully (shows a "not enough data"
/// placeholder in the chart cards) if it isn't found — e.g. for runs saved
/// before this feature existed.
///
/// The Insight card shows rule-based recommendations (see
/// run_recommendation_engine.dart) evaluated against cadence, heart rate,
/// and pace thresholds. Heart-rate zones need the runner's age (for
/// estimated max HR = 220 - age), so this also loads [UserProfile] via
/// [ProfileManager].
class RunSummary extends StatelessWidget {
  final Run run;

  const RunSummary({super.key, required this.run});

  Future<_SummaryData> _loadSummaryData() async {
    final splitData = await PaceSplitManager().getForRun(run.key);
    final profile = await ProfileManager().getProfile();
    return _SummaryData(splitData: splitData, age: profile?.age);
  }

  @override
  Widget build(BuildContext context) {
    final pace = Pace(secondsPerKilometer: run.avgSecondsPerKm ?? 0);
    final dateStr = DateFormat(
      'MMM dd, yyyy – HH:mm',
    ).format(run.completedAt ?? DateTime.now());
    final durationStr =
        '${run.runTime.inHours.toString().padLeft(2, '0')}:'
        '${run.runTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
        '${run.runTime.inSeconds.remainder(60).toString().padLeft(2, '0')}';

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(color: AppColor.primary),
        child: SafeArea(
          child: Column(
            children: [
              // The run is already finished by the time this screen is shown
              // (pushed from stopRun()), so "back" has nowhere useful to go —
              // send the user Home instead of popping to the stopped tracker.
              _Header(
                dateStr: dateStr,
                onBack: () => context.go(AppRouterPath.home),
              ),
              Expanded(
                child: FutureBuilder<_SummaryData>(
                  future: _loadSummaryData(),
                  builder: (context, snapshot) {
                    final isLoading =
                        snapshot.connectionState == ConnectionState.waiting;
                    final splitData = snapshot.data?.splitData;
                    final splits = splitData?.splits ?? const <double>[];
                    final percentile = splitData?.percentile ?? 50;

                    final recommendations = RunRecommendationEngine.evaluate(
                      avgCadence: run.avgCadence,
                      avgHeartRate: run.heartRate,
                      avgSecondsPerKm: run.avgSecondsPerKm,
                      age: snapshot.data?.age,
                    );

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          16.sBHh,
                          _HeroCard(
                            durationStr: durationStr,
                            distance: run.distance,
                          ),
                          16.sBHh,
                          _StatRow(
                            pace: pace,
                            cadence: run.avgCadence,
                            heartRate: run.heartRate,
                            calories: run.calories,
                          ),
                          20.sBHh,
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColor.green,
                                ),
                              ),
                            )
                          else ...[
                            _PaceDropCard(splits: splits),
                            16.sBHh,
                            _InsightCard(recommendations: recommendations),
                            16.sBHh,
                            _PercentileCard(percentile: percentile),
                          ],
                          24.sBHh,
                          AppButton(
                            onPressed: () => context.go(AppRouterPath.home),
                            title: 'Back to Home',
                            leadingIcon: const Icon(
                              Icons.home,
                              color: AppColor.primary,
                              size: 22.0,
                            ),
                            color: Colors.grey.shade100,
                            titleColor: AppColor.primary,
                            width: double.infinity,
                            height: 60.h,
                          ),
                          24.sBHh,
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryData {
  final PaceSplitData? splitData;
  final int? age;

  const _SummaryData({required this.splitData, required this.age});
}

class _Header extends StatelessWidget {
  final String dateStr;
  final VoidCallback onBack;

  const _Header({required this.dateStr, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: AppColor.white),
          ),
          12.sBWw,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Run Summary',
                  style: STextTheme.text26.copyWith(color: AppColor.white),
                ),
                4.sBHh,
                Text(
                  "Great effort! Here's how you did.",
                  style: STextTheme.text16.copyWith(color: AppColor.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String durationStr;
  final double? distance;

  const _HeroCard({required this.durationStr, required this.distance});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Row(
        children: [
          Expanded(
            child: _HeroStat(
              icon: Icons.timer,
              label: 'Total Time',
              value: durationStr,
              unit: '',
            ),
          ),
          Container(width: 1, height: 56.h, color: Colors.white24),
          Expanded(
            child: _HeroStat(
              icon: Icons.location_on,
              label: 'Total Distance',
              value: distance?.toStringAsFixed(2) ?? '0.00',
              unit: 'km',
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColor.green, size: 16.sp),
            6.sBWw,
            Text(
              label,
              style: STextTheme.text14.copyWith(color: AppColor.green),
            ),
          ],
        ),
        8.sBHh,
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: STextTheme.text30.copyWith(
                  color: AppColor.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const TextSpan(text: ' '),
                TextSpan(
                  text: unit,
                  style: STextTheme.text16.copyWith(color: AppColor.green),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final Pace pace;
  final int? cadence;
  final int? heartRate;
  final int? calories;

  const _StatRow({
    required this.pace,
    required this.cadence,
    required this.heartRate,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: RunTrackStats(
                icon: Icons.flash_on,
                title: 'Avg Pace',
                value: pace.toString(),
                unit: 'min/km',
              ),
            ),
            10.sBWw,
            Expanded(
              child: RunTrackStats(
                icon: Icons.directions_run,
                title: 'Avg Cadence',
                value: cadence?.toString() ?? '0',
                unit: 'spm',
              ),
            ),
          ],
        ),
        10.sBHh,
        Row(
          children: [
            Expanded(
              child: RunTrackStats(
                icon: Icons.favorite,
                title: 'Avg Heart Rate',
                value: heartRate != null ? heartRate.toString() : 'Not enough data',
                unit: heartRate != null ? 'bpm' : '',
              ),
            ),
            10.sBWw,
            Expanded(
              child: RunTrackStats(
                icon: Icons.local_fire_department,
                title: 'Calories',
                value: calories?.toString() ?? '0',
                unit: 'kcal',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaceDropCard extends StatelessWidget {
  final List<double> splits;

  const _PaceDropCard({required this.splits});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColor.white, size: 18),
              8.sBWw,
              Text(
                'Pace Drop Per km',
                style: STextTheme.text16.copyWith(
                  color: AppColor.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          16.sBHh,
          SizedBox(
            height: 180.h,
            child: splits.length < 2
                ? Center(
                    child: Text(
                      'Not enough split data yet',
                      style: STextTheme.text14.copyWith(color: Colors.white54),
                    ),
                  )
                : CustomPaint(
                    size: Size.infinite,
                    painter: _PaceLineChartPainter(splits: splits),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Draws pace (seconds/km) per split as a line chart. Y axis is inverted
/// visually (slower pace = further down), matching typical "pace drop" UX.
class _PaceLineChartPainter extends CustomPainter {
  final List<double> splits;

  _PaceLineChartPainter({required this.splits});

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 44.0;
    const bottomPad = 24.0;
    const topPad = 8.0;
    const rightPad = 8.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    final minPace = splits.reduce(math.min);
    final maxPace = splits.reduce(math.max);
    final range = (maxPace - minPace).abs() < 1 ? 1.0 : (maxPace - minPace);
    final padding = range * 0.25;
    final axisMin = minPace - padding;
    final axisMax = maxPace + padding;

    final gridPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    final axisTextStyle = TextStyle(color: Colors.white70, fontSize: 11.sp);

    // Horizontal gridlines + pace labels (4 rows)
    const rows = 4;
    for (var i = 0; i <= rows; i++) {
      final y = topPad + chartHeight * (i / rows);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        gridPaint,
      );

      final paceVal = axisMin + (axisMax - axisMin) * (1 - i / rows);
      final label = _formatPace(paceVal);
      final tp = TextPainter(
        text: TextSpan(text: label, style: axisTextStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // X axis labels (every ~2 km)
    for (var i = 0; i < splits.length; i++) {
      final km = i + 1;
      if (km % 2 != 0 && km != splits.length) continue;
      final x = leftPad + chartWidth * (i / (splits.length - 1));
      final tp = TextPainter(
        text: TextSpan(text: '$km', style: axisTextStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - bottomPad + 4));
    }

    // Line + dots
    final linePaint = Paint()
      ..color = AppColor.green
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < splits.length; i++) {
      final x = leftPad + chartWidth * (i / (splits.length - 1));
      final normalized = (splits[i] - axisMin) / (axisMax - axisMin);
      final y = topPad + chartHeight * (1 - normalized);
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = AppColor.green;
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
    }
  }

  String _formatPace(double secondsPerKm) {
    final s = secondsPerKm.round();
    final m = s ~/ 60;
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  bool shouldRepaint(covariant _PaceLineChartPainter oldDelegate) =>
      oldDelegate.splits != splits;
}

class _InsightCard extends StatelessWidget {
  final List<RunRecommendation> recommendations;

  const _InsightCard({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColor.primary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColor.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColor.green),
            ),
            child: Icon(Icons.lightbulb, color: AppColor.green, size: 18.sp),
          ),
          12.sBWw,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insight',
                  style: STextTheme.text16.copyWith(
                    color: AppColor.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                6.sBHh,
                if (recommendations.isEmpty)
                  Text(
                    'Solid, balanced effort across pace, cadence, and heart rate — keep it up!',
                    style: STextTheme.text14.copyWith(color: AppColor.white),
                  )
                else
                  for (var i = 0; i < recommendations.length; i++) ...[
                    if (i > 0) 8.sBHh,
                    Text(
                      recommendations[i].message,
                      style: STextTheme.text14.copyWith(color: AppColor.white),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentileCard extends StatelessWidget {
  final int percentile;

  const _PercentileCard({required this.percentile});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_none,
                color: AppColor.white,
                size: 18,
              ),
              8.sBWw,
              Text(
                'Pace Percentile',
                style: STextTheme.text16.copyWith(
                  color: AppColor.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          4.sBHh,
          Text(
            'Compared to all your runs',
            style: STextTheme.text14.copyWith(color: AppColor.green),
          ),
          16.sBHh,
          SizedBox(
            height: 150.h,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BellCurvePainter(percentile: percentile),
            ),
          ),
        ],
      ),
    );
  }
}

class _BellCurvePainter extends CustomPainter {
  final int percentile;

  _BellCurvePainter({required this.percentile});

  double _gauss(double x) => math.exp(-math.pow(x - 0.5, 2) / (2 * 0.028));

  @override
  void paint(Canvas canvas, Size size) {
    const bottomPad = 40.0;
    final chartHeight = size.height - bottomPad;
    const steps = 100;

    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = t * size.width;
      final y = chartHeight - _gauss(t) * chartHeight * 0.95;
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Shaded region up to percentile (darker) then rest (lighter)
    final pct = (percentile.clamp(0, 100)) / 100;
    final fillDark = Paint()..color = AppColor.green.withValues(alpha: 0.18);
    final fillLight = Paint()..color = AppColor.green.withValues(alpha: 0.35);

    final splitIndex = (pct * steps).round().clamp(0, steps);
    final darkFill = Path()..moveTo(0, chartHeight);
    for (var i = 0; i <= splitIndex; i++) {
      darkFill.lineTo(points[i].dx, points[i].dy);
    }
    darkFill.lineTo(points[splitIndex].dx, chartHeight);
    darkFill.close();
    canvas.drawPath(darkFill, fillDark);

    final lightFill = Path()..moveTo(points[splitIndex].dx, chartHeight);
    for (var i = splitIndex; i <= steps; i++) {
      lightFill.lineTo(points[i].dx, points[i].dy);
    }
    lightFill.lineTo(size.width, chartHeight);
    lightFill.close();
    canvas.drawPath(lightFill, fillLight);

    final curvePaint = Paint()
      ..color = AppColor.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, curvePaint);

    // Marker line at percentile
    final markerX = pct * size.width;
    final markerPaint = Paint()
      ..color = AppColor.white
      ..strokeWidth = 1.5;
    _drawDashedLine(
      canvas,
      Offset(markerX, 0),
      Offset(markerX, chartHeight),
      markerPaint,
    );

    // Label bubble
    final labelText = _ordinal(percentile);
    final tp = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: AppColor.primary,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final bubbleRect = Rect.fromCenter(
      center: Offset(markerX, -8),
      width: tp.width + 20,
      height: 22,
    ).shift(const Offset(0, 8));
    final bubblePaint = Paint()..color = AppColor.green;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bubbleRect, const Radius.circular(6)),
      bubblePaint,
    );
    tp.paint(
      canvas,
      Offset(
        bubbleRect.center.dx - tp.width / 2,
        bubbleRect.center.dy - tp.height / 2,
      ),
    );

    // Bottom axis labels
    const labels = ['10%', '25%', '50%', '75%', '90%'];
    const positions = [0.1, 0.25, 0.5, 0.75, 0.9];
    final axisStyle = TextStyle(color: Colors.white70, fontSize: 11.sp);
    for (var i = 0; i < labels.length; i++) {
      final tp2 = TextPainter(
        text: TextSpan(text: labels[i], style: axisStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp2.paint(
        canvas,
        Offset(positions[i] * size.width - tp2.width / 2, chartHeight + 4),
      );
    }

    final slowStyle = TextStyle(color: Colors.white54, fontSize: 11.sp);
    final slowTp = TextPainter(
      text: TextSpan(text: 'Slower', style: slowStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    slowTp.paint(canvas, Offset(0, chartHeight + 20));
    final fastTp = TextPainter(
      text: TextSpan(text: 'Faster', style: slowStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    fastTp.paint(canvas, Offset(size.width - fastTp.width, chartHeight + 20));
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 4.0;
    const gapLength = 4.0;
    final total = (end - start).distance;
    final direction = (end - start) / total;
    var distance = 0.0;
    while (distance < total) {
      final segStart = start + direction * distance;
      final segEnd = start + direction * math.min(distance + dashLength, total);
      canvas.drawLine(segStart, segEnd, paint);
      distance += dashLength + gapLength;
    }
  }

  String _ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  @override
  bool shouldRepaint(covariant _BellCurvePainter oldDelegate) =>
      oldDelegate.percentile != percentile;
}

class _CardShell extends StatelessWidget {
  final Widget child;

  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: child,
    );
  }
}
