import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/todo_model.dart';

class TodoFormPopup extends StatefulWidget {
  final Todo? todo;
  final VoidCallback onSaved;

  const TodoFormPopup({super.key, this.todo, required this.onSaved});

  @override
  State<TodoFormPopup> createState() => _TodoFormPopupState();
}

class _TodoFormPopupState extends State<TodoFormPopup> {
  final _titleController = TextEditingController();
  String _priority = 'High';
  DateTime? _dueDate;
  String? _errorMessage;

  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.todo!;
      _titleController.text = t.title;
      _priority = t.priority;
      _dueDate = t.dueDate != null ? DateTime.parse(t.dueDate!) : null;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a task title!');
      return;
    }

    setState(() => _errorMessage = null);

    final t = Todo(
      id: _isEditing ? widget.todo!.id : null,
      title: _titleController.text.trim(),
      priority: _priority,
      status: _isEditing ? widget.todo!.status : 'pending',
      dueDate: _dueDate != null
          ? DateFormat('yyyy-MM-dd').format(_dueDate!)
          : null,
    );

    if (_isEditing) {
      await DatabaseHelper.instance.updateTodo(t);
    } else {
      await DatabaseHelper.instance.insertTodo(t);
    }

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFC3E8CB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),

              Text(_isEditing ? 'Edit Task' : 'Add Task',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2A5E35),
                  )),
              const SizedBox(height: 16),

              // Title
              _buildField(
                label: 'Task title',
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF2A5E35)),
                  decoration: _inputDecoration('Enter task title...'),
                ),
              ),
              const SizedBox(height: 10),

              // Due date
              _buildField(
                label: 'Due date (optional)',
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FAF2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC8EDD0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dueDate == null
                                ? 'Pick a date'
                                : DateFormat('MMM dd, yyyy')
                                    .format(_dueDate!),
                            style: TextStyle(
                              fontSize: 13,
                              color: _dueDate == null
                                  ? const Color(0xFF5A9E67)
                                  : const Color(0xFF2A5E35),
                            ),
                          ),
                        ),
                        if (_dueDate != null)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _dueDate = null),
                            child: const Icon(Icons.close_rounded,
                                size: 16,
                                color: Color(0xFF5A9E67)),
                          )
                        else
                          const Icon(Icons.calendar_today_rounded,
                              size: 14,
                              color: Color(0xFF5A9E67)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Priority selector
              _buildField(
                label: 'Priority',
                child: Row(
                  children: ['High', 'Medium', 'Low'].map((p) {
                    final isSelected = _priority == p;
                    final color = p == 'High'
                        ? const Color(0xFFE24B4A)
                        : p == 'Medium'
                            ? const Color(0xFFB07A30)
                            : const Color(0xFF6A3BAF);
                    final emoji =
                        p == 'High' ? '🔴' : p == 'Medium' ? '🟡' : '🟣';
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: Container(
                          margin: EdgeInsets.only(
                              right: p != 'Low' ? 6 : 0),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.12)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : const Color(0xFFDDDDDD),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text('$emoji $p',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? color
                                      : const Color(0xFFAAAAAA),
                                )),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
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
              ),
              const SizedBox(height: 8),

              // Save button
              GestureDetector(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF639922),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _isEditing ? 'Update Task' : 'Save Task',
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
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF5A9E67))),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(fontSize: 13, color: Color(0xFF5A9E67)),
      filled: true,
      fillColor: const Color(0xFFF0FAF2),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC8EDD0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC8EDD0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF639922)),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}