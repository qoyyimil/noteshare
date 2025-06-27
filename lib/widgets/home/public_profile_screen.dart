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
  bool _isFollowing = false;
  bool _isFollowLoading = false;

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
    _setupFollowStream();
  }

  void _setupFollowStream() {
    if (_currentUser != null && _currentUser!.uid != widget.userId) {
      _firestoreService.isFollowingUser(widget.userId).listen((isFollowing) {
        if (mounted) {
          setState(() {
            _isFollowing = isFollowing;
          });
        }
      });
    }
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
          _profileUserName = data['userName'] ??
              data['fullName'] ??
              data['email'] ??
              'Pengguna NoteShare';
          _profileUserEmail = data['email'] ?? '';
          _profileAboutMe = data['aboutMe'] ??
              data['about'] ??
              "Belum ada deskripsi tentang saya.";
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

  Future<void> _onFollowButtonPressed() async {
    if (_currentUser == null || widget.userId == _currentUser!.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot follow yourself!")),
      );
      return;
    }

    setState(() {
      _isFollowLoading = true;
    });

    try {
      await _firestoreService.toggleFollowUser(widget.userId);

      if (mounted) {
        // Check current follow status
        final isFollowing =
            await _firestoreService.isFollowingUser(widget.userId).first;

        setState(() {
          _isFollowing = isFollowing;
          _isFollowLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFollowing
                ? 'Start following $_profileUserName'
                : 'Stop following $_profileUserName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFollowLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to follow/unfollow: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onClearSearch() {
    _searchController.clear();
    setState(() {});
  }

  void _onMenuItemSelected(String value, BuildContext context) {
    // Implement menu actions if needed
  }

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
          // Dynamic Follow Button with real-time status
          if (_currentUser != null && widget.userId != _currentUser!.uid)
            StreamBuilder<bool>(
              stream: _firestoreService.isFollowingUser(widget.userId),
              builder: (context, followSnapshot) {
                final isFollowing = followSnapshot.data ?? false;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isFollowLoading ? null : _onFollowButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isFollowing ? Colors.grey.shade300 : primaryBlue,
                      foregroundColor:
                          isFollowing ? Colors.black87 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isFollowLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isFollowing ? 'Following' : 'Follow'),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          // Real-time followers/following count
          StreamBuilder<int>(
            stream: _firestoreService.getFollowersCount(widget.userId),
            builder: (context, followersSnapshot) {
              return StreamBuilder<int>(
                stream: _firestoreService.getFollowingCount(widget.userId),
                builder: (context, followingSnapshot) {
                  final followersCount = followersSnapshot.data ?? 0;
                  final followingCount = followingSnapshot.data ?? 0;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem(followersCount, 'Followers'),
                      const SizedBox(width: 32),
                      _buildStatItem(followingCount, 'Following'),
                    ],
                  );
                },
              );
            },
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
            stream:
                _firestoreService.getPublicNotesByOwnerIdStream(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: subtleTextColor),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memuat catatan',
                        style: GoogleFonts.lato(fontSize: 16, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Terjadi kesalahan saat memuat catatan pengguna',
                        style: GoogleFonts.lato(
                            fontSize: 14, color: subtleTextColor),
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
                      Icon(Icons.note_outlined,
                          size: 48, color: subtleTextColor),
                      const SizedBox(height: 16),
                      Text(
                        "Belum ada catatan publik",
                        style: GoogleFonts.lato(fontSize: 16, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${_profileUserName} belum menulis catatan publik.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                            fontSize: 14, color: subtleTextColor),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (context, i) =>
                    const Divider(height: 32, color: borderColor, thickness: 1),
                itemBuilder: (context, index) {
                  DocumentSnapshot document = snapshot.data!.docs[index];
                  String docID = document.id;
                  Map<String, dynamic> data =
                      document.data() as Map<String, dynamic>;

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
