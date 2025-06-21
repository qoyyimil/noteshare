import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noteshare/services/firestore_service.dart';

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

  void _postComment() {
    if (_commentController.text.trim().isEmpty || widget.currentUser == null) return;
    
    widget.firestoreService.addComment(
      noteId: widget.noteId,
      text: _commentController.text,
      userId: widget.currentUser!.uid,
      userEmail: widget.currentUser!.email ?? 'Pengguna Anonim',
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
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topLevelComments.length,
          itemBuilder: (context, index) {
            final comment = topLevelComments[index];
            final commentReplies = replies[comment.id] ?? [];
            return _buildCommentTree(comment, commentReplies);
          },
          separatorBuilder: (context, index) => const Divider(height: 32),
        ),
      ],
    );
  }
  
  // Widget untuk menampilkan pohon komentar (induk + balasan)
  Widget _buildCommentTree(DocumentSnapshot comment, List<DocumentSnapshot> replies) {
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
              itemBuilder: (context, index) => _buildCommentTile(replies[index]),
              separatorBuilder: (context, index) => const SizedBox(height: 16),
            ),
          )
      ],
    );
  }

  Widget _buildCommentInputField() {
    const Color primaryBlue = Color(0xFF3B82F6);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(backgroundColor: primaryBlue),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Menampilkan chip jika sedang membalas ---
              if (_replyingToCommentId != null)
                Chip(
                  label: Text('Membalas @${_replyingToUserEmail ?? ''}'),
                  onDeleted: _cancelReply,
                  backgroundColor: Colors.blue.shade50,
                  deleteIconColor: Colors.blue.shade700,
                ),
              TextField(
                focusNode: _commentFocusNode,
                controller: _commentController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Tuliskan pemikiran Anda...',
                  border: InputBorder.none,
                ),
              ),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _postComment,
                  child: Text('Kirim', style: GoogleFonts.lato(color: primaryBlue)),
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
    const Color subtleTextColor = Color(0xFF6B7280);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(backgroundColor: Colors.grey),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    data['userEmail'] ?? 'Pengguna Anonim',
                    style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text('• 5 menit lalu', style: GoogleFonts.lato(color: subtleTextColor)),
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
                 label: const Text('Balas'),
                 style: TextButton.styleFrom(
                   foregroundColor: subtleTextColor,
                   padding: EdgeInsets.zero
                 ),
                 onPressed: () => _startReply(comment.id, data['userEmail']),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
