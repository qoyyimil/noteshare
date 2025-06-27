import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchTabs extends StatelessWidget {
  final String activeSearchTab;
  final Function(String) onSearchTabSelected;
  final Color primaryBlue;
  final Color subtleTextColor;

  const SearchTabs({
    super.key,
    required this.activeSearchTab,
    required this.onSearchTabSelected,
    required this.primaryBlue,
    required this.subtleTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        children: [
          _buildSearchTabItem('Note'),
          _buildSearchTabItem('User'),
        ],
      ),
    );
  }

  Widget _buildSearchTabItem(String tabName) {
    final bool isActive = activeSearchTab == tabName;
    return InkWell(
      onTap: () => onSearchTabSelected(tabName),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: Text(
            tabName,
            style: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? primaryBlue : subtleTextColor,
            ),
          ),
        ),
      ),
    );
  }
}