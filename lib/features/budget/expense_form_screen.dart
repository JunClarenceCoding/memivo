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

  // Payers — name, amount paid, own expense
  // { 'name': String, 'amount': double, 'ownExpense': double }
  final List<Map<String, dynamic>> _payers = [];
  final _payerNameController = TextEditingController();
  final _payerAmountController = TextEditingController();

  // Equal split people — just names
  final List<String> _splitPeople = [];
  final _splitPersonController = TextEditingController();


  // Custom split people
  // { 'name': String, 'payingTo': [ { 'payerName': String, 'amount': double } ] }
  final List<Map<String, dynamic>> _customPeople = [];
  final _customPersonController = TextEditingController();

  // ✅ Add this — controllers for custom people paying to rows
  // Key: 'personIndex_rowIndex' → controller
  final Map<String, TextEditingController> _customAmountControllers = {};

  TextEditingController _getCustomController(int personIndex, int rowIndex) {
    final key = '${personIndex}_$rowIndex';
    if (!_customAmountControllers.containsKey(key)) {
      final payingTo = (_customPeople[personIndex]['payingTo']
          as List<Map<String, dynamic>>);
      final amount = payingTo[rowIndex]['amount'] as double? ?? 0;
      _customAmountControllers[key] = TextEditingController(
        text: amount > 0 ? amount.toStringAsFixed(0) : '',
      );
    }
    return _customAmountControllers[key]!;
  }

  void _cleanupCustomControllers() {
    for (final controller in _customAmountControllers.values) {
      controller.dispose();
    }
    _customAmountControllers.clear();
  }

  bool get _isEditing => widget.expense != null;

  // Computed — how much each payer is owed by others
  Map<String, double> get _payerOwedAmounts {
    final Map<String, double> result = {};
    for (final payer in _payers) {
      final name = payer['name'] as String;
      final paid = payer['amount'] as double;
      final ownExpense = payer['ownExpense'] as double? ?? 0;
      result[name] = paid - ownExpense;
    }
    return result;
  }

  // Computed — how much of each payer's owed amount is still unassigned
  Map<String, double> get _payerRemainingAmounts {
    final Map<String, double> remaining = Map.from(_payerOwedAmounts);
    for (final person in _customPeople) {
      final payingTo =
          person['payingTo'] as List<Map<String, dynamic>>;
      for (final row in payingTo) {
        final payerName = row['payerName'] as String;
        final amount = row['amount'] as double? ?? 0;
        if (remaining.containsKey(payerName)) {
          remaining[payerName] = (remaining[payerName] ?? 0) - amount;
        }
      }
    }
    return remaining;
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.expense!.name;
      _totalController.text =
          widget.expense!.totalAmount.toStringAsFixed(0);
      _splitMode = widget.expense!.splitMode;
      _loadExistingParticipants();
    }
  }

  Future<void> _loadExistingParticipants() async {
    final participants = await DatabaseHelper.instance
        .getParticipantsByExpense(widget.expense!.id!);

    setState(() {
      for (final p in participants) {
        if (p.paidAtCounter > 0) {
          _payers.add({
            'name': p.name,
            'amount': p.paidAtCounter,
            'ownExpense': 0.0,
          });
        }
        if (p.amountOwed > 0) {
          if (_splitMode == 'equal') {
            if (!_splitPeople.contains(p.name)) {
              _splitPeople.add(p.name);
            }
          } else {
            // custom — add to custom people with empty paying to
            if (!_customPeople
                .any((cp) => cp['name'] == p.name)) {
              _customPeople.add({
                'name': p.name,
                'payingTo': <Map<String, dynamic>>[],
              });
            }
          }
        }
        _cleanupCustomControllers();
      }
    });
  }

  void _addPayer() {
    if (_payerNameController.text.trim().isEmpty ||
        _payerAmountController.text.trim().isEmpty) return;
    setState(() {
      _payers.add({
        'name': _payerNameController.text.trim(),
        'amount':
            double.tryParse(_payerAmountController.text.trim()) ??
                0,
        'ownExpense': 0.0,
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

  void _addCustomPerson() {
  if (_customPersonController.text.trim().isEmpty) return;
  final payingTo = _payers.map((p) {
    return {
      'payerName': p['name'] as String,
      'amount': 0.0,
    };
  }).toList();

  setState(() {
    _customPeople.add({
      'name': _customPersonController.text.trim(),
      'payingTo': payingTo,
    });
    _customPersonController.clear();
    _cleanupCustomControllers(); // ✅ ADD THIS LINE
  });
}

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _totalController.text.trim().isEmpty) {
      setState(() =>
          _errorMessage = 'Please fill in expense name and amount!');
      return;
    }

    final totalAmount =
        double.tryParse(_totalController.text.trim()) ?? 0;
    final payersTotal = _payers.fold(
        0.0, (sum, p) => sum + (p['amount'] as double));

    if (_payers.isEmpty) {
      setState(
          () => _errorMessage = 'Please add at least one payer!');
      return;
    }

    if ((payersTotal - totalAmount).abs() > 0.01) {
      setState(() => _errorMessage =
          'Payers total (₱${payersTotal.toStringAsFixed(0)}) must equal the total amount (₱${totalAmount.toStringAsFixed(0)})!');
      return;
    }

    if (_splitMode == 'equal' && _splitPeople.isEmpty) {
      setState(() =>
          _errorMessage = 'Please add at least one person to split!');
      return;
    }

    if (_splitMode == 'custom' && _customPeople.isEmpty) {
      setState(() =>
          _errorMessage = 'Please add at least one person!');
      return;
    }

    setState(() => _errorMessage = null);

    // Equal split calculations
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
      final old = await DatabaseHelper.instance
          .getParticipantsByExpense(expenseId);
      for (final p in old) {
        await DatabaseHelper.instance.deleteParticipant(p.id!);
      }
      await DatabaseHelper.instance
          .deletePaymentsByExpense(expenseId);
    } else {
      expenseId =
          await DatabaseHelper.instance.insertExpense(expense);
    }

    if (_splitMode == 'equal') {
      // Save payers
      for (final payer in _payers) {
        final isAlsoSplitting =
            _splitPeople.contains(payer['name']);
        await DatabaseHelper.instance.insertParticipant(
          Participant(
            expenseId: expenseId,
            name: payer['name'],
            amountOwed: allPeople.contains(payer['name'])
                ? equalShare
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
              amountOwed: equalShare,
              paidAtCounter: 0,
              paidBack: 0,
            ),
          );
        }
      }
    } else {
      // Custom split

      // Save payers with their own expense as amountOwed
      for (final payer in _payers) {
        final ownExpense = payer['ownExpense'] as double? ?? 0;
        await DatabaseHelper.instance.insertParticipant(
          Participant(
            expenseId: expenseId,
            name: payer['name'],
            amountOwed: ownExpense, // what they owe to themselves
            paidAtCounter: payer['amount'],
            paidBack: 0,
          ),
        );
      }

      // Save custom people
      for (final person in _customPeople) {
        // Total owed = sum of all their paying to rows
        final payingTo =
            person['payingTo'] as List<Map<String, dynamic>>;
        final totalOwed = payingTo.fold(
            0.0, (sum, row) => sum + (row['amount'] as double? ?? 0));

        await DatabaseHelper.instance.insertParticipant(
          Participant(
            expenseId: expenseId,
            name: person['name'],
            amountOwed: totalOwed,
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
    final total =
        double.tryParse(_totalController.text.trim()) ?? 0;
    final payerNames =
        _payers.map((p) => p['name'] as String).toSet();
    final allPeople = {...payerNames, ..._splitPeople};
    final totalPeople = allPeople.length;
    final equalShare =
        totalPeople > 0 ? total / totalPeople : 0.0;
    final remaining = _payerRemainingAmounts;

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
                            fontSize: 14,
                            color: Color(0xFF26215C)),
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
                            fontSize: 14,
                            color: Color(0xFF26215C)),
                        decoration: _inputDecoration('e.g. 1200'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ✅ Split mode selector — MOVED TO TOP
                    _buildSectionLabel(
                      'How to split?',
                      'Choose how to divide this expense.',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _splitMode = 'equal'),
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
                                  width:
                                      _splitMode == 'equal' ? 1.5 : 1,
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
                                    total == 0 || totalPeople == 0
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
                            onTap: () => setState(
                                () => _splitMode = 'custom'),
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
                                        color: _splitMode == 'custom'
                                            ? const Color(0xFF26215C)
                                            : const Color(0xFF7F77DD),
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
                    const SizedBox(height: 16),

                    // Who paid the bill
                    _buildSectionLabel(
                      'Who paid the bill?',
                      _splitMode == 'custom'
                          ? 'Enter how much they paid and how much they spent on themselves.'
                          : 'Who took out their wallet and paid?',
                    ),
                    const SizedBox(height: 8),

                    // Payers list
                    ..._payers.asMap().entries.map((entry) {
                      final i = entry.key;
                      final payer = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEDFE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF534AB7),
                              width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF534AB7),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (payer['name'] as String)[0]
                                          .toUpperCase(),
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
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _payers.removeAt(i)),
                                  child: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: Color(0xFF7F77DD)),
                                ),
                              ],
                            ),

                            // ✅ Custom mode — show paid + own expense fields
                            if (_splitMode == 'custom') ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                            'Paid at counter',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Color(
                                                    0xFF7F77DD))),
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 10,
                                              vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    8),
                                            border: Border.all(
                                                color: const Color(
                                                    0xFFAFA9EC)),
                                          ),
                                          child: Text(
                                            '₱${(payer['amount'] as double).toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Color(0xFF26215C),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                            'Spent on themselves',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Color(
                                                    0xFF7F77DD))),
                                        const SizedBox(height: 3),
                                        TextField(
                                          keyboardType:
                                              TextInputType.number,
                                          onChanged: (val) {
                                            setState(() {
                                              _payers[i][
                                                      'ownExpense'] =
                                                  double.tryParse(
                                                          val) ??
                                                      0;
                                            });
                                          },
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(
                                                  0xFF26215C)),
                                          decoration: InputDecoration(
                                            hintText: '₱0',
                                            hintStyle: const TextStyle(
                                                fontSize: 12,
                                                color: Color(
                                                    0xFF7F77DD)),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 10,
                                                    vertical: 8),
                                            border:
                                                OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(8),
                                              borderSide:
                                                  const BorderSide(
                                                      color: Color(
                                                          0xFFAFA9EC)),
                                            ),
                                            enabledBorder:
                                                OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(8),
                                              borderSide:
                                                  const BorderSide(
                                                      color: Color(
                                                          0xFFAFA9EC)),
                                            ),
                                            focusedBorder:
                                                OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(8),
                                              borderSide:
                                                  const BorderSide(
                                                      color: Color(
                                                          0xFF534AB7)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Others owe indicator
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Others owe ${payer['name']}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF7F77DD)),
                                    ),
                                    Text(
                                      '₱${(_payerOwedAmounts[payer['name']] ?? 0).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF534AB7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Remaining indicator
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Still unassigned',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF7F77DD))),
                                  Text(
                                    '₱${(remaining[payer['name']] ?? 0).toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          (remaining[payer['name']] ??
                                                      0) >
                                                  0
                                              ? const Color(0xFF534AB7)
                                              : const Color(
                                                  0xFF3B6D11),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Equal mode — just show amount
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '₱${(payer['amount'] as double).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF534AB7),
                                  ),
                                ),
                              ),
                            ],
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
                            color: const Color(0xFFAFA9EC)),
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

                    // ✅ Equal split — show split between section
                    if (_splitMode == 'equal') ...[
                      _buildSectionLabel(
                        'Split between',
                        'Who is sharing this expense equally?',
                      ),
                      const SizedBox(height: 8),

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
                                borderRadius:
                                    BorderRadius.circular(20),
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
                                onSubmitted: (_) =>
                                    _addSplitPerson(),
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
                    ],

                    // ✅ Custom split — show who owes what section
                    if (_splitMode == 'custom') ...[
                      _buildSectionLabel(
                        'Who owes what?',
                        'Add each person, their amount, and who they are paying.',
                      ),
                      const SizedBox(height: 4),

                      // Remaining summary bar
                      if (_payers.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEDFE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_rounded,
                                  size: 13,
                                  color: Color(0xFF534AB7)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Remaining to assign: ${_payers.map((p) => '${p['name']}: ₱${(remaining[p['name']] ?? 0).toStringAsFixed(0)}').join(' · ')}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF534AB7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Custom people list
                      ..._customPeople.asMap().entries.map((entry) {
                        final personIndex = entry.key;
                        final person = entry.value;
                        final payingTo = person['payingTo']
                            as List<Map<String, dynamic>>;
                        final totalOwed = payingTo.fold(
                            0.0,
                            (sum, row) =>
                                sum +
                                (row['amount'] as double? ?? 0));

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFAFA9EC)),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // Person header
                              Row(
                                children: [
                                  Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xFFEEEDFE),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        (person['name']
                                                as String)[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: Color(0xFF534AB7),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(person['name'],
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w500,
                                          color: Color(0xFF26215C),
                                        )),
                                  ),
                                  Text(
                                    'Total: ₱${totalOwed.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF534AB7),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _customPeople.removeAt(personIndex);
                                      _cleanupCustomControllers(); // ✅ ADD THIS
                                    }),
                                    child: Container(
                                      width: 22, height: 22,
                                      decoration: BoxDecoration(
                                        color:
                                            const Color(0xFFFCEBEB),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                          Icons.close_rounded,
                                          size: 12,
                                          color: Color(0xFFE24B4A)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Paying to rows
                              ...payingTo.asMap().entries.map(
                                  (rowEntry) {
                                final rowIndex = rowEntry.key;
                                final row = rowEntry.value;
                                final payerName =
                                    row['payerName'] as String;
                                final maxAmount =
                                    (remaining[payerName] ?? 0) +
                                        (row['amount'] as double? ??
                                            0);

                                return Container(
                                  margin: const EdgeInsets.only(
                                      bottom: 6),
                                  child: Row(
                                    children: [
                                      const Text('pays',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Color(
                                                  0xFF7F77DD))),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 10,
                                            vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                              0xFFEEEDFE),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  20),
                                          border: Border.all(
                                            color: const Color(
                                                0xFF534AB7),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(payerName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: Color(
                                                  0xFF534AB7),
                                            )),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: TextField(
                                          keyboardType:
                                              TextInputType.number,
                                          controller: _getCustomController(personIndex, rowIndex),
                                          onChanged: (val) {
                                            final entered =
                                                double.tryParse(
                                                        val) ??
                                                    0;
                                            // ✅ Safety — cannot exceed remaining
                                            if (entered >
                                                maxAmount + 0.01) {
                                              return;
                                            }
                                            setState(() {
                                              _customPeople[
                                                          personIndex]
                                                      ['payingTo']
                                                  [rowIndex]['amount'] = entered;
                                            });
                                          },
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(
                                                  0xFF26215C)),
                                          decoration:
                                              InputDecoration(
                                            hintText: '₱0',
                                            hintStyle: const TextStyle(
                                                fontSize: 12,
                                                color: Color(
                                                    0xFF7F77DD)),
                                            helperText:
                                                'Max ₱${maxAmount.toStringAsFixed(0)}',
                                            helperStyle: const TextStyle(
                                                fontSize: 9,
                                                color: Color(
                                                    0xFF7F77DD)),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 10,
                                                    vertical: 8),
                                            border:
                                                OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(8),
                                              borderSide:
                                                  const BorderSide(
                                                      color: Color(
                                                          0xFFAFA9EC)),
                                            ),
                                            enabledBorder:
                                                OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(8),
                                              borderSide:
                                                  const BorderSide(
                                                      color: Color(
                                                          0xFFAFA9EC)),
                                            ),
                                            focusedBorder:
                                                OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(8),
                                              borderSide:
                                                  const BorderSide(
                                                      color: Color(
                                                          0xFF534AB7)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Remove row button
                                      if (payingTo.length > 1)
                                        GestureDetector(
                                          onTap: () => setState(() {
                                            (_customPeople[personIndex]['payingTo']
                                                as List<Map<String, dynamic>>)
                                                .removeAt(rowIndex);
                                            _cleanupCustomControllers(); // ✅ ADD THIS
                                          }),
                                          child: Container(
                                            width: 22, height: 22,
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                  0xFFFCEBEB),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(6),
                                            ),
                                            child: const Icon(
                                                Icons.close_rounded,
                                                size: 12,
                                                color: Color(
                                                    0xFFE24B4A)),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),

                              // Add another payer row button
                              if (_payers.length > 1)
                                GestureDetector(
                                  onTap: () {
                                    // Add a new paying to row with
                                    // the first payer not already in list
                                    final usedPayers = payingTo
                                        .map((r) =>
                                            r['payerName'] as String)
                                        .toSet();
                                    final availablePayer = _payers
                                        .firstWhere(
                                          (p) => !usedPayers.contains(
                                              p['name']),
                                          orElse: () => _payers.first,
                                        );
                                    setState(() {
                                      (_customPeople[personIndex]['payingTo']
                                          as List<Map<String, dynamic>>)
                                          .add({
                                        'payerName': availablePayer['name'],
                                        'amount': 0.0,
                                      });
                                      _cleanupCustomControllers(); // ✅ ADD THIS
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F1FE),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(
                                              0xFFAFA9EC)),
                                    ),
                                    child: const Text(
                                        '+ Pay another person',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF7F77DD),
                                        )),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 8),

                      // Add custom person
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
                                controller: _customPersonController,
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
                                onSubmitted: (_) =>
                                    _addCustomPerson(),
                              ),
                            ),
                            GestureDetector(
                              onTap: _addCustomPerson,
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
                    ],

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
    _customPersonController.dispose();
    _cleanupCustomControllers();
    super.dispose();
  }
}