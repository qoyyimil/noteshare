// File: lib/screens/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noteshare/providers/search_provider.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/home/category_tabs.dart';
import 'package:noteshare/widgets/home/home_app_bar.dart';
import 'package:noteshare/widgets/home/note_card.dart';
import 'package:noteshare/widgets/home/top_picks_sidebar.dart';
import 'package:noteshare/widgets/search_results_view.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // State untuk filter kategori, ini tetap lokal karena hanya relevan untuk HomeScreen.
  String _selectedCategory = 'For You';

  // -- UI Colors & Styles --
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color bgColor = Color(0xFFFFFFFF);
  static const Color sidebarBgColor = Color(0xFFF9FAFB);
  static const Color textColor = Color(0xFF1F2937);
  static const Color subtleTextColor = Color(0xFF6B7280);

  final List<String> _categories = [
    'For You', 'General', 'Physics', 'Mathematics', 'History', 'Biology', 'Chemistry'
  ];

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    
    // Sinkronkan text di controller dengan state di provider
    final searchProvider = Provider.of<SearchProvider>(context, listen: true);
    if (searchController.text != searchProvider.searchQuery) {
        searchController.text = searchProvider.searchQuery;
        searchController.selection = TextSelection.fromPosition(TextPosition(offset: searchController.text.length));
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: HomeAppBar(
        searchController: searchController,
        currentUser: currentUser,
        primaryBlue: primaryBlue,
        subtleTextColor: subtleTextColor,
        sidebarBgColor: sidebarBgColor, searchKeyword: '', onClearSearch: () {  },
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (searchProvider.searchQuery.isNotEmpty) {
            return SearchResultsView();
          }
          return child!;
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      CategoryTabs(
                        categories: _categories,
                        selectedCategory: _selectedCategory,
                        onCategorySelected: _onCategorySelected,
                        primaryBlue: primaryBlue,
                        subtleTextColor: subtleTextColor,
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      Expanded(
                        child: _buildNotesList(),
                      ),
                    ],
                  ),
                ),
                if (MediaQuery.of(context).size.width > 800)
                  SizedBox(
                    width: 350,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24.0, top: 16.0),
                      child: TopPicksSidebar(
                        firestoreService: firestoreService,
                        primaryBlue: primaryBlue,
                        textColor: textColor,
                        subtleTextColor: subtleTextColor,
                        sidebarBgColor: sidebarBgColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getPublicNotesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("There are no notes in this category."));
        }

        final notes = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _selectedCategory == 'For You' ||
              (data['category'] ?? '').toString().toLowerCase() == _selectedCategory.toLowerCase();
        }).toList();

        if (notes.isEmpty) {
          return const Center(child: Text("There are no notes in this category."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: notes.length,
          itemBuilder: (context, index) => NoteCard(
            docId: notes[index].id,
            data: notes[index].data() as Map<String, dynamic>,
            firestoreService: firestoreService,
            primaryBlue: primaryBlue,
            textColor: textColor,
            subtleTextColor: subtleTextColor,
          ),
        );
      },
    );
  }
}