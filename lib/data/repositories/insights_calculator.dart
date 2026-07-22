/// Rule-based financial insights — pure calculations, no AI/LLM calls.
/// Mirrors the pattern in split_calculator.dart: no DB dependency, easy to
/// unit test. Repositories/providers feed this plain data; it returns
/// plain Insight objects for the UI to render.
class Insight {
  final String text;
  final InsightTone tone;
  const Insight(this.text, this.tone);
}

enum InsightTone { positive, negative, neutral }

class InsightsCalculator {
  /// Compares total spend in a category between two periods.
  /// Returns null if there's nothing meaningful to say (e.g. no spend in
  /// either period).
  static Insight? categoryTrend({
    required String categoryName,
    required double thisMonthSpend,
    required double lastMonthSpend,
  }) {
    if (lastMonthSpend <= 0) return null;
    final change = ((thisMonthSpend - lastMonthSpend) / lastMonthSpend) * 100;
    if (change.abs() < 5) return null; // not meaningful enough to surface

    final direction = change > 0 ? 'more' : 'less';
    return Insight(
      'You spent ${change.abs().toStringAsFixed(0)}% $direction on $categoryName than last month',
      change > 0 ? InsightTone.negative : InsightTone.positive,
    );
  }

  /// Identifies the highest-spending category this period.
  static Insight? highestCategory(Map<String, double> spendByCategory) {
    if (spendByCategory.isEmpty) return null;
    final sorted = spendByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    if (top.value <= 0) return null;
    return Insight(
      '${top.key} is your highest spending category — reached \$${top.value.toStringAsFixed(2)}',
      InsightTone.neutral,
    );
  }

  /// Projects whether a budget will be exceeded at the current daily pace.
  static Insight? budgetPace({
    required String categoryName,
    required double spentSoFar,
    required double limit,
    required int daysElapsedInMonth,
    required int totalDaysInMonth,
  }) {
    if (daysElapsedInMonth <= 0 || limit <= 0) return null;
    final dailyRate = spentSoFar / daysElapsedInMonth;
    final projectedTotal = dailyRate * totalDaysInMonth;

    if (projectedTotal <= limit) return null; // on track, nothing to warn about

    final daysUntilLimitHit =
        dailyRate > 0 ? ((limit - spentSoFar) / dailyRate).floor() : 0;
    final overrunDay = daysElapsedInMonth + daysUntilLimitHit;

    return Insight(
      'At this rate, you\'ll exceed your $categoryName budget by day $overrunDay',
      InsightTone.negative,
    );
  }

  /// Simple savings rate: (income - expense) / income, as a percentage.
  static Insight? savingsRate({required double income, required double expense}) {
    if (income <= 0) return null;
    final rate = ((income - expense) / income) * 100;
    final tone = rate >= 20
        ? InsightTone.positive
        : rate >= 0
            ? InsightTone.neutral
            : InsightTone.negative;
    return Insight(
      'You saved ${rate.toStringAsFixed(0)}% of your income this month',
      tone,
    );
  }
}
