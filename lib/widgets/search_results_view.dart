import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:noteshare/providers/search_provider.dart';
import 'package:noteshare/screens/my_coins_screen.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/home/note_card.dart';
import 'package:noteshare/widgets/home/people_card.dart';
import 'package:noteshare/widgets/home/search_tabs.dart';
import 'package:provider/provider.dart';
import 'package:noteshare/widgets/home/public_profile_screen.dart';
import 'package:noteshare/screens/note_detail_screen.dart';

class SearchResultsView extends StatelessWidget {
  const SearchResultsView({super.key});

  void _showPurchaseConfirmationDialog(
      BuildContext context, Map<String, dynamic> data, String docId) {
    final int price = data['coinPrice'] ?? 0;
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Unlock Premium Note"),
        content: Text("Do you want to spend $price coins to unlock this note?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ElevatedButton(
            child: const Text("Unlock"),
            onPressed: () async {
              if (currentUser == null) return;

              Navigator.of(dialogContext).pop();

              final result =
                  await firestoreService.purchaseNote(currentUser.uid, docId);

              if (result == "Purchase successful!") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NoteDetailScreen(noteId: docId)),
                );
              } else if (result == "Not enough coins!") {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Insufficient Coins"),
                    content: const Text(
                        "You don't have enough coins. Would you like to top up?"),
                    actions: [
                      TextButton(
                        child: const Text("Cancel"),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      ElevatedButton(
                        child: const Text("Top Up Now"),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MyCoinsScreen()));
                        },
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result), backgroundColor: Colors.red));
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleNoteTap(
      BuildContext context, Map<String, dynamic> data, String docId) {
    final bool isPremium = data['isPremium'] ?? false;
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String currentUserId = currentUser?.uid ?? '';
    final List purchasedBy = data['purchasedBy'] ?? [];
    final bool hasPurchased = purchasedBy.contains(currentUserId);
    final bool isOwner = data['ownerId'] == currentUserId;

    Provider.of<SearchProvider>(context, listen: false).clearSearch();

    if (!isPremium || isOwner || hasPurchased) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => NoteDetailScreen(noteId: docId)),
      );
    } else {
      _showPurchaseConfirmationDialog(context, data, docId);
    }
  }


  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);
    const Color primaryBlue = Color(0xFF3B82F6);
    const Color textColor = Color(0xFF1F2937);
    const Color subtleTextColor = Color(0xFF6B7280);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
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
        ),
      ),
    );
  }

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
            itemBuilder: (context, index) {
              final noteDoc = filteredNotes[index];
              final noteData = noteDoc.data() as Map<String, dynamic>;

              return NoteCard(
                docId: noteDoc.id,
                data: noteData,
                firestoreService: firestoreService,
                primaryBlue: primaryBlue,
                textColor: textColor,
                subtleTextColor: subtleTextColor,
                onTap: () {
                  Provider.of<SearchProvider>(context, listen: false)
                      .clearSearch();
                  _handleNoteTap(context, noteData, noteDoc.id);
                },
              );
            },
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
            itemCount: filteredUsers.length,
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
                  Provider.of<SearchProvider>(context, listen: false)
                      .clearSearch();
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
          );
        });
  }
}