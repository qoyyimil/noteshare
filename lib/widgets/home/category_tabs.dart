import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryTabs extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final Color primaryBlue;
  final Color subtleTextColor;

  const CategoryTabs({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.primaryBlue,
    required this.subtleTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final bool isActive = selectedCategory == category;
          return InkWell(
            onTap: () => onCategorySelected(category),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  category,
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? primaryBlue : subtleTextColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}