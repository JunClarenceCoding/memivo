import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/database_helper.dart';
import '../../models/occasion_model.dart';

class OccasionFormScreen extends StatefulWidget {
  final Occasion? occasion;

  const OccasionFormScreen({super.key, this.occasion});

  @override
  State<OccasionFormScreen> createState() =>
      _OccasionFormScreenState();
}

class _OccasionFormScreenState extends State<OccasionFormScreen> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _date;
  String? _errorMessage;

  bool get _isEditing => widget.occasion != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.occasion!.name;
      _notesController.text = widget.occasion!.notes ?? '';
      _date = widget.occasion!.date != null
          ? DateTime.parse(widget.occasion!.date!)
          : null;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      setState(
          () => _errorMessage = 'Please enter an occasion name!');
      return;
    }

    setState(() => _errorMessage = null);

    final o = Occasion(
      id: _isEditing ? widget.occasion!.id : null,
      name: _nameController.text.trim(),
      date: _date != null
          ? DateFormat('yyyy-MM-dd').format(_date!)
          : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (_isEditing) {
      await DatabaseHelper.instance.updateOccasion(o);
    } else {
      await DatabaseHelper.instance.insertOccasion(o);
    }

    if (mounted) Navigator.pop(context);
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
                    _isEditing ? 'Edit Occasion' : 'New Occasion',
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
                    // Name
                    _buildField(
                      label: 'Occasion name',
                      hint: 'What is this occasion? e.g. Barkada Lakad',
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF26215C)),
                        decoration:
                            _inputDecoration('e.g. Barkada Lakad'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date
                    _buildField(
                      label: 'Date (optional)',
                      hint: 'When did this happen?',
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFAFA9EC)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _date == null
                                      ? 'Pick a date'
                                      : DateFormat('MMMM dd, yyyy')
                                          .format(_date!),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _date == null
                                        ? const Color(0xFF7F77DD)
                                        : const Color(0xFF26215C),
                                  ),
                                ),
                              ),
                              if (_date != null)
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _date = null),
                                  child: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: Color(0xFF7F77DD)),
                                )
                              else
                                const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 15,
                                    color: Color(0xFF7F77DD)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    _buildField(
                      label: 'Notes (optional)',
                      hint: 'Any extra details about this occasion?',
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF26215C)),
                        decoration: _inputDecoration(
                            'e.g. Christmas hangout with barkada'),
                      ),
                    ),
                    const SizedBox(height: 24),

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
                                ? 'Update Occasion'
                                : 'Save Occasion',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
    _notesController.dispose();
    super.dispose();
  }
}