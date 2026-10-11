// lib/Merchants_Screen/technicians_tab/widgets/category_filter_chips.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryFilterChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  static const List<String> categories = [
    'All',
    'AC Repair',
    'Electrician',
    'Plumber',
    'Mechanic',
    'Mason',
    'Carpenter',
    'Painter',
    'Appliance Repair',
    'Cleaning',
  ];

  const CategoryFilterChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory.toLowerCase() == cat.toLowerCase();

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(
                cat,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.indigo[900],
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(cat),
              backgroundColor: Colors.indigo[50],
              selectedColor: Colors.indigo,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.indigo : Colors.indigo.withValues(alpha: 0.2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
