// lib/widgets/home/note_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/screens/note_detail_screen.dart';
import 'package:noteshare/screens/top_up_screen.dart';
import 'package:noteshare/services/firestore_service.dart';

class NoteCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final FirestoreService firestoreService;
  final Color primaryBlue;
  final Color textColor;
  final Color subtleTextColor;

  const NoteCard({
    super.key,
    required this.docId,
    required this.data,
    required this.firestoreService,
    required this.primaryBlue,
    required this.textColor,
    required this.subtleTextColor,
  });

  // --- NEW: LOGIC TO HANDLE NOTE TAP ---
  void _handleNoteTap(BuildContext context) {
    final bool isPremium = data['isPremium'] ?? false;
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String currentUserId = currentUser?.uid ?? '';
    final List purchasedBy = data['purchasedBy'] ?? [];
    final bool hasPurchased = purchasedBy.contains(currentUserId);
    final bool isOwner = data['ownerId'] == currentUserId;

    // If the note is not premium, or the user is the owner, or they have already purchased it
    if (!isPremium || isOwner || hasPurchased) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NoteDetailScreen(noteId: docId)),
      );
    } else {
      // If the note is premium and not yet purchased, show a confirmation dialog
      _showPurchaseConfirmationDialog(context);
    }
  }

  // --- NEW: PURCHASE CONFIRMATION DIALOG ---
  void _showPurchaseConfirmationDialog(BuildContext context) {
    final int price = data['coinPrice'] ?? 0;
    final User? currentUser = FirebaseAuth.instance.currentUser;

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
              
              Navigator.of(dialogContext).pop(); // Close confirmation dialog first
              
              final result = await firestoreService.purchaseNote(currentUser.uid, docId);

              if (result == "Purchase successful!") {
                // Navigate to the note detail screen after successful purchase
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NoteDetailScreen(noteId: docId)),
                );
              } else if (result == "Not enough coins!") {
                 showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Insufficient Coins"),
                      content: const Text("You don't have enough coins. Would you like to top up?"),
                      actions: [
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        ElevatedButton(
                          child: const Text("Top Up Now"),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const TopUpScreen()));
                          },
                        ),
                      ],
                    ),
                  );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result), backgroundColor: Colors.red)
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final likesCount = (data['likes'] as List<dynamic>? ?? []).length;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = timestamp != null ? DateFormat('d MMM', 'en_US').format(timestamp) : '';
    final String userFullName = data['fullName'] ?? 'User';
    final String firstLetter = userFullName.isNotEmpty ? userFullName[0].toUpperCase() : 'A';
    final bool isPremium = data['isPremium'] ?? false;

    return InkWell(
      onTap: () => _handleNoteTap(context), // Use the new handler function
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
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
                      // --- NEW: Show a premium icon ---
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
                            final isBookmarked = snapshot.data ?? false;
                            return Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: subtleTextColor);
                          },
                        ),
                        onPressed: () => firestoreService.toggleBookmark(docId),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.more_horiz, color: subtleTextColor),
                        onPressed: () { /* TODO: Implement more options */ },
                      ),
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
