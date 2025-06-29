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
import 'package:noteshare/screens/public_profile.dart';
import 'package:provider/provider.dart';
import 'package:noteshare/screens/profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // --- State for Search & Filter ---
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
    'For You', 'General', 'Physics', 'Mathematics', 'History', 'Biology', 'Chemistry'
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
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onSearchTabSelected(String tabName) {
    setState(() {
      _activeSearchTab = tabName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: HomeAppBar(
        searchController: _searchController,
        searchKeyword: _searchKeyword,
        onClearSearch: _clearSearch,
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
                            categories: _categories,
                            selectedCategory: _selectedCategory,
                            onCategorySelected: _onCategorySelected,
                            primaryBlue: primaryBlue,
                            subtleTextColor: subtleTextColor,
                          )
                        : SearchTabs(
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
    );
  }

  // --- CORRECTED PATTERN FOR STREAMBUILDER ---
  Widget _buildNotesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getPublicNotesStream(),
      builder: (context, snapshot) {
        // 1. Handle connection state first
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // 2. Handle errors
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        // 3. Handle case where there's no data, but no error
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("There are no notes in this category."));
        }

        // 4. If everything is fine, build the list
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

  Widget _buildSearchNotesList() {
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
            return const Center(child: Text("No notes found."));
          }

          final filteredNotes = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toLowerCase();
            final content = (data['content'] ?? '').toLowerCase();
            final userEmail = (data['userEmail'] ?? '').toLowerCase();
            return title.contains(_searchKeyword) ||
                content.contains(_searchKeyword) ||
                userEmail.contains(_searchKeyword);
          }).toList();

          if (filteredNotes.isEmpty) {
            return const Center(child: Text("No matching notes found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredNotes.length,
            itemBuilder: (context, index) => NoteCard(
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
           if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          final filteredUsers = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final fullName = (data['fullName'] ?? '').toLowerCase();
            final userName = (data['userName'] ?? '').toLowerCase();
            return fullName.contains(_searchKeyword) ||
                userName.contains(_searchKeyword);
          }).toList();

          if (filteredUsers.isEmpty) {
            return const Center(child: Text("Users not found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final userData = filteredUsers[index].data() as Map<String, dynamic>;
              final userId = filteredUsers[index].id;
              final userName = userData['fullName'] ?? userData['No Name'];

              return PeopleCard(
                data: userData,
                primaryBlue: primaryBlue,
                textColor: textColor,
                subtleTextColor: subtleTextColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicProfileScreen(
                        userId: userId,
                        userName: userName,
                      ),
                    ),
                  );
                },
              );
            },
            itemCount: filteredUsers.length,
          );
        });
  }
}
