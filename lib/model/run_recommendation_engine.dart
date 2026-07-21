/// Rule-based post-run recommendations, evaluated against fixed sports
/// science thresholds. Pure logic, no I/O — callers fetch whatever data
/// they need (Run fields, UserProfile.age) and pass it in.
class RunRecommendation {
  final String category; // 'cadence' | 'heartRate' | 'pace'
  final String message;

  const RunRecommendation({required this.category, required this.message});
}

class RunRecommendationEngine {
  // Cadence thresholds (SPM) — optimal range 170-180 [11]
  static const int _cadenceLow = 160;
  static const int _cadenceHigh = 190;

  // Heart rate thresholds, as a fraction of estimated max HR (220 - age)
  static const double _hrHighIntensity = 0.85;
  static const double _hrLowIntensity = 0.55;

  // Pace thresholds, in seconds/km
  static const int _paceFast = 240; // under 4:00/km
  static const int _paceSlow = 480; // over 8:00/km

  static List<RunRecommendation> evaluate({
    required int? avgCadence,
    required int? avgHeartRate,
    required int? avgSecondsPerKm,
    required int? age,
  }) {
    final recommendations = <RunRecommendation>[];

    final cadenceRec = _evaluateCadence(avgCadence);
    if (cadenceRec != null) recommendations.add(cadenceRec);

    final heartRateRec = _evaluateHeartRate(avgHeartRate, age);
    if (heartRateRec != null) recommendations.add(heartRateRec);

    final paceRec = _evaluatePace(avgSecondsPerKm);
    if (paceRec != null) recommendations.add(paceRec);

    return recommendations;
  }

  static RunRecommendation? _evaluateCadence(int? avgCadence) {
    if (avgCadence == null) return null;

    if (avgCadence < _cadenceLow) {
      return RunRecommendation(
        category: 'cadence',
        message:
            'Your cadence was $avgCadence SPM — try increasing your stride '
            'turnover toward the optimal 170-180 SPM range for more efficient running.',
      );
    }
    if (avgCadence > _cadenceHigh) {
      return RunRecommendation(
        category: 'cadence',
        message:
            'Your cadence was $avgCadence SPM, above the typical range — '
            'consider moderating your effort a little.',
      );
    }
    return null;
  }

  static RunRecommendation? _evaluateHeartRate(int? avgHeartRate, int? age) {
    if (avgHeartRate == null || age == null) return null;

    final maxHr = 220 - age;
    if (maxHr <= 0) return null;

    final pctOfMax = avgHeartRate / maxHr;

    if (pctOfMax > _hrHighIntensity) {
      return RunRecommendation(
        category: 'heartRate',
        message:
            'This was a high-intensity effort (${(pctOfMax * 100).round()}% of your '
            'estimated max heart rate) — consider taking a recovery day.',
      );
    }
    if (pctOfMax < _hrLowIntensity) {
      return RunRecommendation(
        category: 'heartRate',
        message:
            'Your heart rate stayed fairly low (${(pctOfMax * 100).round()}% of your '
            'estimated max heart rate) — you have room to push the intensity a bit more.',
      );
    }
    return null;
  }

  static RunRecommendation? _evaluatePace(int? avgSecondsPerKm) {
    if (avgSecondsPerKm == null || avgSecondsPerKm <= 0) return null;

    if (avgSecondsPerKm < _paceFast) {
      return const RunRecommendation(
        category: 'pace',
        message:
            'Excellent pace — sub-4:00/km puts you well into strong-runner territory. Great work!',
      );
    }
    if (avgSecondsPerKm > _paceSlow) {
      return const RunRecommendation(
        category: 'pace',
        message:
            "Keep at it — gradual pace improvement comes with consistency, "
            "and you're building the base for it.",
      );
    }
    return null;
  }
}
