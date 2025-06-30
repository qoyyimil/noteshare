import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/delete_confirmation_dialog.dart';

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

  String? _replyingToCommentId;
  String? _replyingToUserFullName;
  String? _currentUserFullName;
  bool _isLoadingFullName = false;

  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color subtleTextColor = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserFullName();
  }

  Future<void> _fetchCurrentUserFullName() async {
    if (widget.currentUser == null) return;
    setState(() => _isLoadingFullName = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser!.uid)
          .get();
      setState(() {
        _currentUserFullName = doc.data()?['fullName'] ?? 'User';
        _isLoadingFullName = false;
      });
    } catch (e) {
      setState(() {
        _currentUserFullName = 'User';
        _isLoadingFullName = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty ||
        widget.currentUser == null ||
        _currentUserFullName == null ||
        _isLoadingFullName) return;

    try {
      await widget.firestoreService.addComment(
        noteId: widget.noteId,
        text: _commentController.text.trim(),
        userId: widget.currentUser!.uid,
        userFullName: _currentUserFullName!,
        parentCommentId: _replyingToCommentId,
      );

      _commentController.clear();
      setState(() {
        _replyingToCommentId = null;
        _replyingToUserFullName = null;
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment: $e')),
      );
    }
  }

  void _startReply(String commentId, String userFullName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserFullName = userFullName;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserFullName = null;
    });
    FocusScope.of(context).unfocus();
  }

  void _showDeleteCommentDialog(String commentId) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        onDelete: () async {
          try {
            Navigator.of(context).pop();
            await widget.firestoreService.deleteComment(widget.noteId, commentId);
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
            final commentReplies = (replies[comment.id] ?? [])
              ..sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTimestamp = (aData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                final bTimestamp = (bData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                return aTimestamp.compareTo(bTimestamp);
              });
            return _buildCommentTree(comment, commentReplies);
          },
          separatorBuilder: (context, index) => const Divider(height: 32),
        ),
      ],
    );
  }

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
    final String displayFullName = _currentUserFullName ?? '';
    final String firstLetter = displayFullName.isNotEmpty
        ? displayFullName[0].toUpperCase()
        : 'U';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: primaryBlue,
          child: Text(
            firstLetter,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_replyingToCommentId != null)
                Chip(
                  label: Text('Replying to ${_replyingToUserFullName ?? ''}'),
                  onDeleted: _cancelReply,
                  backgroundColor: Colors.blue.shade50,
                  deleteIconColor: Colors.blue.shade700,
                ),
              TextField(
                focusNode: _commentFocusNode,
                controller: _commentController,
                maxLines: null,
                enabled: !_isLoadingFullName,
                decoration: InputDecoration(
                  hintText: _isLoadingFullName ? 'Loading...' : 'Write a comment...',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}), // agar tombol Send update state
              ),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: (!_isLoadingFullName &&
                          _commentController.text.trim().isNotEmpty &&
                          _currentUserFullName != null)
                      ? _postComment
                      : null,
                  child: Text('Send', style: GoogleFonts.lato(color: primaryBlue)),
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
    final String userFullName = data['fullName'] ?? 'Anonymous User';
    final String firstLetter =
        userFullName.isNotEmpty ? userFullName[0].toUpperCase() : 'A';
    final String commentUserId = data['userId'] ?? '';
    final bool isMyComment = widget.currentUser?.uid == commentUserId;

    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    String formattedTime = 'Seconds ago';
    if (timestamp != null) {
      final Duration diff = DateTime.now().difference(timestamp);
      if (diff.inSeconds < 60) {
        formattedTime = '${diff.inSeconds} seconds ago';
      } else if (diff.inMinutes < 60) {
        formattedTime = '${diff.inMinutes} minutes ago';
      } else if (diff.inHours < 24) {
        formattedTime = '${diff.inHours} hours ago';
      } else {
        formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(timestamp);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: primaryBlue,
            child: Text(
              firstLetter,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userFullName,
                      style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(width: 8),
                    Text('• $formattedTime',
                        style: GoogleFonts.lato(color: subtleTextColor)),
                    const Spacer(),
                    if (isMyComment)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz,
                            color: subtleTextColor, size: 20),
                        onSelected: (value) {
                          if (value == 'delete_comment') {
                            _showDeleteCommentDialog(comment.id);
                          }
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
                GestureDetector(
                  onTap: () => _startReply(comment.id, userFullName),
                  child: Text(
                    'Reply',
                    style: GoogleFonts.lato(
                      color: primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}