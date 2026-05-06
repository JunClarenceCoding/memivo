import 'package:flutter/material.dart';
import '../../core/services/database_helper.dart';
import '../../models/expense_model.dart';
import '../../models/participant_model.dart';
// import 'expense_form_screen.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  List<Participant> _participants = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final participants = await DatabaseHelper.instance
        .getParticipantsByExpense(widget.expense.id!);
    setState(() => _participants = participants);
  }

  List<Participant> get _payers =>
      _participants.where((p) => p.paidAtCounter > 0).toList();

  Future<void> _updatePaidBack(Participant p) async {
    final controller = TextEditingController(
        text: p.paidBack.toStringAsFixed(0));

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('${p.name} — Paid Back',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF26215C))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${p.name} owes ₱${p.amountOwed.toStringAsFixed(0)}. How much have they paid back so far?',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF7F77DD)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₱ ',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF534AB7)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
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
              final updated = Participant(
                id: p.id,
                expenseId: p.expenseId,
                name: p.name,
                amountOwed: p.amountOwed,
                paidAtCounter: p.paidAtCounter,
                paidBack:
                    double.tryParse(controller.text.trim()) ?? 0,
              );
              await DatabaseHelper.instance
                  .updateParticipant(updated);
              _load();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Save',
                style:
                    TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteParticipant(int id) async {
    await DatabaseHelper.instance.deleteParticipant(id);
    _load();
  }

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
                                        _updatePaidBack(p),
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

                                  // Delete
                                  GestureDetector(
                                    onTap: () =>
                                        _deleteParticipant(p.id!),
                                    child: Container(
                                      width: 28, height: 28,
                                      decoration: BoxDecoration(
                                        color:
                                            const Color(0xFFFCEBEB),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                          Icons.delete_rounded,
                                          size: 14,
                                          color: Color(0xFFE24B4A)),
                                    ),
                                  ),
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