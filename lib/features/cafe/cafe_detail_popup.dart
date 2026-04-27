import 'dart:io';
import 'package:flutter/material.dart';
import 'package:memivo/core/constants/app_colors.dart';
import '../../core/services/database_helper.dart';
import '../../models/cafe_model.dart';
import 'cafe_form_popup.dart';

class CafeDetailPopup extends StatelessWidget {
  final Cafe cafe;
  final VoidCallback onChanged;

  const CafeDetailPopup({
    super.key,
    required this.cafe,
    required this.onChanged,
  });

  final Map<String, String> _drinkEmoji = const {
    'Hot Coffee': '☕',
    'Iced Coffee': '🧊',
    'Milk Tea': '🧋',
    'Matcha': '🍵',
    'Frappe': '🥤',
    'Fruit Tea': '🧃',
    'Smoothie': '🥤',
    'Other': '🍹',
  };

  String _stars(int rating) => '⭐' * rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
          const SizedBox(height: 16),

          // Photo or emoji + name
          Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.cafeBorder,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: cafe.photoPath != null
                    ? Image.file(File(cafe.photoPath!), fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          _drinkEmoji[cafe.drinkType] ?? '☕',
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cafe.drinkName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.cafeText,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      '${cafe.cafeName} · ${cafe.drinkType}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.cafeSubtext),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Star rating banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cafeBorder),
            ),
            child: Column(
              children: [
                Text(_stars(cafe.rating),
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 2),
                Text('${cafe.rating} out of 5 stars',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.cafeSubtext)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Details
          if (cafe.date != null && cafe.date!.isNotEmpty)
            _detailRow('Date', cafe.date!),
          if (cafe.location != null && cafe.location!.isNotEmpty)
            _detailRow('Location', cafe.location!),
          if (cafe.price != null && cafe.price!.isNotEmpty)
            _detailRow('Price', '₱${cafe.price}'),
          if (cafe.notes != null && cafe.notes!.isNotEmpty)
            _detailRow('Notes', cafe.notes!, isLast: true),

          const SizedBox(height: 16),

          // Edit & Delete
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
                      builder: (_) => CafeFormPopup(
                        cafe: cafe,
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
                      child: Text('Edit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.editText,
                          )),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await DatabaseHelper.instance.deleteCafe(cafe.id!);
                    onChanged();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.deleteBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('Delete',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.deleteText,
                          )),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.cafeSubtext)),
              Flexible(
                child: Text(value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.cafeText,
                    )),
              ),
            ],
          ),
        ),
        if (!isLast)
          Container(height: 0.5, color: AppColors.cafeBorder),
      ],
    );
  }
}