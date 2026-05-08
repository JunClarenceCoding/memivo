import 'package:flutter/material.dart';
import '../../core/services/database_helper.dart';
import '../../models/occasion_model.dart';
import '../../models/expense_model.dart';
import '../../models/participant_model.dart';
import 'expense_form_screen.dart';
import 'expense_detail_screen.dart';
import 'occasion_form_screen.dart';
import '../../models/payment_model.dart';

class OccasionDetailScreen extends StatefulWidget {
  final Occasion occasion;

  const OccasionDetailScreen({super.key, required this.occasion});

  @override
  State<OccasionDetailScreen> createState() =>
      _OccasionDetailScreenState();
}

class _OccasionDetailScreenState extends State<OccasionDetailScreen> {
  List<Expense> _expenses = [];
  Map<int, List<Participant>> _participantMap = {};
  Map<int, List<Payment>> _paymentMap = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
  final expenses = await DatabaseHelper.instance
      .getExpensesByOccasion(widget.occasion.id!);
  final participantMap = <int, List<Participant>>{};
  final paymentMap = <int, List<Payment>>{}; // ✅ add

  for (final e in expenses) {
    participantMap[e.id!] = await DatabaseHelper.instance
        .getParticipantsByExpense(e.id!);
    paymentMap[e.id!] = await DatabaseHelper.instance  // ✅ add
        .getPaymentsByExpense(e.id!);
  }

  setState(() {
    _expenses = expenses;
    _participantMap = participantMap;
    _paymentMap = paymentMap; // ✅ add
  });
}

  double get _totalAmount =>
      _expenses.fold(0, (sum, e) => sum + e.totalAmount);

  // ✅ Collected = only what was paid at the counter
// ✅ Collected = sum of shares that are fully settled
double get _totalCollected {
  double total = 0;
  for (final e in _expenses) {
    final participants = _participantMap[e.id!] ?? [];
    for (final p in participants) {
      if (p.balance >= 0) {
        // This person's share is fully covered
        total += p.amountOwed;
      } else {
        // Partially paid — count only what they've contributed
        total += p.paidAtCounter + p.paidBack;
      }
    }
  }
  return total;
}

