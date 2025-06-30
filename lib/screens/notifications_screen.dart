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
  final List<String> _filters = ['All', 'Likes', 'Comment', 'Follow', 'Purchases'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firestoreService.markAllNotificationsAsRead();
    });
  }

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
            // --- PERUBAHAN DI SINI: Lebar maksimal diubah menjadi 1200 ---
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
                final filteredNotifs = allNotifs.where((doc) {
                  final type = doc['type'] as String;
                  switch (_selectedFilter) {
                    case 'Likes':
                      return type == 'like';
                    case 'Comment':
                      return type == 'comment';
                    case 'Follow':
                      return type == 'follow';
                    case 'Purchases':
                      return type == 'purchase';
                    case 'All':
                    default:
                      return true;
                  }
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
                      child: Text(
                        "Notification",
                        style: GoogleFonts.lora(
                            fontSize: 32, fontWeight: FontWeight.bold),
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
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              itemCount: filteredNotifs.length,
                              itemBuilder: (context, index) {
                                final data = filteredNotifs[index].data() as Map<String, dynamic>;
                                return _buildNotificationItem(data);
                              },
                              separatorBuilder: (context, index) => const Divider(),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
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
              style: GoogleFonts.lora(
                  fontSize: 32, fontWeight: FontWeight.bold),
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
            child: Center(
                child: Text("You have no notifications yet."))),
      ],
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> data) {
    final type = data['type'];
    final fromUserName = data['fromUserName'] ?? 'Someone';
    final noteTitle = data['noteTitle'] ?? '';
    final message = data['message'] as String?;
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final bool isRead = data['isRead'] ?? true;

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
        description = message ?? 'There was a transaction related to "$noteTitle".';
        break;
      default:
        title = 'New Notification';
        description = 'You have a new activity.';
    }

    return InkWell(
      onTap: () {
        if (data['noteId'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(noteId: data['noteId']),
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
                style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM d, yyyy  HH:mm').format(timestamp),
                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}