import 'dart:io';
import 'package:flutter/material.dart';
import 'package:memivo/core/constants/app_colors.dart';
import '../../core/services/database_helper.dart';
import '../../models/cafe_model.dart';
import 'cafe_detail_popup.dart';
import 'cafe_form_popup.dart';

class CoffeeScreen extends StatefulWidget {
  const CoffeeScreen({super.key});

  @override
  State<CoffeeScreen> createState() => _CoffeeScreenState();
}

class _CoffeeScreenState extends State<CoffeeScreen> {
  List<Cafe> _cafes = [];
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Hot Coffee',
    'Iced Coffee',
    'Milk Tea',
    'Matcha',
    'Frappe',
    'Fruit Tea',
    'Smoothie',
    'Other',
  ];

  final Map<String, String> _drinkEmoji = {
    'Hot Coffee': '☕',
    'Iced Coffee': '🧊',
    'Milk Tea': '🧋',
    'Matcha': '🍵',
    'Frappe': '🥤',
    'Fruit Tea': '🧃',
    'Smoothie': '🥤',
    'Other': '🍹',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance.getAllCafes();
    setState(() => _cafes = data);
  }

  List<Cafe> get _filtered => _selectedFilter == 'All'
      ? _cafes
      : _cafes.where((c) => c.drinkType == _selectedFilter).toList();

  double get _avgRating {
    if (_filtered.isEmpty) return 0;
    return _filtered.map((c) => c.rating).reduce((a, b) => a + b) /
        _filtered.length;
  }

  double get _avgPrice {
    final withPrice = _filtered
        .where((c) => c.price != null && c.price!.isNotEmpty)
        .toList();
    if (withPrice.isEmpty) return 0;
    final total = withPrice
        .map((c) => double.tryParse(c.price!) ?? 0)
        .reduce((a, b) => a + b);
    return total / withPrice.length;
  }

  String _stars(int rating) => '⭐' * rating;

  void _openAddPopup() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CafeFormPopup(onSaved: _load),
    );
  }

  void _openDetailPopup(Cafe cafe) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CafeDetailPopup(cafe: cafe, onChanged: _load),
    );
  }

  void _showFilterDropdown() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.cafeBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Filter by Drink Type',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.cafeText,
                )),
            const SizedBox(height: 12),
            ..._filterOptions.map((option) {
              final isSelected = _selectedFilter == option;
              final emoji = option == 'All' ? '🍹' : _drinkEmoji[option]!;
              return GestureDetector(
                onTap: () => Navigator.pop(context, option),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFF3E0)
                        : AppColors.cafeBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.cafePrimary
                          : AppColors.cafeBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    '$emoji $option',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.cafePrimary
                          : AppColors.cafeText,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _selectedFilter = selected);
  }

  @override
  Widget build(BuildContext context) {
    final isFiltered = _selectedFilter != 'All';

    return Scaffold(
      backgroundColor: AppColors.cafeBackground,
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
                        color: AppColors.cafeBorder,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: AppColors.cafeSubtext),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Cafe Journal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.cafeText,
                      )),
                ],
              ),
            ),

            // Stats bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cafeBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('${_filtered.length}', 'Total'),
                    Container(width: 0.5, height: 28,
                        color: AppColors.cafeBorder),
                    _statItem(
                        _filtered.isEmpty
                            ? '—'
                            : '${_avgRating.toStringAsFixed(1)} ⭐',
                        'Avg Rating'),
                    Container(width: 0.5, height: 28,
                        color: AppColors.cafeBorder),
                    _statItem(
                        _avgPrice == 0 ? '—' : '₱${_avgPrice.toStringAsFixed(0)}',
                        'Avg Price'),
                  ],
                ),
              ),
            ),

            // Filter dropdown
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: GestureDetector(
                onTap: _showFilterDropdown,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isFiltered
                        ? const Color(0xFFFFF3E0)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFiltered
                          ? AppColors.cafePrimary
                          : AppColors.cafeBorder,
                      width: isFiltered ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list_rounded,
                          size: 16,
                          color: isFiltered
                              ? AppColors.cafePrimary
                              : AppColors.cafeSubtext),
                      const SizedBox(width: 8),
                      Text(
                        _selectedFilter == 'All'
                            ? 'All Drinks'
                            : '${_drinkEmoji[_selectedFilter]} $_selectedFilter',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isFiltered
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isFiltered
                              ? AppColors.cafePrimary
                              : AppColors.cafeText,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          color: isFiltered
                              ? AppColors.cafePrimary
                              : AppColors.cafeSubtext),
                    ],
                  ),
                ),
              ),
            ),

            // List
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        _selectedFilter == 'All'
                            ? 'No entries yet!\nTap + to add one.'
                            : 'No $_selectedFilter entries yet!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 15, color: AppColors.cafeSubtext),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final c = _filtered[index];
                        return GestureDetector(
                          onTap: () => _openDetailPopup(c),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.cafeBorder),
                            ),
                            child: Row(
                              children: [
                                // Photo or emoji
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.cafeBorder,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: c.photoPath != null
                                      ? Image.file(
                                          File(c.photoPath!),
                                          fit: BoxFit.cover,
                                        )
                                      : Center(
                                          child: Text(
                                            _drinkEmoji[c.drinkType] ?? '☕',
                                            style: const TextStyle(
                                                fontSize: 22),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),

                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(c.drinkName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.cafeText,
                                          )),
                                      const SizedBox(height: 2),
                                      Text(c.cafeName,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.cafeSubtext,
                                          )),
                                      Text(
                                        '${_drinkEmoji[c.drinkType] ?? '☕'} ${c.drinkType}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.cafeSubtext,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Rating & price
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(_stars(c.rating),
                                        style: const TextStyle(
                                            fontSize: 11)),
                                    const SizedBox(height: 3),
                                    Text(
                                      c.price != null &&
                                              c.price!.isNotEmpty
                                          ? '₱${c.price}'
                                          : '—',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.cafeSubtext,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.cafeBorder,
                                    size: 16),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPopup,
        backgroundColor: AppColors.cafePrimary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.cafeSubtext,
            )),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.cafeSubtext)),
      ],
    );
  }
}