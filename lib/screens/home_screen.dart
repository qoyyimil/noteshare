import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:noteshare/widgets/home/home_app_bar.dart';
import 'package:noteshare/widgets/home/category_tabs.dart';
import 'package:noteshare/widgets/home/search_tabs.dart';
import 'package:noteshare/widgets/home/note_card.dart';
import 'package:noteshare/widgets/home/people_card.dart';
import 'package:noteshare/widgets/home/top_picks_sidebar.dart';

import 'package:noteshare/auth/auth_gate.dart';
import 'package:noteshare/auth/auth_service.dart';
import 'package:noteshare/screens/create_note_screen.dart';
import 'package:noteshare/screens/my_bookmarks_screen.dart';
import 'package:noteshare/screens/my_notes_screen.dart';
import 'package:noteshare/screens/note_detail_screen.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // --- State untuk Search & Filter ---
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  String _activeSearchTab = 'Note';
  String _selectedCategory = 'For You';

  // -- UI Colors & Styles --
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color bgColor = Color(0xFFFFFFFF);
  static const Color sidebarBgColor = Color(0xFFF9FAFB);
  static const Color textColor = Color(0xFF1F2937);
  static const Color subtleTextColor = Color(0xFF6B7280);

  final List<String> _categories = [
    'For You',
    'General',
    'Physics',
    'Mathematics',
    'History',
    'Biology',
    'Chemistry'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchKeyword = _searchController.text.trim().toLowerCase();
      if (_searchKeyword.isNotEmpty && _activeSearchTab == 'user') {
        _activeSearchTab = 'Note';
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchKeyword = '';
      _activeSearchTab = 'Note';
    });
  }

  // Callback untuk CategoryTabs
  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  // Callback untuk SearchTabs
  void _onSearchTabSelected(String tabName) {
    setState(() {
      _activeSearchTab = tabName;
    });
  }

  // Callback untuk PopupMenuButton di AppBar
  void _onMenuItemSelected(String value, BuildContext context) {
    switch (value) {
      case 'notes':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const MyNotesScreen()));
        break;
      case 'library':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const MyBookmarksScreen()));
        break;
      case 'logout':
        final authService = Provider.of<AuthService>(context, listen: false);
        authService.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The feature "$value" is not available yet.')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: HomeAppBar(
        // Menggunakan widget HomeAppBar
        searchController: _searchController,
        searchKeyword: _searchKeyword,
        onClearSearch: _clearSearch,
        onMenuItemSelected: _onMenuItemSelected,
        currentUser: currentUser,
        primaryBlue: primaryBlue,
        subtleTextColor: subtleTextColor,
        sidebarBgColor: sidebarBgColor,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _searchKeyword.isEmpty
                        ? CategoryTabs(
                            // Menggunakan widget CategoryTabs
                            categories: _categories,
                            selectedCategory: _selectedCategory,
                            onCategorySelected: _onCategorySelected,
                            primaryBlue: primaryBlue,
                            subtleTextColor: subtleTextColor,
                          )
                        : SearchTabs(
                            // Menggunakan widget SearchTabs
                            activeSearchTab: _activeSearchTab,
                            onSearchTabSelected: _onSearchTabSelected,
                            primaryBlue: primaryBlue,
                            subtleTextColor: subtleTextColor,
                          ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    Expanded(
                      child: _searchKeyword.isEmpty
                          ? _buildNotesList()
                          : _activeSearchTab == 'Note'
                              ? _buildSearchNotesList()
                              : _buildSearchPeopleList(),
                    ),
                  ],
                ),
              ),
              if (MediaQuery.of(context).size.width > 800)
                Container(
                  width: 350,
                  padding: const EdgeInsets.only(left: 24.0, top: 16.0),
                  child: TopPicksSidebar(
                    // Menggunakan widget TopPicksSidebar
                    firestoreService: firestoreService,
                    primaryBlue: primaryBlue,
                    textColor: textColor,
                    subtleTextColor: subtleTextColor,
                    sidebarBgColor: sidebarBgColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Metode-metode yang mem-build daftar (list) akan tetap di HomeScreen ---
  // Karena mereka memiliki logika filtering berdasarkan state HomeScreen
  Widget _buildNotesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getPublicNotesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final notes = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _selectedCategory == 'For You' ||
              (data['category'] ?? '').toString().toLowerCase() ==
                  _selectedCategory.toLowerCase();
        }).toList();

        if (notes.isEmpty)
          return const Center(
              child: Text("There are no notes in this category."));

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: notes.length,
          itemBuilder: (context, index) => NoteCard(
            // Menggunakan widget NoteCard
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

  Widget _buildSearchNotesList() {
    return StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getPublicNotesStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final filteredNotes = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toLowerCase();
            final content = (data['content'] ?? '').toLowerCase();
            final userEmail = (data['userEmail'] ?? '').toLowerCase();
            return title.contains(_searchKeyword) ||
                content.contains(_searchKeyword) ||
                userEmail.contains(_searchKeyword);
          }).toList();

          if (filteredNotes.isEmpty)
            return const Center(child: Text("No matching notes found."));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredNotes.length,
            itemBuilder: (context, index) => NoteCard(
              // Menggunakan widget NoteCard
              docId: filteredNotes[index].id,
              data: filteredNotes[index].data() as Map<String, dynamic>,
              firestoreService: firestoreService,
              primaryBlue: primaryBlue,
              textColor: textColor,
              subtleTextColor: subtleTextColor,
            ),
          );
        });
  }

  Widget _buildSearchPeopleList() {
    return StreamBuilder<QuerySnapshot>(
        stream: firestoreService.users.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final filteredUsers = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final email = (data['email'] ?? '').toLowerCase();
            return email.contains(_searchKeyword);
          }).toList();

          if (filteredUsers.isEmpty)
            return const Center(child: Text("Users not found."));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) => PeopleCard(
              // Menggunakan widget PeopleCard
              data: filteredUsers[index].data() as Map<String, dynamic>,
              primaryBlue: primaryBlue,
              textColor: textColor,
              subtleTextColor: subtleTextColor,
            ),
          );
        });
  }
}
