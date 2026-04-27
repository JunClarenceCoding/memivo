import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memivo/core/constants/app_colors.dart';
import '../../core/services/database_helper.dart';
import '../../models/birthday_model.dart';
import 'birthday_form_popup.dart';

class BirthdayDetailPopup extends StatelessWidget {
  final Birthday birthday;
  final int daysUntil;
  final VoidCallback onChanged;

  const BirthdayDetailPopup({
    super.key,
    required this.birthday,
    required this.daysUntil,
    required this.onChanged,
  });

  String get _daysLabel {
    if (daysUntil == 0) return 'TODAY!';
    if (daysUntil == 1) return 'Tomorrow';
    return 'In $daysUntil days';
  }

  int get _ageThisYear {
    final today = DateTime.now();
    final bday = DateTime.parse(birthday.birthdate);
    int age = today.year - bday.year;

    if (today.month < bday.month || 
      (today.month == bday.month && today.day < bday.day)) {
        age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final bday = DateTime.parse(birthday.birthdate);
    final formatted = DateFormat('MMMM dd, yyyy').format(bday);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //Handle
          Container(
            width: 48, height: 4,
            decoration:  BoxDecoration(
              color:  AppColors.birthdayIcon,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16,),

          //Avatar
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.birthdayIcon,
            backgroundImage: birthday.photoPath != null
                ? FileImage(File(birthday.photoPath!))
                : null,
            child: birthday.photoPath == null
                ? Text(birthday.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: AppColors.birthdayText,
                    ),)
                : null,
          ),
          const SizedBox(height: 10,),

          Text(
            birthday.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.birthdayText,
            ),
          ),
          const SizedBox(height: 2,),
          Text(
            birthday.relationship,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.birthdaySubtext,
            ),
          ),
          const SizedBox(height: 14,),

          //Countdown banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color:  AppColors.birthdayPrimary,
              borderRadius:  BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text(
                  'Next birthday',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70
                  ),
                ),
                const SizedBox(height: 2,),
                Text(
                  '$_daysLabel — $formatted',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color:  Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14,),

          //Details
          _detailRow('Current age', '$_ageThisYear years old'),
          _detailRow('Birthday', formatted),
          if (birthday.notes != null  && birthday.notes!.isNotEmpty)
            _detailRow('Notes', birthday.notes!),

          const SizedBox(height: 16,),

          //Edit & Delete Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => BirthdayFormPopup(
                        birthday: birthday,
                        onSaved: onChanged,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.editBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.editText,
                        ),
                      ),
                    ),
                  ),
                )
              ),
              const SizedBox(width: 10,),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await DatabaseHelper.instance.deleteBirthday(birthday.id!);
                    onChanged();
                    if(context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.deleteBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.deleteText,
                        ),
                      ),
                    ),
                  ),
                )
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment:  MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13, color: AppColors.deleteText,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.birthdayText,
            ),
          ),
        ],
      ),
    );
  }
}