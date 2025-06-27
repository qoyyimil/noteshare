import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/delete_confirmation_dialog.dart'; // Import dialog konfirmasi hapus

class CommentSection extends StatefulWidget {
  final String noteId;
  final FirestoreService firestoreService;
  final User? currentUser;
  final List<QueryDocumentSnapshot> comments;

  const CommentSection({
    super.key,
    required this.noteId,
    required this.firestoreService,
    required this.currentUser,
    required this.comments,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  // State untuk melacak balasan
  String? _replyingToCommentId;
  String? _replyingToUserEmail;

  // -- Warna dari Desain (dari HomeScreen, agar konsisten) --
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color subtleTextColor = Color(0xFF6B7280);

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _postComment() {
    if (_commentController.text.trim().isEmpty || widget.currentUser == null)
      return;

    widget.firestoreService.addComment(
      noteId: widget.noteId,
      text: _commentController.text,
      userId: widget.currentUser!.uid,
      userEmail: widget.currentUser!.email ?? 'Anonymous User',
      // Kirim parentId jika sedang membalas
      parentCommentId: _replyingToCommentId,
    );

    // Reset state setelah mengirim
    _commentController.clear();
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserEmail = null;
    });
    FocusScope.of(context).unfocus();
  }

  void _startReply(String commentId, String userEmail) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserEmail = userEmail;
    });
    // Fokus ke input field
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserEmail = null;
    });
    FocusScope.of(context).unfocus();
  }

  // --- FUNGSI BARU: Menampilkan dialog konfirmasi hapus komentar ---
  void _showDeleteCommentDialog(String commentId) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        onDelete: () async {
          try {
            Navigator.of(context).pop(); // Close dialog
            await widget.firestoreService
                .deleteComment(widget.noteId, commentId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Successfully deleted comment'),
                  backgroundColor: Colors.green),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to delete comment: $e'),
                  backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Proses data untuk memisahkan komentar dan balasan ---
    final topLevelComments = <QueryDocumentSnapshot>[];
    final replies = <String, List<QueryDocumentSnapshot>>{};

    for (var comment in widget.comments) {
      final data = comment.data() as Map<String, dynamic>;
      final parentId = data['parentCommentId'] as String?;

      if (parentId == null) {
        topLevelComments.add(comment);
      } else {
        (replies[parentId] ??= []).add(comment);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments (${widget.comments.length})',
          style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildCommentInputField(),
        const SizedBox(height: 32),
        // Sort top-level comments by timestamp for consistent display
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topLevelComments.length,
          itemBuilder: (context, index) {
            final comment = topLevelComments[index];
            // Sort replies for each top-level comment
            final commentReplies = (replies[comment.id] ?? [])
              ..sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTimestamp = (aData['timestamp'] as Timestamp).toDate();
                final bTimestamp = (bData['timestamp'] as Timestamp).toDate();
                return aTimestamp.compareTo(bTimestamp);
              });
            return _buildCommentTree(comment, commentReplies);
          },
          separatorBuilder: (context, index) => const Divider(height: 32),
        ),
      ],
    );
  }

  // Widget untuk menampilkan pohon komentar (induk + balasan)
  Widget _buildCommentTree(
      DocumentSnapshot comment, List<DocumentSnapshot> replies) {
    return Column(
      children: [
        _buildCommentTile(comment),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: replies.length,
              itemBuilder: (context, index) =>
                  _buildCommentTile(replies[index]),
              separatorBuilder: (context, index) => const SizedBox(height: 16),
            ),
          )
      ],
    );
  }

  Widget _buildCommentInputField() {
    // Get current user's email first letter for their avatar
    final String currentUserEmail = widget.currentUser?.email ?? 'U';
    final String firstLetter =
        currentUserEmail.isNotEmpty ? currentUserEmail[0].toUpperCase() : 'U';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: primaryBlue, // Use primaryBlue for consistency
          child: Text(
            firstLetter,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16), // Adjust font size as needed
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Menampilkan chip jika sedang membalas ---
              if (_replyingToCommentId != null)
                Chip(
                  label: Text('Replying to @${_replyingToUserEmail ?? ''}'),
                  onDeleted: _cancelReply,
                  backgroundColor: Colors.blue.shade50,
                  deleteIconColor: Colors.blue.shade700,
                ),
              TextField(
                focusNode: _commentFocusNode,
                controller: _commentController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  border: InputBorder.none,
                ),
              ),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _postComment,
                  child: Text('Send',
                      style: GoogleFonts.lato(color: primaryBlue)),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentTile(DocumentSnapshot comment) {
    final data = comment.data() as Map<String, dynamic>;
    final String userEmail = data['userEmail'] ?? 'Anonymous User';
    final String firstLetter = userEmail.isNotEmpty
        ? userEmail[0].toUpperCase()
        : 'P'; // Default to 'P' for Pengguna
    final String commentUserId =
        data['userId'] ?? ''; // ID pengguna yang membuat komentar
    final bool isMyComment = widget.currentUser?.uid ==
        commentUserId; // Cek apakah komentar ini milik pengguna saat ini

    // Get timestamp for comment
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    // Format timestamp relative to now
    String formattedTime = 'Seconds ago'; // Default value
    if (timestamp != null) {
      final Duration diff = DateTime.now().difference(timestamp);
      if (diff.inSeconds < 60) {
        formattedTime = '${diff.inSeconds} seconds ago';
      } else if (diff.inMinutes < 60) {
        formattedTime = '${diff.inMinutes} minutes ago';
      } else if (diff.inHours < 24) {
        formattedTime = '${diff.inHours} hours ago';
      } else if (diff.inDays < 7) {
        formattedTime = '${diff.inDays} days ago';
      } else {
        formattedTime = DateFormat('d MMM yyyy', 'id_ID')
            .format(timestamp); // Fallback for older comments
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: primaryBlue, // Use primaryBlue for consistency
          child: Text(
            firstLetter,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16), // Adjust font size as needed
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    userEmail,
                    style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text('• $formattedTime',
                      style: GoogleFonts.lato(color: subtleTextColor)),
                  const Spacer(), // Tambahkan Spacer
                  // --- Menu Opsi Komentar (Hanya Tampil Jika Komentar Milik Pengguna) ---
                  if (isMyComment)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz,
                          color: subtleTextColor, size: 20),
                      onSelected: (value) {
                        if (value == 'delete_comment') {
                          _showDeleteCommentDialog(comment.id);
                        }
                        // Tambahkan opsi lain di sini jika diperlukan
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'delete_comment',
                          child: Text('Delete Comment',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data['text'] ?? '',
                style: GoogleFonts.lato(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 8),
              // --- Tombol Balas ---
              TextButton.icon(
                icon: const Icon(Icons.reply_outlined, size: 18),
                label: const Text('Reply'),
                style: TextButton.styleFrom(
                    foregroundColor: subtleTextColor, padding: EdgeInsets.zero),
                onPressed: () => _startReply(comment.id, userEmail),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
