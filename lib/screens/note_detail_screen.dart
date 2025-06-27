import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/screens/create_note_screen.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/comment_section.dart';
import 'package:noteshare/widgets/delete_confirmation_dialog.dart';
import 'package:noteshare/widgets/report_dialog.dart';
import 'package:noteshare/widgets/share_dialog.dart';
import 'package:noteshare/widgets/home/home_app_bar.dart';

class NoteDetailScreen extends StatefulWidget {
  final String noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();

  // -- Warna dari Desain --
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color textColor = Color(0xFF1F2937);
  static const Color subtleTextColor = Color(0xFF6B7280);
  static const Color backgroundColor = Color(0xFFF9FAFB);

  // -- Dialog Functions --
  void _showShareDialog(BuildContext context, String title, bool isOwner) {
    final String url =
        "https://noteshare-86d6d.web.app/#/note/${widget.noteId}";
    showDialog(
      context: context,
      builder: (context) => ShareDialog(
        noteId: widget.noteId,
        noteTitle: title,
        shareUrl: url,
        isOwner: isOwner,
      ),
    );
  }

  void _showReportDialog(String noteOwnerId) {
    if (_currentUser == null) return;
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        noteId: widget.noteId,
        noteOwnerId: noteOwnerId,
        reporterId: _currentUser!.uid,
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: 'Delete Note',
        content:
            'Are you sure you want to delete this note? This action cannot be cancel.',
        confirmText: 'Delete',
        onDelete: () async {
          try {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            await _firestoreService.deleteNote(widget.noteId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Note succesfully deleted!.'),
                  backgroundColor: Colors.green),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to delete note: $e'),
                  backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onClearSearch() {
    _searchController.clear();
  }

  void _onMenuItemSelected(String value, BuildContext context) {
    switch (value) {
      case 'profile':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile feature not available yet.')),
        );
        break;
      case 'library':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Library feature not available yet.')),
        );
        break;
      case 'notes':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('My Notes feature not available yet.')),
        );
        break;
      case 'logout':
        Navigator.pop(context);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The feature "$value" is not available yet.')),
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Update UI when search text changes
    });
    // Tidak perlu load ownerId di initState, ownerId diambil dari data note di builder
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: HomeAppBar(
        searchController: _searchController,
        searchKeyword: _searchController.text,
        onClearSearch: _onClearSearch,
        onMenuItemSelected: _onMenuItemSelected,
        currentUser: _currentUser,
        primaryBlue: primaryBlue,
        subtleTextColor: subtleTextColor,
        sidebarBgColor: backgroundColor,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getNoteStream(widget.noteId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text("No notes found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final bool isMyNote = data['ownerId'] == _currentUser?.uid;
          final commentStream =
              _firestoreService.getCommentsStream(widget.noteId);

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNoteTitle(data),
                      const SizedBox(height: 16),
                      _buildAuthorHeader(data, isMyNote),
                      const SizedBox(height: 24),
                      _buildNoteActions(data, isMyNote),
                      const SizedBox(height: 24),
                      _buildNoteContent(data),
                      const SizedBox(height: 24),
                      _buildTagsSection(data),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 32),
                      _buildAuthorFooter(data, isMyNote),
                      const SizedBox(height: 48),
                      StreamBuilder<QuerySnapshot>(
                          stream: commentStream,
                          builder: (context, commentSnapshot) {
                            final comments = commentSnapshot.data?.docs ?? [];
                            return CommentSection(
                              noteId: widget.noteId,
                              firestoreService: _firestoreService,
                              currentUser: _currentUser,
                              comments: comments,
                            );
                          }),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoteTitle(Map<String, dynamic> data) {
    return Text(
      data['title'] ?? 'Untitled',
      style: GoogleFonts.lora(
          fontSize: 42, fontWeight: FontWeight.bold, color: textColor),
    );
  }

  Widget _buildAuthorHeader(Map<String, dynamic> data, bool isMyNote) {
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final formattedTime = timestamp != null
        ? DateFormat.yMMMMd('id_ID').add_jm().format(timestamp)
        : 'Seconds ago';

    final String userEmail = data['userEmail'] ?? 'Anonymous User';
    final String firstLetter =
        userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'P';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: primaryBlue,
          child: Text(
            firstLetter, // Menampilkan huruf pertama email
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userEmail,
                style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text(formattedTime,
                style: GoogleFonts.lato(color: subtleTextColor, fontSize: 14)),
          ],
        ),
        const Spacer(),
        if (!isMyNote)
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Follow'),
          ),
      ],
    );
  }

  Widget _buildNoteActions(Map<String, dynamic> data, bool isMyNote) {
    final List<dynamic> likes = data.containsKey('likes') ? data['likes'] : [];
    final bool isLikedByMe = likes.contains(_currentUser?.uid);
    final int likeCount = likes.length;

    return Row(
      children: [
        _actionButton(isLikedByMe ? Icons.favorite : Icons.favorite_border,
            '$likeCount', isLikedByMe ? Colors.redAccent : subtleTextColor, () {
          if (_currentUser != null) {
            _firestoreService.toggleLike(
                widget.noteId, _currentUser!.uid, isLikedByMe);
          }
        }),
        const SizedBox(width: 24),
        StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getCommentsStream(widget.noteId),
            builder: (context, snapshot) {
              final int commentCount = snapshot.data?.docs.length ?? 0;
              return _actionButton(Icons.chat_bubble_outline, '$commentCount',
                  subtleTextColor, () {});
            }),
        const Spacer(),
        StreamBuilder<bool>(
          stream: _firestoreService.isNoteBookmarked(widget.noteId),
          builder: (context, snapshot) {
            final bool isBookmarked = snapshot.data ?? false;
            return IconButton(
                icon:
                    Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                color: isBookmarked ? primaryBlue : subtleTextColor,
                onPressed: () {
                  if (_currentUser != null) {
                    _firestoreService.toggleBookmark(widget.noteId);
                  }
                });
          },
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined, color: subtleTextColor),
          onPressed: () => _showShareDialog(context, data['title'], isMyNote),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz, color: subtleTextColor),
          onSelected: (value) {
            if (value == 'delete') _showDeleteDialog();
            if (value == 'report') _showReportDialog(data['ownerId']);
            if (value == 'edit') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateNoteScreen(
                            docID: widget.noteId,
                            initialTitle: data['title'],
                            initialContent: data['content'],
                            initialCategory: data['category'],
                            initialIsPublic: data['isPublic'],
                          )));
            }
          },
          itemBuilder: (BuildContext context) {
            if (isMyNote) {
              return [
                const PopupMenuItem<String>(
                    value: 'edit', child: Text('Edit Note')),
                const PopupMenuItem<String>(
                    value: 'stats', child: Text('View Statistics')),
                const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete Note',
                        style: TextStyle(color: Colors.red))),
              ];
            } else {
              return [
                const PopupMenuItem<String>(
                    value: 'mute', child: Text('Hide this author')),
                const PopupMenuItem<String>(
                    value: 'report',
                    child: Text('Report Note',
                        style: TextStyle(color: Colors.red))),
              ];
            }
          },
        ),
      ],
    );
  }

  Widget _actionButton(
      IconData icon, String label, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.lato(
                  color: subtleTextColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNoteContent(Map<String, dynamic> data) {
    return Text(
      data['content'] ?? 'No content found.',
      style: GoogleFonts.sourceSerif4(
          fontSize: 18, height: 1.7, color: textColor.withOpacity(0.9)),
    );
  }

  Widget _buildTagsSection(Map<String, dynamic> data) {
    final String category = data['category'] ?? '';
    if (category.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8.0,
      children: [
        ActionChip(
          label: Text(category),
          onPressed: () {},
          backgroundColor: Colors.grey.shade200,
          labelStyle: GoogleFonts.lato(color: subtleTextColor),
        ),
      ],
    );
  }

  Widget _buildAuthorFooter(Map<String, dynamic> data, bool isMyNote) {
    final String userEmail = data['userEmail'] ?? 'Anonymous User';
    final String firstLetter =
        userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'P';

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: primaryBlue,
          child: Text(
            firstLetter,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Written by $userEmail',
                style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text('0 Followers • 4k Following',
                style: GoogleFonts.lato(color: subtleTextColor, fontSize: 14)),
          ],
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: isMyNote ? Colors.white : primaryBlue,
            foregroundColor: isMyNote ? primaryBlue : Colors.white,
            side: isMyNote
                ? const BorderSide(color: primaryBlue)
                : BorderSide.none,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(isMyNote ? 'Edit Profile' : 'Follow'),
        )
      ],
    );
  }
}
