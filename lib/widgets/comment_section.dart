import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noteshare/services/firestore_service.dart';

class CommentSection extends StatefulWidget {
  final String noteId;
  final FirestoreService firestoreService;
  final User? currentUser;
  final List<QueryDocumentSnapshot> comments; // <-- Parameter baru

  const CommentSection({
    super.key,
    required this.noteId,
    required this.firestoreService,
    required this.currentUser,
    required this.comments, // <-- Diterima di sini
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();

  void _postComment() {
    if (_commentController.text.trim().isEmpty || widget.currentUser == null) return;
    widget.firestoreService.addComment(
      noteId: widget.noteId,
      text: _commentController.text,
      userId: widget.currentUser!.uid,
      userEmail: widget.currentUser!.email ?? 'Pengguna Anonim',
    );
    _commentController.clear();
    FocusScope.of(context).unfocus(); // Menutup keyboard
  }

  @override
  Widget build(BuildContext context) {
    // Warna dari desain
    const Color textColor = Color(0xFF1F2937);
    const Color subtleTextColor = Color(0xFF6B7280);
    const Color borderColor = Color(0xFFE5E7EB);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul
        Text(
          'Comments (${widget.comments.length})',
          style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 24),
        
        // Input field untuk komentar baru
        _buildCommentInputField(),
        
        const SizedBox(height: 32),
        
        // Daftar komentar
        ListView.separated(
          shrinkWrap: true, // Penting di dalam SingleChildScrollView
          physics: const NeverScrollableScrollPhysics(), // Agar tidak ada double scrolling
          itemCount: widget.comments.length,
          itemBuilder: (context, index) {
            var comment = widget.comments[index];
            return _buildCommentTile(comment);
          },
          separatorBuilder: (context, index) => const Divider(height: 32),
        ),
      ],
    );
  }

  Widget _buildCommentInputField() {
    const Color primaryBlue = Color(0xFF3B82F6);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         CircleAvatar(
          backgroundColor: primaryBlue,
          child: Text(
            widget.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'G',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              TextField(
                controller: _commentController,
                maxLines: null, // Mengizinkan multi-baris
                decoration: InputDecoration(
                  hintText: 'Tuliskan pemikiran Anda...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.lato(color: Colors.grey.shade500),
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
    var data = comment.data() as Map<String, dynamic>;
    const Color primaryBlue = Color(0xFF3B82F6);
    const Color subtleTextColor = Color(0xFF6B7280);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(backgroundColor: primaryBlue),
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
                  Text('• 15 menit lalu', style: GoogleFonts.lato(color: subtleTextColor)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data['text'] ?? '',
                style: GoogleFonts.lato(fontSize: 15, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.reply_outlined, size: 20, color: subtleTextColor),
                onPressed: () {
                  // TODO: Implement reply functionality
                },
              )
            ],
          ),
        ),
      ],
    );
  }
}
