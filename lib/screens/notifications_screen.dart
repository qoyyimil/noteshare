// lib/screens/notifications_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/screens/note_detail_screen.dart';
import 'package:noteshare/services/firestore_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedFilter = 'All';

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
              case 'Purchases': // Filter baru
                return type == 'purchase';
              case 'All':
              default:
                return true;
            }
          }).toList();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Notification",
                  style: GoogleFonts.lato(
                      fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildFilterTabs(),
                const SizedBox(height: 8),
                const Divider(),
                Expanded(
                  child: filteredNotifs.isEmpty
                      ? const Center(child: Text("No notifications in this category."))
                      : ListView.separated(
                          padding: const EdgeInsets.only(top: 16),
                          itemCount: filteredNotifs.length,
                          itemBuilder: (context, index) {
                            final data = filteredNotifs[index].data() as Map<String, dynamic>;
                            return _buildNotificationItem(data, filteredNotifs[index].id);
                          },
                          separatorBuilder: (context, index) => const Divider(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Padding(
       padding: const EdgeInsets.symmetric(horizontal: 24.0),
       child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              "Notification",
              style: GoogleFonts.lato(
                  fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildFilterTabs(),
            const SizedBox(height: 8),
            const Divider(),
            const Expanded(
              child: Center(
                child: Text("You have no notifications yet.")
              )
            ),
          ],
        ),
    );
  }

  Widget _buildFilterTabs() {
    // Menambahkan 'Purchases' ke dalam daftar filter
    return Row(
      children: ['All', 'Likes', 'Comment', 'Follow', 'Purchases']
          .map((filter) => _buildFilterButton(filter))
          .toList(),
    );
  }

  Widget _buildFilterButton(String title) {
    final bool isActive = _selectedFilter == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = title;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 24.0),
        child: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF3B82F6) : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> data, String docId) {
    final type = data['type'];
    final fromUserName = data['fromUserName'] ?? 'Someone';
    final noteTitle = data['noteTitle'] ?? '';
    final message = data['message'] as String?; // Ambil pesan kustom
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final bool isRead = data['isRead'] ?? true;

    String title;
    String description;
    
    // Membuat pesan notifikasi yang lebih sesuai
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
      case 'purchase': // Penanganan untuk tipe notifikasi baru
        title = 'Purchase Information';
        description = message ?? 'There was a transaction related to "$noteTitle".'; // Gunakan pesan kustom
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
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat.yMMMd().add_jm().format(timestamp),
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
