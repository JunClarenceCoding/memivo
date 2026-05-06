import 'package:flutter/material.dart';
import '../../core/services/database_helper.dart';
import '../../models/expense_model.dart';
import '../../models/participant_model.dart';

class ExpenseFormScreen extends StatefulWidget {
  final int occasionId;
  final Expense? expense;

  const ExpenseFormScreen({
    super.key,
    required this.occasionId,
    this.expense,
  });

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _nameController = TextEditingController();
  final _totalController = TextEditingController();
  String _splitMode = 'equal';
  String? _errorMessage;

  // Payers — who paid at the counter
  final List<Map<String, dynamic>> _payers = [];
  final _payerNameController = TextEditingController();
  final _payerAmountController = TextEditingController();

  // People splitting the bill
  final List<String> _splitPeople = [];
  final _splitPersonController = TextEditingController();

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.expense!.name;
      _totalController.text =
          widget.expense!.totalAmount.toStringAsFixed(0);
      _splitMode = widget.expense!.splitMode;
    }
  }

  void _addPayer() {
    if (_payerNameController.text.trim().isEmpty ||
        _payerAmountController.text.trim().isEmpty) return;
    setState(() {
      _payers.add({
        'name': _payerNameController.text.trim(),
        'amount':
            double.tryParse(_payerAmountController.text.trim()) ?? 0,
      });
      _payerNameController.clear();
      _payerAmountController.clear();
    });
  }

  void _addSplitPerson() {
    if (_splitPersonController.text.trim().isEmpty) return;
    setState(() {
      _splitPeople.add(_splitPersonController.text.trim());
      _splitPersonController.clear();
    });
  }

  Future<void> _save() async {
  if (_nameController.text.trim().isEmpty ||
      _totalController.text.trim().isEmpty) {
    setState(() =>
        _errorMessage = 'Please fill in expense name and amount!');
    return;
  }
  if (_splitPeople.isEmpty && _payers.isEmpty) {
    setState(() =>
        _errorMessage = 'Please add at least one person!');
    return;
  }
  // ✅ Add this — validate payers total matches bill total
final totalAmount =
    double.tryParse(_totalController.text.trim()) ?? 0;
final payersTotal = _payers.fold(
    0.0, (sum, p) => sum + (p['amount'] as double));

if (_payers.isEmpty) {
  setState(() =>
      _errorMessage = 'Please add at least one payer!');
  return;
}

if ((payersTotal - totalAmount).abs() > 0.01) {
  setState(() => _errorMessage =
      'Payers total (₱${payersTotal.toStringAsFixed(0)}) must equal the total amount (₱${totalAmount.toStringAsFixed(0)})!');
  return;
}

  setState(() => _errorMessage = null);
  
  // ✅ Fix: count ALL unique people (payers + split people combined)
  final payerNames =
      _payers.map((p) => p['name'] as String).toSet();
  final allPeople = {
    ...payerNames,
    ..._splitPeople,
  };
  final totalPeople = allPeople.length;
  final equalShare =
      totalPeople > 0 ? totalAmount / totalPeople : 0.0;

  // Save expense
  final expense = Expense(
    id: _isEditing ? widget.expense!.id : null,
    occasionId: widget.occasionId,
    name: _nameController.text.trim(),
    totalAmount: totalAmount,
    splitMode: _splitMode,
  );

  int expenseId;
  if (_isEditing) {
    await DatabaseHelper.instance.updateExpense(expense);
    expenseId = widget.expense!.id!;
    // Delete old participants so we start fresh
    final old = await DatabaseHelper.instance
        .getParticipantsByExpense(expenseId);
    for (final p in old) {
      await DatabaseHelper.instance.deleteParticipant(p.id!);
    }
  } else {
    expenseId =
        await DatabaseHelper.instance.insertExpense(expense);
  }

  // Save payers first
  for (final payer in _payers) {
    final isAlsoSplitting =
        _splitPeople.contains(payer['name']);
    await DatabaseHelper.instance.insertParticipant(
      Participant(
        expenseId: expenseId,
        name: payer['name'],
        // ✅ Payer also gets their fair share assigned
        amountOwed: isAlsoSplitting || allPeople.contains(payer['name'])
            ? (_splitMode == 'equal' ? equalShare : 0)
            : 0,
        paidAtCounter: payer['amount'],
        paidBack: 0,
      ),
    );
  }

  // Save non-payer split people
  for (final person in _splitPeople) {
    if (!payerNames.contains(person)) {
      await DatabaseHelper.instance.insertParticipant(
        Participant(
          expenseId: expenseId,
          name: person,
          amountOwed:
              _splitMode == 'equal' ? equalShare : 0,
          paidAtCounter: 0,
          paidBack: 0,
        ),
      );
    }
  }

  if (mounted) Navigator.pop(context);
}

  @override
  Widget build(BuildContext context) {
    final total = double.tryParse(_totalController.text.trim()) ?? 0;

  // ✅ Replace with this
  final payerNames = _payers.map((p) => p['name'] as String).toSet();
  final allPeople = {
    ...payerNames,
    ..._splitPeople,
  };
  final totalPeople = allPeople.length;
  final equalShare = totalPeople > 0 ? total / totalPeople : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FE),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
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
                  Text(
                    _isEditing ? 'Edit Expense' : 'New Expense',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF26215C),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Expense name
                    _buildField(
                      label: 'Expense name',
                      hint: 'What did you spend on?',
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF26215C)),
                        decoration: _inputDecoration(
                            'e.g. Lunch at Jollibee'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Total amount
                    _buildField(
                      label: 'Total amount',
                      hint: 'How much was the total bill?',
                      child: TextField(
                        controller: _totalController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF26215C)),
                        decoration: _inputDecoration('e.g. 1200'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Who paid the bill
                    _buildSectionLabel(
                      'Who paid the bill?',
                      'Who took out their wallet and paid? Add all payers if more than one.',
                    ),
                    const SizedBox(height: 8),

                    // Payers list
                    ..._payers.asMap().entries.map((entry) {
                      final i = entry.key;
                      final payer = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEDFE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF534AB7),
                              width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF534AB7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  payer['name'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(payer['name'],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF26215C),
                                    fontWeight: FontWeight.w500,
                                  )),
                            ),
                            Text(
                              '₱${(payer['amount'] as double).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF534AB7),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _payers.removeAt(i)),
                              child: const Icon(Icons.close_rounded,
                                  size: 16,
                                  color: Color(0xFF7F77DD)),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Add payer row
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFAFA9EC),
                            style: BorderStyle.solid),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _payerNameController,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF26215C)),
                              decoration: const InputDecoration(
                                hintText: 'Name',
                                hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF7F77DD)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('₱',
                              style: TextStyle(
                                  color: Color(0xFF7F77DD),
                                  fontSize: 13)),
                          Expanded(
                            child: TextField(
                              controller: _payerAmountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF26215C)),
                              decoration: const InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF7F77DD)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _addPayer,
                            child: Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFF534AB7),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Split between
                    _buildSectionLabel(
                      'Split between',
                      'Who is sharing this expense? Add all of them.',
                    ),
                    const SizedBox(height: 8),

                    // Split people chips
                    if (_splitPeople.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _splitPeople
                            .asMap()
                            .entries
                            .map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEDFE),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF534AB7),
                                  width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(entry.value,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF26215C),
                                      fontWeight: FontWeight.w500,
                                    )),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => setState(() =>
                                      _splitPeople
                                          .removeAt(entry.key)),
                                  child: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: Color(0xFF7F77DD)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 8),

                    // Add split person
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFAFA9EC)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _splitPersonController,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF26215C)),
                              decoration: const InputDecoration(
                                hintText: 'Add person name',
                                hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF7F77DD)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (_) => _addSplitPerson(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _addSplitPerson,
                            child: Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFF534AB7),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // How to split
                    _buildSectionLabel(
                      'How to split?',
                      'Equally means everyone pays the same amount.',
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _splitMode = 'equal'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              decoration: BoxDecoration(
                                color: _splitMode == 'equal'
                                    ? const Color(0xFFEEEDFE)
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                  color: _splitMode == 'equal'
                                      ? const Color(0xFF534AB7)
                                      : const Color(0xFFAFA9EC),
                                  width: _splitMode == 'equal'
                                      ? 1.5
                                      : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text('Equally',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _splitMode == 'equal'
                                            ? const Color(0xFF26215C)
                                            : const Color(0xFF7F77DD),
                                      )),
                                  const SizedBox(height: 2),
                                  Text(
                                    _splitPeople.isEmpty || total == 0
                                        ? '₱0 each'
                                        : '₱${equalShare.toStringAsFixed(0)} each',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _splitMode == 'equal'
                                          ? const Color(0xFF534AB7)
                                          : const Color(0xFFAFA9EC),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _splitMode = 'custom'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              decoration: BoxDecoration(
                                color: _splitMode == 'custom'
                                    ? const Color(0xFFEEEDFE)
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                  color: _splitMode == 'custom'
                                      ? const Color(0xFF534AB7)
                                      : const Color(0xFFAFA9EC),
                                  width: _splitMode == 'custom'
                                      ? 1.5
                                      : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text('Custom',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            _splitMode == 'custom'
                                                ? const Color(
                                                    0xFF26215C)
                                                : const Color(
                                                    0xFF7F77DD),
                                      )),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Set per person',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _splitMode == 'custom'
                                          ? const Color(0xFF534AB7)
                                          : const Color(0xFFAFA9EC),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_splitMode == 'custom')
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8EE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFF5DFB0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_rounded,
                                color: Color(0xFFB07A30), size: 15),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'After saving, go inside the expense to set each person\'s custom amount.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B4200),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Error message
                    _buildErrorBox(),
                    const SizedBox(height: 8),

                    // Save button
                    GestureDetector(
                      onTap: _save,
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF534AB7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            _isEditing
                                ? 'Update Expense'
                                : 'Save Expense',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF26215C),
            )),
        const SizedBox(height: 2),
        Text(hint,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF7F77DD))),
      ],
    );
  }

  Widget _buildField(
      {required String label,
      required String hint,
      required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF26215C),
            )),
        const SizedBox(height: 3),
        Text(hint,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF7F77DD))),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _errorMessage != null
            ? const Color(0xFFFCEBEB)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _errorMessage != null
              ? const Color(0xFFE24B4A)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded,
              color: _errorMessage != null
                  ? const Color(0xFFA32D2D)
                  : Colors.transparent,
              size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? ' ',
              style: TextStyle(
                fontSize: 12,
                color: _errorMessage != null
                    ? const Color(0xFFA32D2D)
                    : Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          fontSize: 14, color: Color(0xFF7F77DD)),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFAFA9EC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFAFA9EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF534AB7)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalController.dispose();
    _payerNameController.dispose();
    _payerAmountController.dispose();
    _splitPersonController.dispose();
    super.dispose();
  }
}