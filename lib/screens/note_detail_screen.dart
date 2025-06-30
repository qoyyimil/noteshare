import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/providers/search_provider.dart';
import 'package:noteshare/screens/create_note_screen.dart';
import 'package:noteshare/screens/edit_profile.dart';
import 'package:noteshare/screens/my_coins_screen.dart';
import 'package:noteshare/screens/profile.dart';
import 'package:noteshare/widgets/home/public_profile_screen.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/comment_section.dart';
import 'package:noteshare/widgets/delete_confirmation_dialog.dart';
import 'package:noteshare/widgets/report_dialog.dart';
import 'package:noteshare/widgets/search_results_view.dart';
import 'package:noteshare/widgets/share_dialog.dart';
import 'package:noteshare/widgets/home/home_app_bar.dart';
import 'package:provider/provider.dart';

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
  final GlobalKey _commentSectionKey = GlobalKey();

  // --- State for Purchase Flow ---
  bool _isPurchasing = false;

  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color textColor = Color(0xFF1F2937);
  static const Color subtleTextColor = Color(0xFF6B7280);
  static const Color backgroundColor = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _incrementReadCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onClearSearch() {
    _searchController.clear();
  }

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
            'Are you sure you want to delete this note? This action cannot be canceled.',
        confirmText: 'Delete',
        onDelete: () async {
          try {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            await _firestoreService.deleteNote(widget.noteId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Note successfully deleted!'),
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

  void _onMenuItemSelected(String value, BuildContext context) {
    switch (value) {
      case 'profile':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile feature not available yet.')),
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

  Future<void> _incrementReadCount() async {
    _firestoreService.incrementReadCount(widget.noteId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HomeAppBar(
        searchController: _searchController,
        currentUser: _currentUser,
        primaryBlue: primaryBlue,
        subtleTextColor: subtleTextColor,
        sidebarBgColor: Colors.white, searchKeyword: '',
        onClearSearch: () {},
        // searchKeyword dan onClearSearch DIHAPUS
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (searchProvider.searchQuery.isNotEmpty) {
            return const SearchResultsView();
          }
          return child!;
        },
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.getNoteStream(widget.noteId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !_isPurchasing) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Note not found."));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final bool isMyNote = data['ownerId'] == _currentUser?.uid;
            final bool isPremium = data['isPremium'] ?? false;
            final List purchasedBy = data['purchasedBy'] ?? [];
            final bool hasPurchased = purchasedBy.contains(_currentUser?.uid);

            final bool canViewContent = !isPremium || isMyNote || hasPurchased;

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
                        if (canViewContent)
                          _buildNoteContent(data)
                        else
                          _buildLockedContent(context, data),
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
                              return KeyedSubtree(
                                key: _commentSectionKey,
                                child: CommentSection(
                                  noteId: widget.noteId,
                                  firestoreService: _firestoreService,
                                  currentUser: _currentUser,
                                  comments: comments,
                                ),
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
      ),
    );
  }

  // --- WIDGET YANG DIPERBAIKI ---
  Widget _buildLockedContent(BuildContext context, Map<String, dynamic> data) {
    final int price = data['coinPrice'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 60, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text("Premium Note",
              style:
                  GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("You must unlock this note to read its content.",
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 16, color: subtleTextColor)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isPurchasing
                ? null
                : () async {
                    if (_currentUser == null) return;

                    setState(() => _isPurchasing = true);

                    try {
                      final result = await _firestoreService.purchaseNote(
                          _currentUser!.uid, widget.noteId);

                      // Hanya bertindak jika mounted dan jika hasil TIDAK sukses.
                      // Jika sukses, StreamBuilder akan menangani pembaruan UI.
                      if (mounted && result != "Purchase successful!") {
                        setState(() => _isPurchasing = false);

                        if (result == "Not enough coins!") {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text("Insufficient Coins"),
                              content: const Text(
                                  "You don't have enough coins to purchase this note. Would you like to top up?"),
                              actions: [
                                TextButton(
                                  child: const Text("Cancel"),
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                ),
                                ElevatedButton(
                                  child: const Text("Top Up Now"),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const MyCoinsScreen()));
                                  },
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Menampilkan error lain yang mungkin dikembalikan oleh service
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(result),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    } catch (e) {
                      // Menangkap semua jenis error (exception) dari proses pembelian
                      if (mounted) {
                        setState(() => _isPurchasing = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Purchase failed: $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
            icon: _isPurchasing
                ? const SizedBox.shrink()
                : const Icon(Icons.lock_open, color: Colors.white),
            label: _isPurchasing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text("Unlock for $price Coins",
                    style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- Other existing build methods (_buildNoteTitle, etc.) ---
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
        ? DateFormat.yMMMMd('en_US').add_jm().format(timestamp)
        : 'A few seconds ago';

    final int readCount = data['readCount'] ?? 0;
    final String userFullName = data['fullName'] ?? 'Anonymous User';
    final String firstLetter =
        userFullName.isNotEmpty ? userFullName[0].toUpperCase() : 'A';
    final String ownerId = data['ownerId'] ?? ''; // Dapatkan ownerId di sini

    return GestureDetector(
      // Bungkus dengan GestureDetector
      onTap: () {
        if (_currentUser?.uid != ownerId) {
          // Hanya navigasi jika bukan profil pengguna saat ini
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PublicProfileScreen(
                  userId: ownerId), // Navigasi ke PublicProfileScreen
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfilePage(),
            ),
          );
        }
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: primaryBlue,
            child: Text(
              firstLetter,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userFullName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    Text(formattedTime,
                        style: GoogleFonts.lato(
                            color: subtleTextColor, fontSize: 14)),
                    Text(' • $readCount views',
                        style: GoogleFonts.lato(
                            color: subtleTextColor, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!isMyNote)
            StreamBuilder<bool>(
              // Pastikan StreamBuilder membungkus ElevatedButton
              stream: _firestoreService.isFollowingUser(ownerId),
              builder: (context, snapshot) {
                final isFollowing = snapshot.data ?? false;
                return ElevatedButton(
                  onPressed: () async {
                    if (_currentUser != null) {
                      await _firestoreService.toggleFollowUser(ownerId);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    // --- PERUBAHAN DI SINI ---
                    backgroundColor: isFollowing
                        ? Colors.white
                        : primaryBlue, // Jika Following -> Putih, jika belum -> primaryBlue
                    foregroundColor: isFollowing
                        ? primaryBlue
                        : Colors
                            .white, // Jika Following -> primaryBlue, jika belum -> Putih
                    side:
                        isFollowing // Jika Following -> border biru, jika belum -> tidak ada border
                            ? const BorderSide(color: primaryBlue)
                            : BorderSide.none,
                    // --- AKHIR PERUBAHAN ---
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(isFollowing ? 'Following' : 'Follow'),
                );
              },
            ),
        ],
      ),
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
              return _actionButton(
                  Icons.chat_bubble_outline, '$commentCount', subtleTextColor,
                  () {
                Scrollable.ensureVisible(
                  _commentSectionKey.currentContext!,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              });
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
        Builder(
          builder: (menuContext) {
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: subtleTextColor),
              onSelected: (value) {
                if (value == 'delete') _showDeleteDialog();
                if (value == 'report') _showReportDialog(data['ownerId']);
                if (value == 'edit') {
                  Navigator.push(
                      menuContext,
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
            );
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
    final String userFullName = data['fullName'] ?? 'Anonymous User';
    final String firstLetter =
        userFullName.isNotEmpty ? userFullName[0].toUpperCase() : 'A';
    final String ownerId = data['ownerId'] ?? '';

    return GestureDetector(
      // Bungkus dengan GestureDetector
      onTap: () {
        if (_currentUser?.uid != ownerId) {
          // Hanya navigasi jika bukan profil pengguna saat ini
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PublicProfileScreen(
                  userId: ownerId), // Navigasi ke PublicProfileScreen
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfilePage(),
            ),
          );
        }
      },
      child: Row(
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
              Text('Written by $userFullName',
                  style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  StreamBuilder<int>(
                    stream: _firestoreService.getFollowersCount(ownerId),
                    builder: (context, snapshot) {
                      final followers = snapshot.data ?? 0;
                      return Text('$followers Followers',
                          style: GoogleFonts.lato(
                              color: subtleTextColor, fontSize: 14));
                    },
                  ),
                  const SizedBox(width: 8),
                  StreamBuilder<int>(
                    stream: _firestoreService.getFollowingCount(ownerId),
                    builder: (context, snapshot) {
                      final following = snapshot.data ?? 0;
                      return Text('• $following Following',
                          style: GoogleFonts.lato(
                              color: subtleTextColor, fontSize: 14));
                    },
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          if (isMyNote)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditProfilePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryBlue,
                side: const BorderSide(color: primaryBlue),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Edit Profile'),
            )
          else
            StreamBuilder<bool>(
              stream: _firestoreService.isFollowingUser(ownerId),
              builder: (context, snapshot) {
                final isFollowing = snapshot.data ?? false;
                return ElevatedButton(
                  onPressed: () async {
                    await _firestoreService.toggleFollowUser(ownerId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.white : primaryBlue,
                    foregroundColor: isFollowing ? primaryBlue : Colors.white,
                    side: isFollowing
                        ? const BorderSide(color: primaryBlue)
                        : BorderSide.none,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(isFollowing ? 'Following' : 'Follow'),
                );
              },
            ),
        ],
      ),
    );
  }
}
