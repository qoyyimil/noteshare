import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noteshare/widgets/home/category_tabs.dart';
import 'package:noteshare/widgets/home/home_app_bar.dart';
import 'package:noteshare/screens/edit_profile.dart';
import 'package:noteshare/widgets/home/note_card.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/providers/search_provider.dart';
import 'package:noteshare/widgets/search_results_view.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool _loading = true;
  final TextEditingController searchController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  String _selectedTab = 'My Notes';
  final List<String> _tabs = ['My Notes', 'Bookmarks'];

  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color textColor = Color(0xFF1F2937);
  static const Color subtleTextColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color sidebarBgColor = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (currentUser == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    if (mounted) {
      setState(() {
        userData = doc.data();
        _loading = false;
      });
    }
  }

  Widget _buildNotesList() {
    if (currentUser == null)
      return const Center(child: Text("User not logged in."));
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getNotesByOwner(currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("You haven't created any notes yet."),
          ));
        }
        final notes = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.only(top: 24),
          itemCount: notes.length,
          itemBuilder: (context, i) {
            final doc = notes[i];
            final data = doc.data() as Map<String, dynamic>;
            final bool isPublic = data['isPublic'] ?? false;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Public/Private
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          isPublic ? Colors.blue.shade50 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPublic ? "Public" : "Private",
                      style: TextStyle(
                        color: isPublic
                            ? Colors.blue.shade800
                            : Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                NoteCard(
                  docId: doc.id,
                  data: data,
                  firestoreService: _firestoreService,
                  primaryBlue: primaryBlue,
                  textColor: textColor,
                  subtleTextColor: subtleTextColor,
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBookmarksList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getUserBookmarksStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("You haven't bookmarked any notes yet."),
          ));
        }
        final bookmarkedNotes = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.only(top: 24),
          itemCount: bookmarkedNotes.length,
          itemBuilder: (context, index) {
            final noteData = bookmarkedNotes[index];
            final docId = noteData['id'];
            return NoteCard(
              docId: docId,
              data: noteData,
              firestoreService: _firestoreService,
              isBookmarked: true,
              primaryBlue: primaryBlue,
              textColor: textColor,
              subtleTextColor: subtleTextColor,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HomeAppBar(
        searchController: searchController,
        currentUser: currentUser,
        primaryBlue: primaryBlue,
        subtleTextColor: subtleTextColor,
        sidebarBgColor: sidebarBgColor,
        searchKeyword: '',
        onClearSearch: () {},
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (searchProvider.searchQuery.isNotEmpty) {
            return const SearchResultsView();
          }
          return child!;
        },
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildDesktopLayout(),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(right: 32),
            child: _buildNotesSection(),
          ),
        ),
        SizedBox(
          width: 340,
          child: _buildProfileSidebar(),
        ),
      ],
    );
  }

  // --- PERUBAHAN DI SINI ---
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NAMA PENGGUNA DITAMBAHKAN KEMBALI DI ATAS TABS
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          child: Text(
            userData?['fullName'] ?? 'My Notes',
            style: GoogleFonts.lora(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        CategoryTabs(
          categories: _tabs,
          selectedCategory: _selectedTab,
          onCategorySelected: (tab) {
            setState(() {
              _selectedTab = tab;
            });
          },
          primaryBlue: primaryBlue,
          subtleTextColor: subtleTextColor,
        ),
        const Divider(height: 1, color: borderColor),
        Expanded(
          child: _selectedTab == 'My Notes'
              ? _buildNotesList()
              : _buildBookmarksList(),
        ),
      ],
    );
  }

  Widget _buildProfileSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildProfileHeader(),
        const SizedBox(height: 32),
        _buildAboutMeCard(),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final String fullName = userData?['fullName'] ?? 'User';
    final String displayLetter =
        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';

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
            backgroundColor: primaryBlue,
            child: Text(displayLetter,
                style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(
            fullName,
            style: GoogleFonts.lora(
                fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 150,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditProfilePage()),
                ).then((_) => _fetchUserData());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Edit Profile'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFollowerFollowingCount(isFollowers: true),
              const SizedBox(width: 32),
              _buildFollowerFollowingCount(isFollowers: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMeCard() {
    return Container(
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
          Text('About Me',
              style: GoogleFonts.lora(
                  fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          Text(userData?['about'] ?? "Belum ada deskripsi tentang saya.",
              style: GoogleFonts.lato(
                  fontSize: 15, color: subtleTextColor, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildFollowerFollowingCount({required bool isFollowers}) {
    if (currentUser == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.users
          .doc(currentUser!.uid)
          .collection(isFollowers ? 'followers' : 'following')
          .snapshots(),
      builder: (context, snapshot) {
        return _buildStatItem(snapshot.data?.docs.length ?? 0,
            isFollowers ? 'Followers' : 'Following');
      },
    );
  }

  Widget _buildStatItem(int count, String label) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.lora(
              fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
        ),
        Text(label,
            style: GoogleFonts.lato(fontSize: 14, color: subtleTextColor)),
      ],
    );
  }
}
