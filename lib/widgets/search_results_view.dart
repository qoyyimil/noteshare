import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:noteshare/providers/search_provider.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/home/note_card.dart';
import 'package:noteshare/widgets/home/people_card.dart';
import 'package:noteshare/widgets/home/search_tabs.dart';
import 'package:provider/provider.dart';
import 'package:noteshare/widgets/home/public_profile_screen.dart';

class SearchResultsView extends StatelessWidget {
  const SearchResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);
    const Color primaryBlue = Color(0xFF3B82F6);
    const Color textColor = Color(0xFF1F2937);
    const Color subtleTextColor = Color(0xFF6B7280);

    return Column(
      children: [
        SearchTabs(
          activeSearchTab: searchProvider.activeTab,
          onSearchTabSelected: (tab) {
            Provider.of<SearchProvider>(context, listen: false)
                .setActiveTab(tab);
          },
          primaryBlue: primaryBlue,
          subtleTextColor: subtleTextColor,
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        Expanded(
          child: searchProvider.activeTab == 'Note'
              ? _buildSearchNotesList(searchProvider.searchQuery,
                  FirestoreService(), primaryBlue, textColor, subtleTextColor)
              : _buildSearchPeopleList(searchProvider.searchQuery,
                  FirestoreService(), primaryBlue, textColor, subtleTextColor),
        ),
      ],
    );
  }

  // Logika dari HomeScreen dipindahkan ke sini
  Widget _buildSearchNotesList(
      String keyword,
      FirestoreService firestoreService,
      Color primaryBlue,
      Color textColor,
      Color subtleTextColor) {
    return StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getPublicNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notes found."));
          }
          final filteredNotes = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toLowerCase();
            final content = (data['content'] ?? '').toLowerCase();
            // **PERUBAIKAN: Ganti userEmail dengan fullName**
            final authorName = (data['fullName'] ?? '').toLowerCase();

            return title.contains(keyword) ||
                content.contains(keyword) ||
                authorName.contains(keyword);
          }).toList();

          if (filteredNotes.isEmpty) {
            return const Center(
                child: Text("No matching notes or authors found."));
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

  Widget _buildSearchPeopleList(
      String keyword,
      FirestoreService firestoreService,
      Color primaryBlue,
      Color textColor,
      Color subtleTextColor) {
    return StreamBuilder<QuerySnapshot>(
        stream: firestoreService.users.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found."));
          }
          final filteredUsers = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final fullName = (data['fullName'] ?? '').toLowerCase();
            return fullName.contains(keyword);
          }).toList();
          if (filteredUsers.isEmpty) {
            return const Center(child: Text("Users not found."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final userData =
                  filteredUsers[index].data() as Map<String, dynamic>;
              final userId = filteredUsers[index].id;
              final userName = userData['fullName'] ?? 'No Name';
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
                          userId: userId, userName: userName),
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
