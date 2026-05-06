import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:memivo/core/constants/app_colors.dart';
import '../../core/services/database_helper.dart';
import '../../models/occasion_model.dart';
import '../../models/expense_model.dart';
import '../../models/participant_model.dart';
import 'occasion_form_screen.dart';
import 'occasion_detail_screen.dart';


class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<Occasion> _occasions = [];
  Map<int, List<Expense>> _expenseMap = {};
  Map<int, List<Participant>> _participantMap = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final occasions = await DatabaseHelper.instance.getAllOccasions();
    final expenseMap = <int, List<Expense>>{};
    final participantMap = <int, List<Participant>>{};

    for (final o in occasions) {
      final expenses =
          await DatabaseHelper.instance.getExpensesByOccasion(o.id!);
      expenseMap[o.id!] = expenses;
      for (final e in expenses) {
        final participants = await DatabaseHelper.instance
            .getParticipantsByExpense(e.id!);
        participantMap[e.id!] = participants;
      }
    }

    setState(() {
      _occasions = occasions;
      _expenseMap = expenseMap;
      _participantMap = participantMap;
    });
  }

  double _totalSpent(int occasionId) {
    final expenses = _expenseMap[occasionId] ?? [];
    return expenses.fold(0, (sum, e) => sum + e.totalAmount);
  }

  bool _isSettled(int occasionId) {
    final expenses = _expenseMap[occasionId] ?? [];
    for (final e in expenses) {
      final participants = _participantMap[e.id!] ?? [];
      for (final p in participants) {
        if (p.balance < 0) return false;
      }
    }
    return true;
  }

  double _totalUnsettled() {
    double total = 0;
    for (final o in _occasions) {
      if (!_isSettled(o.id!)) {
        total += _totalSpent(o.id!);
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FE),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCECBF6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: Color(0xFF534AB7)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Budget Splitter',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF26215C),
                      )),
                ],
              ),
            ),

            // Stats bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFAFA9EC)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('${_occasions.length}', 'Occasions'),
                    Container(width: 0.5, height: 28,
                        color: const Color(0xFFAFA9EC)),
                    _statItem(
                      _occasions.isEmpty
                          ? '₱0'
                          : '₱${_occasions.fold(0.0, (sum, o) => sum + _totalSpent(o.id!)).toStringAsFixed(0)}',
                      'Total Spent',
                    ),
                    Container(width: 0.5, height: 28,
                        color: const Color(0xFFAFA9EC)),
                    _statItem(
                      '₱${_totalUnsettled().toStringAsFixed(0)}',
                      'Unsettled',
                      valueColor: _totalUnsettled() > 0
                          ? const Color(0xFFE24B4A)
                          : const Color(0xFF26215C),
                    ),
                  ],
                ),
              ),
            ),

            // List
            Expanded(
              child: _occasions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEDFE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Color(0xFF534AB7),
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('No occasions yet!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF26215C),
                              )),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap + to create your first occasion\nand start splitting expenses!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7F77DD),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _occasions.length,
                      itemBuilder: (context, index) {
                        final o = _occasions[index];
                        final expenses = _expenseMap[o.id!] ?? [];
                        final total = _totalSpent(o.id!);
                        final settled = _isSettled(o.id!);

                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    OccasionDetailScreen(occasion: o),
                              ),
                            );
                            _load();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFAFA9EC)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEEDFE),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Center(
                                      child: Text('🍽️',
                                          style:
                                              TextStyle(fontSize: 20))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(o.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF26215C),
                                          )),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${o.date != null ? '${DateFormat('MMM dd').format(DateTime.parse(o.date!))} · ' : ''}${expenses.length} expense${expenses.length != 1 ? 's' : ''}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF7F77DD),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₱${total.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF26215C),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: settled
                                            ? const Color(0xFFEAF3DE)
                                            : const Color(0xFFFCEBEB),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        settled ? 'Settled' : 'Unsettled',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: settled
                                              ? const Color(0xFF3B6D11)
                                              : const Color(0xFFA32D2D),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right_rounded,
                                    color: Color(0xFFAFA9EC), size: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const OccasionFormScreen()),
          );
          _load();
        },
        backgroundColor: const Color(0xFF534AB7),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _statItem(String value, String label,
      {Color valueColor = const Color(0xFF26215C)}) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor,
            )),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF534AB7))),
      ],
    );
  }
}