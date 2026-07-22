import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/expense_providers.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/repositories/insights_calculator.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(allExpensesProvider);
    final incomeAsync = ref.watch(allIncomeProvider);
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (expenses) {
          return incomeAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (incomeList) {
              return categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (categories) {
                  final now = DateTime.now();
                  final monthStart = DateTime(now.year, now.month, 1);
                  final lastMonthStart = DateTime(now.year, now.month - 1, 1);
                  final lastMonthEnd = DateTime(now.year, now.month, 0);

                  bool inMonth(DateTime d, DateTime start, DateTime endExclusive) =>
                      !d.isBefore(start) && d.isBefore(endExclusive);

                  final thisMonthExpenses =
                      expenses.where((e) => inMonth(e.date, monthStart, now.add(const Duration(days: 1)))).toList();
                  final lastMonthExpenses = expenses
                      .where((e) => !e.date.isBefore(lastMonthStart) && !e.date.isAfter(lastMonthEnd))
                      .toList();
                  final thisMonthIncome = incomeList
                      .where((i) => inMonth(i.date, monthStart, now.add(const Duration(days: 1))))
                      .toList();

                  final totalExpense = thisMonthExpenses.fold<double>(0, (s, e) => s + e.amount);
                  final totalIncome = thisMonthIncome.fold<double>(0, (s, i) => s + i.amount);
                  final netSavings = totalIncome - totalExpense;

                  final categoryMap = {for (final c in categories) c.id: c.name};
                  final spendByCategory = <String, double>{};
                  for (final e in thisMonthExpenses) {
                    final name = categoryMap[e.categoryId] ?? 'Uncategorized';
                    spendByCategory[name] = (spendByCategory[name] ?? 0) + e.amount;
                  }
                  final lastMonthSpendByCategory = <String, double>{};
                  for (final e in lastMonthExpenses) {
                    final name = categoryMap[e.categoryId] ?? 'Uncategorized';
                    lastMonthSpendByCategory[name] =
                        (lastMonthSpendByCategory[name] ?? 0) + e.amount;
                  }

                  // Build insights
                  final insights = <Insight>[];
                  final savingsInsight =
                      InsightsCalculator.savingsRate(income: totalIncome, expense: totalExpense);
                  if (savingsInsight != null) insights.add(savingsInsight);

                  final highest = InsightsCalculator.highestCategory(spendByCategory);
                  if (highest != null) insights.add(highest);

                  for (final entry in spendByCategory.entries) {
                    final trend = InsightsCalculator.categoryTrend(
                      categoryName: entry.key,
                      thisMonthSpend: entry.value,
                      lastMonthSpend: lastMonthSpendByCategory[entry.key] ?? 0,
                    );
                    if (trend != null) insights.add(trend);
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SummaryCard(
                        label: 'Total Income',
                        amount: totalIncome,
                        color: AppColors.income,
                        borderColor: AppColors.income,
                      ),
                      const SizedBox(height: 12),
                      _SummaryCard(
                        label: 'Total Expense',
                        amount: totalExpense,
                        color: AppColors.error,
                        borderColor: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      _SummaryCard(
                        label: 'Net Savings',
                        amount: netSavings,
                        color: netSavings >= 0 ? AppColors.income : AppColors.error,
                        borderColor: AppColors.secondaryContainer,
                        filled: true,
                      ),
                      const SizedBox(height: 24),

                      if (spendByCategory.isNotEmpty) ...[
                        Text('Spending by Category', style: AppTypography.titleMd),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: _CategoryPieChart(spendByCategory: spendByCategory),
                        ),
                        const SizedBox(height: 8),
                        ...spendByCategory.entries.map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.key, style: AppTypography.bodyMd),
                                  Text(
                                    '${(e.value / (totalExpense == 0 ? 1 : totalExpense) * 100).toStringAsFixed(0)}%',
                                    style: AppTypography.bodyMd,
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 24),
                      ],

                      Text('Smart Insights', style: AppTypography.titleMd),
                      const SizedBox(height: 8),
                      if (insights.isEmpty)
                        Text('Not enough data yet for insights',
                            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant))
                      else
                        ...insights.map((i) => _InsightCard(insight: i)),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final Color borderColor;
  final bool filled;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.borderColor,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: filled ? AppColors.secondaryContainer.withValues(alpha: 0.3) : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTypography.labelMd),
          const SizedBox(height: 4),
          Text(
            '\$${amount.abs().toStringAsFixed(2)}',
            style: AppTypography.headlineLg.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final Map<String, double> spendByCategory;
  const _CategoryPieChart({required this.spendByCategory});

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    Color(0xFF78909C),
    Color(0xFFFFA726),
    Color(0xFF29B6F6),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = spendByCategory.entries.toList();
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: List.generate(entries.length, (i) {
          return PieChartSectionData(
            value: entries[i].value,
            color: _colors[i % _colors.length],
            title: '',
            radius: 24,
          );
        }),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Insight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    Color accent;
    switch (insight.tone) {
      case InsightTone.positive:
        accent = AppColors.income;
      case InsightTone.negative:
        accent = AppColors.error;
      case InsightTone.neutral:
        accent = AppColors.outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Text(insight.text, style: AppTypography.bodyMd),
    );
  }
}