// ✅ Remaining = sum of shares not yet paid
double get _remaining {
  double total = 0;
  for (final e in _expenses) {
    final participants = _participantMap[e.id!] ?? [];
    for (final p in participants) {
      if (p.balance < 0) {
        // Still owes money — how much more do they need to pay?
        total += p.amountOwed - p.paidAtCounter - p.paidBack;
      }
    }
  }
  return total > 0 ? total : 0;
}

  // Settlement calculation
  List<Map<String, dynamic>> _calculateSettlements() {
    final Map<String, double> balances = {};

    // Step 1 — calculate base balances from participants
    for (final e in _expenses) {
      final participants = _participantMap[e.id!] ?? [];
      for (final p in participants) {
        final net = p.paidAtCounter - p.amountOwed;
        balances[p.name] = (balances[p.name] ?? 0) + net;
      }
    }

    // Step 2 — adjust balances based on actual payments made
    for (final e in _expenses) {
      final payments = _paymentMap[e.id!] ?? [];
      for (final payment in payments) {
        // fromPerson paid toPerson → fromPerson's debt reduces
        // toPerson received money → their credit reduces
        balances[payment.fromPerson] =
            (balances[payment.fromPerson] ?? 0) + payment.amount;
        balances[payment.toPerson] =
            (balances[payment.toPerson] ?? 0) - payment.amount;
      }
    }

    // Step 3 — calculate settlements from remaining balances
    final creditors = balances.entries
        .where((e) => e.value > 0.01)
        .map((e) => {'name': e.key, 'amount': e.value})
        .toList()
      ..sort((a, b) =>
          (a['name'] as String).compareTo(b['name'] as String));

    final debtors = balances.entries
        .where((e) => e.value < -0.01)
        .map((e) => {'name': e.key, 'amount': -(e.value)})
        .toList()
      ..sort((a, b) =>
          (a['name'] as String).compareTo(b['name'] as String));

    final settlements = <Map<String, dynamic>>[];

    int i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      final debtorName = debtors[i]['name'] as String;
      final creditorName = creditors[j]['name'] as String;
      double debtorAmount = debtors[i]['amount'] as double;
      double creditorAmount = creditors[j]['amount'] as double;

      final amount = debtorAmount < creditorAmount
          ? debtorAmount
          : creditorAmount;

      if (amount > 0.01) {
        settlements.add({
          'from': debtorName,
          'to': creditorName,
          'amount': amount,
        });
      }

      debtors[i]['amount'] = debtorAmount - amount;
      creditors[j]['amount'] = creditorAmount - amount;

      if ((debtors[i]['amount'] as double) < 0.01) i++;
      if ((creditors[j]['amount'] as double) < 0.01) j++;
    }

    return settlements;
  }

  Future<void> _deleteOccasion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Occasion?',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF26215C))),
        content: Text(
          'This will delete "${widget.occasion.name}" and all its expenses. This cannot be undone.',
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF7F77DD)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF534AB7))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE24B4A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style:
                    TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance
          .deleteOccasion(widget.occasion.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settlements = _calculateSettlements();

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
                  Expanded(
                    child: Text(widget.occasion.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF26215C),
                        )),
                  ),
                  // Edit button
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OccasionFormScreen(
                              occasion: widget.occasion),
                        ),
                      );
                      _load();
                    },
                    child: Container(
                      width: 36, height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEDFE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Color(0xFF534AB7), size: 18),
                    ),
                  ),
                  // Delete button
                  GestureDetector(
                    onTap: _deleteOccasion,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCEBEB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_rounded,
                          color: Color(0xFFE24B4A), size: 18),
                    ),
                  ),
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
                    _statItem(
                        '₱${_totalAmount.toStringAsFixed(0)}',
                        'Total'),
                    Container(width: 0.5, height: 28,
                        color: const Color(0xFFAFA9EC)),
                    _statItem(
                        '₱${_totalCollected.toStringAsFixed(0)}',
                        'Collected',
                        valueColor: const Color(0xFF3B6D11)),
                    Container(width: 0.5, height: 28,
                        color: const Color(0xFFAFA9EC)),
                    _statItem(
                        '₱${_remaining > 0 ? _remaining.toStringAsFixed(0) : '0'}',
                        'Remaining',
                        valueColor: _remaining > 0
                            ? const Color(0xFFE24B4A)
                            : const Color(0xFF3B6D11)),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Expenses section
                  const Text('EXPENSES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: Color(0xFF534AB7),
                      )),
                  const SizedBox(height: 8),

                  if (_expenses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: const Color(0xFFAFA9EC)),
                      ),
                      child: const Text(
                        'No expenses yet. Tap "Add Expense" to start!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF7F77DD)),
                      ),
                    )
                  else
                    ..._expenses.map((e) {
                      final participants =
                          _participantMap[e.id!] ?? [];
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExpenseDetailScreen(expense: e),
                            ),
                          );
                          _load();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFAFA9EC)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(e.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF26215C),
                                        )),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${participants.length} people · ${e.splitMode == 'equal' ? 'Equal' : 'Custom'} split',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF7F77DD),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₱${e.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF26215C),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right_rounded,
                                  color: Color(0xFFAFA9EC), size: 16),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 12),

                  // Who owes who section
                  if (settlements.isNotEmpty) ...[
                    const Text('WHO OWES WHO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: Color(0xFF534AB7),
                        )),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEDFE),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: const Color(0xFFAFA9EC)),
                      ),
                      child: Column(
                        children: settlements.map((s) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                          fontSize: 12),
                                      children: [
                                        TextSpan(
                                          text: s['from'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF26215C),
                                          ),
                                        ),
                                        const TextSpan(
                                          text: ' needs to pay ',
                                          style: TextStyle(
                                              color: Color(0xFF7F77DD)),
                                        ),
                                        TextSpan(
                                          text: s['to'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF26215C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Text(
                                  '₱${(s['amount'] as double).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF534AB7),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Add expense button
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpenseFormScreen(
                              occasionId: widget.occasion.id!),
                        ),
                      );
                      _load();
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF534AB7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('+ Add Expense',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            )),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
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