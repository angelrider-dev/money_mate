/// Pure logic for dividing an expense among members.
/// Kept separate from DB code so it's trivially unit-testable.
class SplitCalculator {
  /// Equal split — handles paisa/cent rounding so shares always sum to [total].
  static Map<int, double> splitEqually({
    required double total,
    required List<int> memberIds,
  }) {
    if (memberIds.isEmpty) return {};
    final base = (total / memberIds.length * 100).floor() / 100;
    final result = <int, double>{};
    double allocated = 0;
    for (final id in memberIds) {
      result[id] = base;
      allocated += base;
    }
    // dump remaining paisa onto the last member so totals always match
    final remainder = double.parse((total - allocated).toStringAsFixed(2));
    if (remainder != 0) {
      result[memberIds.last] = result[memberIds.last]! + remainder;
    }
    return result;
  }

  /// Exact split — caller supplies exact amounts; validates they sum to total.
  static Map<int, double> splitExact({
    required double total,
    required Map<int, double> exactShares,
  }) {
    final sum = exactShares.values.fold<double>(0, (a, b) => a + b);
    if ((sum - total).abs() > 0.01) {
      throw ArgumentError(
          'Exact shares ($sum) do not add up to total ($total)');
    }
    return exactShares;
  }

  /// Percentage split — caller supplies % per member (should sum to 100).
  static Map<int, double> splitByPercentage({
    required double total,
    required Map<int, double> percentages,
  }) {
    final sumPct = percentages.values.fold<double>(0, (a, b) => a + b);
    if ((sumPct - 100).abs() > 0.5) {
      throw ArgumentError('Percentages sum to $sumPct, expected ~100');
    }
    return percentages.map((id, pct) => MapEntry(id, total * pct / 100));
  }

  /// Simplifies a group's debts into minimal transactions
  /// balances: memberId -> net amount (+ve = owed money, -ve = owes money)
  static List<SettlementSuggestion> simplifyDebts(Map<int, double> balances) {
    final creditors = balances.entries.where((e) => e.value > 0.01).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final debtors = balances.entries.where((e) => e.value < -0.01).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final result = <SettlementSuggestion>[];
    int i = 0, j = 0;
    final creditorsMut = creditors.map((e) => MapEntry(e.key, e.value)).toList();
    final debtorsMut = debtors.map((e) => MapEntry(e.key, e.value)).toList();

    while (i < debtorsMut.length && j < creditorsMut.length) {
      final debtor = debtorsMut[i];
      final creditor = creditorsMut[j];
      final amount = [-debtor.value, creditor.value]
          .reduce((a, b) => a < b ? a : b);

      result.add(SettlementSuggestion(
        fromMemberId: debtor.key,
        toMemberId: creditor.key,
        amount: double.parse(amount.toStringAsFixed(2)),
      ));

      debtorsMut[i] = MapEntry(debtor.key, debtor.value + amount);
      creditorsMut[j] = MapEntry(creditor.key, creditor.value - amount);

      if (debtorsMut[i].value.abs() < 0.01) i++;
      if (creditorsMut[j].value.abs() < 0.01) j++;
    }
    return result;
  }
}

class SettlementSuggestion {
  final int fromMemberId;
  final int toMemberId;
  final double amount;
  SettlementSuggestion({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
  });
}
