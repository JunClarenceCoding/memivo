import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../database/database_helper.dart';
import '../../models/birthday_model.dart';

class BirthdayFormPopup extends StatefulWidget {
  final Birthday? birthday;
  final VoidCallback onSaved;

  const BirthdayFormPopup({super.key, this.birthday, required this.onSaved});

  @override
  State<BirthdayFormPopup> createState() => _BirthdayFormPopupState();
}

class _BirthdayFormPopupState extends State<BirthdayFormPopup> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  String _relationship = 'Friend';
  DateTime? _selectedDate;
  String? _photoPath;
  String? _errorMessage;

  bool get _isEditing => widget.birthday != null;

  final List<String> _relationships = [
    'Friend', 'Family', 'Partner', 'Colleague', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    if(_isEditing) {
      final b = widget.birthday!;
      _nameController.text = b.name;
      _relationship = b.relationship;
      _selectedDate = DateTime.parse(b.birthdate);
      _notesController.text = b.notes ?? '';
      _photoPath = b.photoPath;
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery, imageQuality: 70 
    );
    if(picked != null) setState(() => _photoPath = picked.path);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if(picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if(_nameController.text.trim().isEmpty || _selectedDate == null) {
      setState(() {
        _errorMessage = 'Please fill in name and birthday date';
      });
      return;
    }

    setState(() => _errorMessage = null);

    final b = Birthday(
      id: _isEditing ? widget.birthday!.id : null,
      name: _nameController.text.trim(),
      relationship: _relationship,
      birthdate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      notes: _notesController.text.trim(),
      photoPath: _photoPath,
    );

    if(_isEditing) {
      await DatabaseHelper.instance.updateBirthday(b);
    }else {
      await DatabaseHelper.instance.insertBirthday(b);
    }

    widget.onSaved();
    if(mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top:  Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //Handle
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9C6E0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14,),

              Text(
                _isEditing ? 'Edit Birthday' : 'Add Birthday',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8B2D5E),
                ),
              ),
              const SizedBox(height: 16,),

              //Photo Picker
              GestureDetector(
                onTap: _pickPhoto,
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xFFF9C6E0),
                  backgroundImage: _photoPath != null
                      ? FileImage(File(_photoPath!))
                      : null,
                  child:  _photoPath == null
                      ? const Icon(Icons.camera_alt_rounded,
                          color: Color(0xFFC4689A), size: 26,)
                      : null,
                ),
              ),
              const SizedBox(height: 6,),
              const Text(
                'Tap to add photo',
                style: TextStyle(
                  fontSize: 11, color:  Color(0xFFC4689A)
                ),
              ),
              const SizedBox(height: 16,),

              //Name
              _buildField(
                label: 'Full name',
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontSize: 13, color:  Color(0xFF8B2D5E)
                  ),
                  decoration: _inputDecoration('Enter name...'),
                ),
              ),
              const SizedBox(height: 10,),

              //Relationship & Date side by side
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'Relationship',
                      child: DropdownButtonFormField<String>(
                        value: _relationship,
                        style: const TextStyle(
                          fontSize: 13, color: Color(0xFF8B2D5E)
                        ),
                        decoration: _inputDecoration(null),
                        items: _relationships
                            .map((r) => DropdownMenuItem(
                                value: r, child: Text(r)
                            )).toList(),
                        onChanged: (val) =>
                            setState(() => _relationship = val!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10,),
                  Expanded(
                    child: _buildField(
                      label: 'Birthday',
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF7D0E8)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedDate == null
                                      ? 'Pick date'
                                      : DateFormat('MMM dd')
                                          .format(_selectedDate!),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _selectedDate == null
                                        ? const Color(0xFFC4689A)
                                        : const Color(0xFF8B2D5E),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Color(0xFFC4689A),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10,),

              //Notes
              _buildField(
                label: 'Notes (optional)',
                child: TextField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 13, color:  Color(0xFF8B2D5E)
                  ),
                  decoration: _inputDecoration('Optional notes...'),
                ),
              ),
              const SizedBox(height: 12),

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

              //Save button
              GestureDetector(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E8C),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _isEditing ? 'Update Birthday' : 'Save Birthday',
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
      crossAxisAlignment:  CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11, color:  Color(0xFFC4689A)
          ),
        ),
        const SizedBox(height: 4,),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: 
          const TextStyle(fontSize: 13, color: Color(0xFFC4689A)),
      filled: true,
      fillColor: const Color(0xFFFFF0F7),
      contentPadding: 
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF7D0E8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF7D0E8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE91E8C)),
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