import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memivo/core/constants/app_colors.dart';
import 'package:memivo/core/utils/date_utils.dart';
import '../../core/services/database_helper.dart';
import '../../models/birthday_model.dart';
import 'birthday_form_popup.dart';
import 'birthday_detail_popup.dart';

class BirthdayScreen extends StatefulWidget {
  const BirthdayScreen({super.key});

  @override
  State<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<BirthdayScreen> {
  List<Birthday> _birthdays = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance.getAllBirthdays();
    // Sort by days until birthday
    data.sort((a, b) =>
        AppDateUtils.daysUntilBirthday(a.birthdate).compareTo(AppDateUtils.daysUntilBirthday(b.birthdate)));
    setState(() => _birthdays = data);
  }

  // int _daysUntil(String birthdate) {
  //   final today = DateTime.now();
  //   final bday = DateTime.parse(birthdate);
  //   var next = DateTime(today.year, bday.month, bday.day);
  //   if (next.isBefore(DateTime(today.year, today.month, today.day))) {
  //     next = DateTime(today.year + 1, bday.month, bday.day);
  //   }
  //   return next
  //       .difference(DateTime(today.year, today.month, today.day))
  //       .inDays;
  // }

  // String _daysLabel(int days) {
  //   if (days == 0) return 'Today!';
  //   if (days == 1) return 'Tomorrow';
  //   return '$days days';
  // }

  void _openAddPopup() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BirthdayFormPopup(onSaved: _load),
    );
  }

  void _openDetailPopup(Birthday b) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BirthdayDetailPopup(
        birthday: b,
        daysUntil: AppDateUtils.daysUntilBirthday(b.birthdate),
        onChanged: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final next = _birthdays.isNotEmpty ? _birthdays.first : null;

    return Scaffold(
      backgroundColor: AppColors.birthdayBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        color: AppColors.birthdayIcon,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: AppColors.birthdaySubtext),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Birthdays',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.birthdayText,
                      )),
                ],
              ),
            ),

            // Next birthday banner
            if (next != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.birthdayIcon),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.birthdayPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.cake_rounded,
                              color: Colors.white, size: 18
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Next birthday',
                                style: TextStyle(
                                  fontSize: 11, color: AppColors.birthdaySubtext
                                )
                              ),
                              Text(
                                '${next.name} — ${AppDateUtils.daysLabel(AppDateUtils.daysUntilBirthday(next.birthdate))}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.birthdayText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                ),
              ),

              //List
              Expanded(
                child: _birthdays.isEmpty
                    ? const Center(
                      child: Text(
                        'No birthdays yet!\nTap + to add one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15, color: AppColors.birthdaySubtext,
                        ),
                      ),
                    )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _birthdays.length,
                      itemBuilder: (context, index) {
                        final b = _birthdays[index];
                        final days = AppDateUtils.daysUntilBirthday(b.birthdate);
                        final bday = DateTime.parse(b.birthdate);
                        final formatted =
                            DateFormat('MMM dd').format(bday);

                        return GestureDetector(
                          onTap: () => _openDetailPopup(b),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.birthdayBorder),
                            ),
                            child: Row(
                              children: [
                                //Avatar
                                CircleAvatar(
                                  radius: 23,
                                  backgroundColor: AppColors.birthdayIcon,
                                  backgroundImage: b.photoPath != null
                                      ? FileImage(File(b.photoPath!))
                                      : null,
                                  child: b.photoPath == null
                                      ? Text(
                                        b.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.birthdayText,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 17,
                                        ),
                                      )
                                      : null,
                                ),
                                const SizedBox(width: 12,),

                                //Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(b.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.birthdayText,
                                          )),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${b.relationship} · $formatted',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.birthdaySubtext,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                //Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4
                                  ),
                                  decoration: BoxDecoration(
                                    color: days  == 0
                                        ? AppColors.birthdayIcon
                                        : days <= 7
                                            ? const Color(0xFFF5DFB0)
                                            : const Color(0xFFE8D8F8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    AppDateUtils.daysLabel(days),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: days == 0
                                          ? AppColors.birthdayText
                                          : days <= 7
                                              ? const Color(0xFF6B4200)
                                              : const Color(0xFF6A3BAF),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.birthdayIcon, size: 16
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                  ),
              ),
          ],
        ),
      ),

      // FAB
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPopup,
        backgroundColor: AppColors.birthdayPrimary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

