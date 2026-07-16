import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../data/repositories/split_calculator.dart';

class SettleUpScreen extends ConsumerStatefulWidget {
  final int groupId;
  const SettleUpScreen({super.key, required this.groupId});

  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  late Future<List<SettlementSuggestion>> _suggestionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  void _loadSuggestions() {
    _suggestionsFuture =
        ref.read(groupRepositoryProvider).getSettlementSuggestions(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(activeMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settle Up')),
      body: FutureBuilder<List<SettlementSuggestion>>(
        future: _suggestionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final suggestions = snapshot.data!;
          if (suggestions.isEmpty) {
            return const Center(child: Text('Everyone is settled up! 🎉'));
          }

          return membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (members) {
              final memberMap = {for (final m in members) m.id: m};
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: suggestions.length,
                itemBuilder: (context, i) {
                  final s = suggestions[i];
                  final from = memberMap[s.fromMemberId]?.name ?? 'Unknown';
                  final to = memberMap[s.toMemberId]?.name ?? 'Unknown';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: AppTypography.bodyLg,
                                children: [
                                  TextSpan(
                                      text: from,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const TextSpan(text: ' owes '),
                                  TextSpan(
                                      text: to,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  TextSpan(
                                    text: '  \$${s.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await ref.read(groupRepositoryProvider).recordSettlement(
                                    groupId: widget.groupId,
                                    fromMemberId: s.fromMemberId,
                                    toMemberId: s.toMemberId,
                                    amount: s.amount,
                                  );
                              setState(_loadSuggestions);
                            },
                            child: const Text('Mark Settled'),
                          ),
                        ],
                      ),
                    ),
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
