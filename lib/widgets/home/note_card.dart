import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/screens/my_coins_screen.dart';
import 'package:noteshare/screens/note_detail_screen.dart';
import 'package:noteshare/services/firestore_service.dart';

class NoteCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final FirestoreService firestoreService;
  final Color primaryBlue;
  final Color textColor;
  final Color subtleTextColor;
  final VoidCallback? onTap;
  final bool isBookmarked;
  final bool showBottomBorder;

  const NoteCard({
    super.key,
    required this.docId,
    required this.data,
    required this.firestoreService,
    required this.primaryBlue,
    required this.textColor,
    required this.subtleTextColor,
    this.onTap,
    this.isBookmarked = false,
    this.showBottomBorder = true, 
  });

  @override
  Widget build(BuildContext context) {
    final likesCount = (data['likes'] as List<dynamic>? ?? []).length;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = timestamp != null ? DateFormat('d MMM', 'en_US').format(timestamp) : '';
    final String userFullName = data['fullName'] ?? 'User';
    final String firstLetter = userFullName.isNotEmpty ? userFullName[0].toUpperCase() : 'A';
    final bool isPremium = data['isPremium'] ?? false;

    return InkWell(
      onTap: onTap ??
          () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NoteDetailScreen(noteId: docId)),
              ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        decoration: BoxDecoration(
          border: showBottomBorder
              ? const Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: primaryBlue,
                        child: Text(
                          firstLetter,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(userFullName, style: GoogleFonts.lato(fontSize: 18, color: textColor)),
                      if (isPremium)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.workspace_premium, color: Colors.amber.shade700, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data['title'] ?? 'Untitled',
                    style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['content'] ?? 'No content',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(fontSize: 16, color: subtleTextColor, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(formattedDate, style: GoogleFonts.lato(fontSize: 13, color: subtleTextColor)),
                      const SizedBox(width: 16),
                      Icon(Icons.favorite_border, size: 16, color: subtleTextColor),
                      const SizedBox(width: 4),
                      Text('$likesCount', style: GoogleFonts.lato(fontSize: 13, color: subtleTextColor)),
                      const SizedBox(width: 16),
                      Icon(Icons.chat_bubble_outline, size: 16, color: subtleTextColor),
                      const SizedBox(width: 4),
                      StreamBuilder<QuerySnapshot>(
                        stream: firestoreService.getCommentsStream(docId),
                        builder: (context, commentSnapshot) {
                          final count = commentSnapshot.data?.docs.length ?? 0;
                          return Text(count.toString(), style: GoogleFonts.lato(fontSize: 13, color: subtleTextColor));
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: StreamBuilder<bool>(
                          stream: firestoreService.isNoteBookmarked(docId),
                          builder: (context, snapshot) {
                            final isBookmarkedByStream = snapshot.data ?? false;
                            final bool displayAsBookmarked = isBookmarked || isBookmarkedByStream;

                            return Icon(
                              displayAsBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: displayAsBookmarked ? primaryBlue : subtleTextColor,
                            );
                          },
                        ),
                        onPressed: () => firestoreService.toggleBookmark(docId),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ],
              ),
            ),
            if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    data['imageUrl'],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(width: 120, height: 120, color: Colors.grey[200]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}