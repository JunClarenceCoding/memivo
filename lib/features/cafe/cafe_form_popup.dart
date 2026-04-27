import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memivo/core/constants/app_colors.dart';
import 'package:intl/intl.dart';
import '../../core/services/database_helper.dart';
import '../../models/cafe_model.dart';

class CafeFormPopup extends StatefulWidget {
  final Cafe? cafe;
  final VoidCallback onSaved;

  const CafeFormPopup({super.key, this.cafe, required this.onSaved});

  @override
  State<CafeFormPopup> createState() => _CafeFormPopupState();
}

class _CafeFormPopupState extends State<CafeFormPopup> {
  final _drinkNameController = TextEditingController();
  final _cafeNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  String _drinkType = 'Hot Coffee';
  int _rating = 0;
  DateTime? _date;
  String? _photoPath;
  String? _errorMessage;

  bool get _isEditing => widget.cafe != null;

  final List<Map<String, String>> _drinkTypes = [
    {'label': 'Hot Coffee', 'emoji': '☕'},
    {'label': 'Iced Coffee', 'emoji': '🧊'},
    {'label': 'Milk Tea', 'emoji': '🧋'},
    {'label': 'Matcha', 'emoji': '🍵'},
    {'label': 'Frappe', 'emoji': '🥤'},
    {'label': 'Fruit Tea', 'emoji': '🧃'},
    {'label': 'Smoothie', 'emoji': '🥤'},
    {'label': 'Other', 'emoji': '🍹'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.cafe!;
      _drinkNameController.text = c.drinkName;
      _cafeNameController.text = c.cafeName;
      _drinkType = c.drinkType;
      _rating = c.rating;
      _priceController.text = c.price ?? '';
      _locationController.text = c.location ?? '';
      _notesController.text = c.notes ?? '';
      _photoPath = c.photoPath;
      _date = c.date != null ? DateTime.parse(c.date!) : null;
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_drinkNameController.text.trim().isEmpty ||
        _cafeNameController.text.trim().isEmpty ||
        _rating == 0) {
      setState(() => _errorMessage =
          'Please fill in drink name, cafe name and rating!');
      return;
    }

    setState(() => _errorMessage = null);

    final c = Cafe(
      id: _isEditing ? widget.cafe!.id : null,
      drinkName: _drinkNameController.text.trim(),
      cafeName: _cafeNameController.text.trim(),
      drinkType: _drinkType,
      rating: _rating,
      price: _priceController.text.trim(),
      date: _date != null
          ? DateFormat('yyyy-MM-dd').format(_date!)
          : null,
      location: _locationController.text.trim(),
      notes: _notesController.text.trim(),
      photoPath: _photoPath,
    );

    if (_isEditing) {
      await DatabaseHelper.instance.updateCafe(c);
    } else {
      await DatabaseHelper.instance.insertCafe(c);
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
                  color: AppColors.cafeBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),

              Text(_isEditing ? 'Edit Entry' : 'Add Cafe Entry',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cafeText,
                  )),
              const SizedBox(height: 16),

              // Photo + drink name
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.cafeBorder,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.cafeSubtext,
                          style: BorderStyle.solid,
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _photoPath != null
                          ? Image.file(File(_photoPath!),
                              fit: BoxFit.cover)
                          : const Center(
                              child: Icon(Icons.camera_alt_rounded,
                                  color: AppColors.cafeSubtext, size: 22)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField(
                      label: 'Drink name',
                      child: TextField(
                        controller: _drinkNameController,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.cafeText),
                        decoration:
                            _inputDecoration('e.g. Caramel Macchiato'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Cafe name
              _buildField(
                label: 'Cafe name',
                child: TextField(
                  controller: _cafeNameController,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.cafeText),
                  decoration: _inputDecoration('e.g. Starbucks'),
                ),
              ),
              const SizedBox(height: 10),

              // Drink type chips
              _buildField(
                label: 'Drink type',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _drinkTypes.map((type) {
                    final isSelected = _drinkType == type['label'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _drinkType = type['label']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF3E0)
                              : AppColors.cafeBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.cafePrimary
                                : AppColors.cafeBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          '${type['emoji']} ${type['label']}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFFBA7517)
                                : AppColors.cafeText,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              // Star rating
              _buildField(
                label: 'Rating',
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cafeBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cafeBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _rating = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6),
                          child: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            size: 28,
                            color: index < _rating ? Colors.amber : Colors.grey,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Price & Date
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'Price (optional)',
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.cafeText),
                        decoration: _inputDecoration('0.00'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField(
                      label: 'Date (optional)',
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.cafeBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.cafeBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _date == null
                                      ? 'Pick date'
                                      : DateFormat('MMM dd')
                                          .format(_date!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _date == null
                                        ? AppColors.cafeSubtext
                                        : AppColors.cafeText,
                                  ),
                                ),
                              ),
                              if (_date != null)
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _date = null),
                                  child: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: AppColors.cafeSubtext),
                                )
                              else
                                const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 13,
                                    color: AppColors.cafeSubtext),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Location
              _buildField(
                label: 'Location (optional)',
                child: TextField(
                  controller: _locationController,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.cafeText),
                  decoration: _inputDecoration('e.g. BGC, Taguig'),
                ),
              ),
              const SizedBox(height: 10),

              // Notes
              _buildField(
                label: 'Notes (optional)',
                child: TextField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.cafeText),
                  decoration: _inputDecoration('e.g. So creamy!'),
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
                      ? AppColors.deleteBackground
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _errorMessage != null
                        ? AppColors.errorBorder
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_rounded,
                        color: _errorMessage != null
                            ? AppColors.deleteText
                            : Colors.transparent,
                        size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage ?? ' ',
                        style: TextStyle(
                          fontSize: 12,
                          color: _errorMessage != null
                              ? AppColors.deleteText
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
                    color: AppColors.cafePrimary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _isEditing ? 'Update Entry' : 'Save Entry',
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
                fontSize: 11, color: AppColors.cafeSubtext)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(fontSize: 13, color: AppColors.cafeSubtext),
      filled: true,
      fillColor: AppColors.cafeBackground,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cafeBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cafeBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cafePrimary),
      ),
    );
  }

  @override
  void dispose() {
    _drinkNameController.dispose();
    _cafeNameController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}