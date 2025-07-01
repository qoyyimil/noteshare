import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/providers/search_provider.dart';
import 'package:noteshare/screens/note_detail_screen.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/home/category_tabs.dart';
import 'package:noteshare/widgets/home/home_app_bar.dart';
import 'package:noteshare/widgets/search_results_view.dart';
import 'package:provider/provider.dart';
import 'package:noteshare/screens/public_profile.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Likes',
    'Comment',
    'Follow',
    'Purchases'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HomeAppBar(
        searchController: _searchController,
        currentUser: _currentUser,
        primaryBlue: const Color(0xFF3B82F6),
        subtleTextColor: const Color(0xFF6B7280),
        sidebarBgColor: Colors.white,
        searchKeyword: '',
        onClearSearch: () {},
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (searchProvider.searchQuery.isNotEmpty) {
            return const SearchResultsView();
          }
          return child!;
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getNotificationsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final allNotifs = snapshot.data!.docs;

                if (_selectedFilter == 'Purchases') {
                  final purchaseNotifs = allNotifs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    return data['type'] == 'purchase';
                  }).toList();

                  return FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: _filterOnlyPremiumPurchases(purchaseNotifs),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _buildNotificationsList(snap.data!);
                    },
                  );
                }

                // Tab lain tetap
                final filteredNotifs = allNotifs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final type = data['type'] as String? ?? '';
                  switch (_selectedFilter) {
                    case 'Likes':
                      return type == 'like';
                    case 'Comment':
                      return type == 'comment';
                    case 'Follow':
                      return type == 'follow';
                    case 'All':
                    default:
                      return true;
                  }
                }).toList();

                return _buildNotificationsList(filteredNotifs);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<List<QueryDocumentSnapshot>> _filterOnlyPremiumPurchases(
      List<QueryDocumentSnapshot> notifs) async {
    List<QueryDocumentSnapshot> result = [];
    for (final notif in notifs) {
      final data = notif.data() as Map<String, dynamic>? ?? {};
      final noteId = data['noteId'];
      if (noteId == null) continue;
      final noteDoc = await FirebaseFirestore.instance
          .collection('notes')
          .doc(noteId)
          .get();
      if (noteDoc.exists && (noteDoc.data()?['isPremium'] ?? false)) {
        result.add(notif);
      }
    }
    return result;
  }

  Widget _buildNotificationsList(List<QueryDocumentSnapshot> filteredNotifs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
          child: Text(
            "Notification",
            style: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        CategoryTabs(
          categories: _filters,
          selectedCategory: _selectedFilter,
          onCategorySelected: (filter) {
            setState(() {
              _selectedFilter = filter;
            });
          },
          primaryBlue: const Color(0xFF3B82F6),
          subtleTextColor: Colors.grey.shade600,
        ),
        const Divider(height: 1),
        Expanded(
          child: filteredNotifs.isEmpty
              ? const Center(child: Text("No notifications in this category."))
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  itemCount: filteredNotifs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredNotifs[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    return _buildNotificationItem(data, notificationId: doc.id);
                  },
                  separatorBuilder: (context, index) => const Divider(),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
          child: Text(
            "Notification",
            style: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        CategoryTabs(
          categories: _filters,
          selectedCategory: _selectedFilter,
          onCategorySelected: (filter) {
            setState(() {
              _selectedFilter = filter;
            });
          },
          primaryBlue: const Color(0xFF3B82F6),
          subtleTextColor: Colors.grey.shade600,
        ),
        const Divider(height: 1),
        const Expanded(
            child: Center(child: Text("You have no notifications yet."))),
      ],
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> data,
      {required String notificationId}) {
    final type = data['type'] as String? ?? '';
    final fromUserName = data['fromUserName'] ?? 'Someone';
    final fromUserId = data['fromUserId']; // <-- Tambahkan ini
    final noteTitle = data['noteTitle']?.toString() ?? '';
    final message = data['message'] as String?;
    final Timestamp? timestampObj = data['timestamp'] as Timestamp?;
    final timestamp = timestampObj?.toDate() ?? DateTime.now();
    final bool isRead = data['isRead'] ?? true;
    final String? noteId = data['noteId']?.toString();

    String title;
    String description;

    switch (type) {
      case 'like':
        title = 'Your note received a like';
        description = '$fromUserName liked "$noteTitle"';
        break;
      case 'comment':
        title = 'New comment on your note';
        description = '$fromUserName commented on "$noteTitle"';
        break;
      case 'follow':
        title = 'You have a new follower';
        description = '$fromUserName started following you.';
        break;
      case 'purchase':
        title = 'Purchase Information';
        description =
            message ?? 'There was a transaction related to "$noteTitle".';
        break;
      default:
        title = 'New Notification';
        description = 'You have a new activity.';
    }

    return InkWell(
      onTap: () async {
        // Tandai sebagai sudah dibaca di Firestore
        if (!isRead) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('notifications')
                .doc(notificationId)
                .update({'isRead': true});
          }
        }
        if (type == 'follow' && fromUserId != null && fromUserId != '') {
          // Navigasi ke profil user publik (user yang follow)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PublicProfileScreen(
                userId: fromUserId,
              ),
            ),
          );
        } else if (noteId != null && noteId.isNotEmpty) {
          // Navigasi ke detail note untuk like, comment, purchases
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(noteId: noteId),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Opacity(
          opacity: isRead ? 0.6 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM d, yyyy  HH:mm').format(timestamp),
                style:
                    GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
