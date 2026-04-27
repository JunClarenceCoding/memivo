import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memivo/core/constants/app_colors.dart';
import '../../core/services/database_helper.dart';
import '../../models/todo_model.dart';
import 'todo_form_popup.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Todo> _todos = [];
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance.getAllTodos();
    setState(() => _todos = data);
  }

  List<Todo> get _pending =>
      _todos.where((t) => t.status == 'pending').toList()
        ..sort((a, b) => _priorityOrder(a.priority)
            .compareTo(_priorityOrder(b.priority)));

  List<Todo> get _done =>
      _todos.where((t) => t.status == 'done').toList();

  int _priorityOrder(String priority) {
    switch (priority) {
      case 'High': return 0;
      case 'Medium': return 1;
      case 'Low': return 2;
      default: return 3;
    }
  }

  Future<void> _confirmMarkDone(Todo todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Mark as Done?',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.todoText)),
        content: Text(
          'Are you sure you want to mark "${todo.title}" as done?',
          style: const TextStyle(fontSize: 13, color: AppColors.todoSubtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.todoSubtext)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.todoPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Done!',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updated = Todo(
        id: todo.id,
        title: todo.title,
        priority: todo.priority,
        status: 'done',
        dueDate: todo.dueDate,
      );
      await DatabaseHelper.instance.updateTodo(updated);
      _load();
    }
  }

  Future<void> _deleteTodo(int id) async {
    await DatabaseHelper.instance.deleteTodo(id);
    _load();
  }

  void _openAddPopup() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TodoFormPopup(onSaved: _load),
    );
  }

  void _openEditPopup(Todo todo) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TodoFormPopup(todo: todo, onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.todoBackground,
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
                        color: const Color(0xFFC3E8CB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: AppColors.todoSubtext),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('To-Do List',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.todoText,
                      )),
                ],
              ),
            ),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.todoBorder),
                ),
                child: Row(
                  children: [
                    _buildTab('Pending', 0),
                    _buildTab('Done', 1),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Content
            Expanded(
              child: _selectedTab == 0
                  ? _buildPendingList()
                  : _buildDoneList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPopup,
        backgroundColor: AppColors.todoPrimary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.todoPrimary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : AppColors.todoSubtext,
                )),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingList() {
    if (_pending.isEmpty) {
      return const Center(
        child: Text('No pending tasks!\nTap + to add one.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.todoSubtext)),
      );
    }

    // Group by priority
    final high = _pending.where((t) => t.priority == 'High').toList();
    final medium = _pending.where((t) => t.priority == 'Medium').toList();
    final low = _pending.where((t) => t.priority == 'Low').toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (high.isNotEmpty) ...[
          _sectionLabel('🔴 HIGH', const Color(0xFFE24B4A)),
          ...high.map((t) => _pendingCard(t)),
        ],
        if (medium.isNotEmpty) ...[
          _sectionLabel('🟡 MEDIUM', const Color(0xFFB07A30)),
          ...medium.map((t) => _pendingCard(t)),
        ],
        if (low.isNotEmpty) ...[
          _sectionLabel('🟣 LOW', const Color(0xFF6A3BAF)),
          ...low.map((t) => _pendingCard(t)),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildDoneList() {
    if (_done.isEmpty) {
      return const Center(
        child: Text('No completed tasks yet!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.todoSubtext)),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        ..._done.map((t) => _doneCard(t)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: color,
          )),
    );
  }

  Widget _pendingCard(Todo todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.todoBorder),
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => _confirmMarkDone(todo),
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: todo.priority == 'High'
                      ? const Color(0xFFE24B4A)
                      : todo.priority == 'Medium'
                          ? const Color(0xFFB07A30)
                          : const Color(0xFF6A3BAF),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(todo.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.todoText,
                    )),
                const SizedBox(height: 2),
                Text(
                  todo.dueDate != null
                      ? 'Due: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(todo.dueDate!))}'
                      : 'No due date',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.todoSubtext),
                ),
              ],
            ),
          ),

          // Edit
          GestureDetector(
            onTap: () => _openEditPopup(todo),
            child: Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.todoBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_rounded,
                  size: 14, color: AppColors.todoSubtext),
            ),
          ),

          // Delete
          GestureDetector(
            onTap: () => _deleteTodo(todo.id!),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.deleteBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_rounded,
                  size: 14, color: AppColors.errorBorder),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doneCard(Todo todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.todoBorder),
      ),
      child: Row(
        children: [
          // Checked checkbox
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: AppColors.todoSubtext,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.check_rounded,
                size: 14, color: Colors.white),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Opacity(
              opacity: 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(todo.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.todoText,
                        decoration: TextDecoration.lineThrough,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    '${todo.priority == 'High' ? '🔴' : todo.priority == 'Medium' ? '🟡' : '🟣'} ${todo.priority}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.todoSubtext),
                  ),
                ],
              ),
            ),
          ),

          // Delete only
          GestureDetector(
            onTap: () => _deleteTodo(todo.id!),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.deleteBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_rounded,
                  size: 14, color: AppColors.errorBorder),
            ),
          ),
        ],
      ),
    );
  }
}