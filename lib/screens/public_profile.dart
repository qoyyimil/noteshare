import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/home/note_card.dart';
import 'package:noteshare/widgets/home/home_app_bar.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.userName = 'Pengguna NoteShare',
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();

  // Data profil
  String _profileUserName = '';
  String _profileUserEmail = '';
  String _profileAboutMe = '';
  bool _isLoading = true;
  bool _hasError = false;

  // Warna UI
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color textColor = Color(0xFF1F2937);
  static const Color subtleTextColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color sidebarBgColor = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _profileUserName = widget.userName;
    _loadUserProfileData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfileData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      DocumentSnapshot userDoc =
          await _firestoreService.users.doc(widget.userId).get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _profileUserName =
              data['userName'] ?? data['fullName'] ?? data['email'] ?? 'Pengguna NoteShare';
          _profileUserEmail = data['email'] ?? '';
          _profileAboutMe =
              data['aboutMe'] ?? data['about'] ?? "Belum ada deskripsi tentang saya.";
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _onClearSearch() {
    _searchController.clear();
    setState(() {});
  }

  void _onMenuItemSelected(String value, BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HomeAppBar(
        searchController: _searchController,
        searchKeyword: _searchController.text,
        onClearSearch: _onClearSearch,
        currentUser: _currentUser,
        primaryBlue: primaryBlue,
        subtleTextColor: subtleTextColor,
        sidebarBgColor: sidebarBgColor,
      ),
      body: _buildBody(isDesktop),
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: subtleTextColor),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat profil pengguna',
              style: GoogleFonts.lato(fontSize: 18, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Pengguna mungkin tidak ditemukan',
              style: GoogleFonts.lato(fontSize: 14, color: subtleTextColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kembali'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT: Notes Section
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(right: 32),
            child: _buildNotesSection(),
          ),
        ),
        // RIGHT: Sidebar
        SizedBox(
          width: 340,
          child: _buildProfileSidebar(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildProfileHeader(),
        const SizedBox(height: 24),
        Expanded(child: _buildNotesSection()),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final String currentUserId = _currentUser?.uid ?? '';
    final bool isMe = currentUserId == widget.userId;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.grey.shade300,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            _profileUserName,
            style: GoogleFonts.lora(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          if (!isMe)
            _buildFollowButton(currentUserId, widget.userId),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFollowersCount(widget.userId),
              const SizedBox(width: 32),
              _buildFollowingCount(widget.userId),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildProfileHeader(),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Me',
                style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _profileAboutMe,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  color: subtleTextColor,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nama besar di atas daftar note
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0, top: 8),
          child: Text(
            _profileUserName,
            style: GoogleFonts.lora(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getPublicNotesByOwnerIdStream(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: subtleTextColor),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memuat catatan',
                        style: GoogleFonts.lato(fontSize: 16, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Terjadi kesalahan saat memuat catatan pengguna',
                        style: GoogleFonts.lato(fontSize: 14, color: subtleTextColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_outlined, size: 48, color: subtleTextColor),
                      const SizedBox(height: 16),
                      Text(
                        "Belum ada catatan publik",
                        style: GoogleFonts.lato(fontSize: 16, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${_profileUserName} belum menulis catatan publik.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(fontSize: 14, color: subtleTextColor),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (context, i) => const Divider(height: 32, color: borderColor, thickness: 1),
                itemBuilder: (context, index) {
                  DocumentSnapshot document = snapshot.data!.docs[index];
                  String docID = document.id;
                  Map<String, dynamic> data = document.data() as Map<String, dynamic>;

                  return NoteCard(
                    docId: docID,
                    data: data,
                    firestoreService: _firestoreService,
                    primaryBlue: primaryBlue,
                    textColor: textColor,
                    subtleTextColor: subtleTextColor,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // FOLLOW BUTTON
  Widget _buildFollowButton(String currentUserId, String targetUserId) {
    return StreamBuilder<bool>(
      stream: _firestoreService.isFollowing(targetUserId, currentUserId),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;
        return ElevatedButton(
          onPressed: () async {
            if (isFollowing) {
              await _firestoreService.unfollowUser(targetUserId, currentUserId);
            } else {
              await _firestoreService.followUser(targetUserId, currentUserId);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.white : primaryBlue,
            foregroundColor: isFollowing ? primaryBlue : Colors.white,
            side: isFollowing ? const BorderSide(color: primaryBlue) : BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(isFollowing ? 'Following' : 'Follow'),
        );
      },
    );
  }

  // FOLLOWERS COUNT
  Widget _buildFollowersCount(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('followers')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return _buildStatItem(count, 'Followers');
      },
    );
  }

  // FOLLOWING COUNT
  Widget _buildFollowingCount(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('following')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return _buildStatItem(count, 'Following');
      },
    );
  }

  Widget _buildStatItem(int count, String label) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.lora(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lato(fontSize: 14, color: subtleTextColor),
        ),
      ],
    );
  }
}