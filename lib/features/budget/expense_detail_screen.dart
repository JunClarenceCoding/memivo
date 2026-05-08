import 'package:flutter/material.dart';
import '../../core/services/database_helper.dart';
import '../../models/expense_model.dart';
import '../../models/participant_model.dart';
import 'expense_form_screen.dart';
import '../../models/payment_model.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  List<Participant> _participants = [];
  List<Payment> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
  final participants = await DatabaseHelper.instance
      .getParticipantsByExpense(widget.expense.id!);
  final payments = await DatabaseHelper.instance
      .getPaymentsByExpense(widget.expense.id!); // ✅ add
  setState(() {
    _participants = participants;
    _payments = payments; // ✅ add
  });
}

  List<Participant> get _payers =>
      _participants.where((p) => p.paidAtCounter > 0).toList();

  Future<void> _recordPayment(Participant payer) async {

    // Step 1 — calculate current balances
    final Map<String, double> balances = {};
    for (final p in _participants) {
      final net = p.paidAtCounter - p.amountOwed;
      balances[p.name] = (balances[p.name] ?? 0) + net;
    }

    // Step 2 — adjust balances from existing payments
    for (final payment in _payments) {
      balances[payment.fromPerson] =
          (balances[payment.fromPerson] ?? 0) + payment.amount;
      balances[payment.toPerson] =
          (balances[payment.toPerson] ?? 0) - payment.amount;
    }

    // Step 3 — calculate who payer specifically owes
    // Run settlement algorithm to find payer's specific debts
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

    // Find what payer owes to each creditor
    final Map<String, double> payerOwes = {};
    int i = 0, j = 0;
    final debtorsCopy = debtors
        .map((d) => {'name': d['name'], 'amount': d['amount']})
        .toList();
    final creditorsCopy = creditors
        .map((c) => {'name': c['name'], 'amount': c['amount']})
        .toList();

    while (i < debtorsCopy.length && j < creditorsCopy.length) {
      final debtorName = debtorsCopy[i]['name'] as String;
      final creditorName = creditorsCopy[j]['name'] as String;
      double debtorAmount = debtorsCopy[i]['amount'] as double;
      double creditorAmount = creditorsCopy[j]['amount'] as double;

      final amount = debtorAmount < creditorAmount
          ? debtorAmount
          : creditorAmount;

      if (amount > 0.01 && debtorName == payer.name) {
        payerOwes[creditorName] =
            (payerOwes[creditorName] ?? 0) + amount;
      }

      debtorsCopy[i]['amount'] = debtorAmount - amount;
      creditorsCopy[j]['amount'] = creditorAmount - amount;

      if ((debtorsCopy[i]['amount'] as double) < 0.01) i++;
      if ((creditorsCopy[j]['amount'] as double) < 0.01) j++;
    }

    // Step 4 — check if payer has anyone to pay
    if (payerOwes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${payer.name} has no outstanding payments!'),
            backgroundColor: const Color(0xFF534AB7),
          ),
        );
      }
      return;
    }

    // Step 5 — show dialog with only the people payer owes
    String? selectedCreditor = payerOwes.keys.first;
    final amountController = TextEditingController(
      text: payerOwes[selectedCreditor]!.toStringAsFixed(0),
    );

    await showDialog(
  context: context,
  builder: (ctx) {
    // ✅ Animation controller for shake
    final shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: Navigator.of(ctx),
    );
    final shakeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(
            parent: shakeController, curve: Curves.elasticIn));
    bool hasError = false;
    String errorText = '';

    return StatefulBuilder(
      builder: (ctx, setDialogState) {

        // Shake widget wrapper
        Widget shakeWidget(Widget child) {
          return AnimatedBuilder(
            animation: shakeAnimation,
            builder: (context, child) {
              final sineValue =
                  (shakeController.value * 3 * 3.14159).abs();
              final offset = 8 * (sineValue > 0
                  ? (sineValue % 2 == 0 ? 1 : -1) *
                      (1 - shakeController.value)
                  : 0);
              return Transform.translate(
                offset: Offset(offset.toDouble(), 0),
                child: child,
              );
            },
            child: child,
          );
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('${payer.name} is paying back',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF26215C),
              )),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Info box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEDFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_rounded,
                        size: 14, color: Color(0xFF534AB7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Based on settlements, ${payer.name} needs to pay:',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF534AB7)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Who they owe chips
              const Text('Select who they are paying:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF26215C))),
              const SizedBox(height: 8),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: payerOwes.entries.map((entry) {
                  final isSelected = selectedCreditor == entry.key;
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedCreditor = entry.key;
                        amountController.text =
                            entry.value.toStringAsFixed(0);
                        hasError = false; // ✅ clear error on select
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEEEDFE)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF534AB7)
                              : const Color(0xFFAFA9EC),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(entry.key,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF534AB7)
                                    : const Color(0xFF26215C),
                              )),
                          Text(
                            'owes ₱${entry.value.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? const Color(0xFF534AB7)
                                  : const Color(0xFF7F77DD),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Amount field with shake
              const Text('Amount paying:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF26215C))),
              const SizedBox(height: 6),

              // ✅ Shake wrapper around the amount field
              shakeWidget(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        if (hasError) {
                          setDialogState(() => hasError = false);
                        }
                      },
                      decoration: InputDecoration(
                        prefixText: '₱ ',
                        hintText: '0',
                        helperText: selectedCreditor != null
                            ? 'Max: ₱${payerOwes[selectedCreditor]!.toStringAsFixed(0)}'
                            : null,
                        helperStyle: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF7F77DD)),
                        // ✅ Red border when error
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: hasError
                                ? const Color(0xFFE24B4A)
                                : const Color(0xFFAFA9EC),
                            width: hasError ? 2 : 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: hasError
                                ? const Color(0xFFE24B4A)
                                : const Color(0xFF534AB7),
                            width: hasError ? 2 : 1.5,
                          ),
                        ),
                      ),
                    ),
                    // ✅ Error text below field
                    if (hasError)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 4, left: 4),
                        child: Text(
                          errorText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE24B4A),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                shakeController.dispose();
                Navigator.pop(ctx);
              },
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF534AB7))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF534AB7),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final amount = double.tryParse(
                        amountController.text.trim()) ??
                    0;

                // ✅ Validate — empty or zero
                if (amount <= 0) {
                  setDialogState(() {
                    hasError = true;
                    errorText = 'Please enter a valid amount!';
                  });
                  shakeController.forward(from: 0);
                  return;
                }

                // ✅ Validate — exceeds max
                final maxOwed =
                    payerOwes[selectedCreditor] ?? 0;
                if (amount > maxOwed + 0.01) {
                  setDialogState(() {
                    hasError = true;
                    errorText =
                        'Amount cannot exceed ₱${maxOwed.toStringAsFixed(0)}!';
                  });
                  shakeController.forward(from: 0);
                  return;
                }

                // Save the payment
                await DatabaseHelper.instance.insertPayment(
                  Payment(
                    expenseId: widget.expense.id!,
                    fromPerson: payer.name,
                    toPerson: selectedCreditor!,
                    amount: amount,
                  ),
                );

                // Update paidBack on participant
                final updated = Participant(
                  id: payer.id,
                  expenseId: payer.expenseId,
                  name: payer.name,
                  amountOwed: payer.amountOwed,
                  paidAtCounter: payer.paidAtCounter,
                  paidBack: payer.paidBack + amount,
                );
                await DatabaseHelper.instance
                    .updateParticipant(updated);

                shakeController.dispose();
                _load();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Payment',
                  style: TextStyle(
                      color: Colors.white, fontSize: 13)),
            ),
          ],
        );
      },
    );
  },
);
  }

  // Future<void> _deleteParticipant(int id) async {
  //   await DatabaseHelper.instance.deleteParticipant(id);
  //   _load();
  // }

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Expense?',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF26215C))),
        content: const Text(
          'This will delete the expense and all its participants.',
          style:
              TextStyle(fontSize: 13, color: Color(0xFF7F77DD)),
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
          .deleteExpense(widget.expense.id!);
      if (mounted) Navigator.pop(context);
    }
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
                  Expanded(
                    child: Text(widget.expense.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF26215C),
                        )),
                  ),
                  // ✅ Edit button
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpenseFormScreen(
                            occasionId: widget.expense.occasionId,
                            expense: widget.expense,
                          ),
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
                    onTap: _deleteExpense,
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
                        '₱${widget.expense.totalAmount.toStringAsFixed(0)}',
                        'Total'),
                    Container(width: 0.5, height: 28,
                        color: const Color(0xFFAFA9EC)),
                    _statItem(
                        widget.expense.splitMode == 'equal'
                            ? 'Equal'
                            : 'Custom',
                        'Split'),
                    Container(width: 0.5, height: 28,
                        color: const Color(0xFFAFA9EC)),
                    _statItem('${_participants.length}', 'People'),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [

                  // Who paid the bill
                  if (_payers.isNotEmpty) ...[
                    const Text('WHO PAID THE BILL',
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFAFA9EC)),
                      ),
                      child: Column(
                        children: _payers.map((p) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEEDFE),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      p.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF534AB7),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(p.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF26215C),
                                      )),
                                ),
                                Text(
                                  'paid ₱${p.paidAtCounter.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
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

                  // Each person's share
                  const Text("EACH PERSON'S SHARE",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: Color(0xFF534AB7),
                      )),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: const Color(0xFFAFA9EC)),
                    ),
                    child: Column(
                      children: _participants
                          .asMap()
                          .entries
                          .map((entry) {
                        final i = entry.key;
                        final p = entry.value;
                        final isLast =
                            i == _participants.length - 1;

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 11),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30, height: 30,
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xFFEEEDFE),
                                      borderRadius:
                                          BorderRadius.circular(9),
                                    ),
                                    child: Center(
                                      child: Text(
                                        p.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: Color(0xFF534AB7),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w500,
                                              color:
                                                  Color(0xFF26215C),
                                            )),
                                        Text(
                                          'owes ₱${p.amountOwed.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF7F77DD),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Status badge
                                  GestureDetector(
                                    onTap: () =>
                                        _recordPayment(p),
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4),
                                      decoration: BoxDecoration(
                                        color: p.status ==
                                                'Already Paid'
                                            ? const Color(0xFFEAF3DE)
                                            : p.status == 'Partial'
                                                ? const Color(
                                                    0xFFFAEEDA)
                                                : const Color(
                                                    0xFFFCEBEB),
                                        borderRadius:
                                            BorderRadius.circular(
                                                20),
                                      ),
                                      child: Text(
                                        p.status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: p.status ==
                                                  'Already Paid'
                                              ? const Color(0xFF3B6D11)
                                              : p.status == 'Partial'
                                                  ? const Color(
                                                      0xFF633806)
                                                  : const Color(
                                                      0xFFA32D2D),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Container(
                                  height: 0.5,
                                  color: const Color(0xFFE8E6FD),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 14)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEDFE),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFAFA9EC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app_rounded,
                            size: 14, color: Color(0xFF534AB7)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Tap a person\'s status badge to update how much they\'ve paid back.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF534AB7),
                            ),
                          ),
                        ),
                      ],
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

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF26215C),
            )),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF534AB7))),
      ],
    );
  }
}