import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:noteshare/auth/auth_gate.dart';
import 'package:noteshare/auth/auth_service.dart';
import 'package:noteshare/screens/create_note_screen.dart';
import 'package:noteshare/screens/my_notes_screen.dart'; // Pastikan ini digunakan untuk "Catatan"
import 'package:noteshare/screens/note_detail_screen.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  final List<String> _categories = [
    'For you',
    'Umum',
    'Fisika',
    'Matematika',
    'Biologi',
    'Kimia',
    'Sejarah'
  ];
  String _selectedCategory = 'For you';

  String _activeSearchTab = 'Notes';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchKeyword = _searchController.text.toLowerCase();
      if (_searchKeyword.isNotEmpty) {
        _activeSearchTab = 'Notes';
      }
    });
  }

  void _performSearch(String query) {
    setState(() {
      _searchKeyword = query.toLowerCase();
      if (_searchKeyword.isNotEmpty) {
        _activeSearchTab = 'Notes';
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchKeyword = '';
      _activeSearchTab = 'Notes';
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
      _searchKeyword = '';
      _activeSearchTab = 'Notes';
    });
  }

  void _onMenuItemSelected(String value, BuildContext context) {
    switch (value) {
      case 'notes':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyNotesScreen()));
        break;
      case 'library': // Handle 'Perpustakaan' menu item
        // Di sini Anda perlu menavigasi ke MyBookmarksScreen
        // Contoh: Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookmarksScreen()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perpustakaan belum diimplementasikan. Buat MyBookmarksScreen terlebih dahulu.')),
        );
        break;
      case 'logout':
        final authService = Provider.of<AuthService>(context, listen: false);
        authService.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$value belum diimplementasikan.')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Image.asset(
                'assets/Logo.png',
                height: 20,
              ),
            ),
            const SizedBox(width: 20),
            Container(
              width: 250,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                  hintStyle: TextStyle(color: Colors.grey[600]),
                ),
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateNoteScreen())),
            icon: const Icon(Icons.edit_outlined, color: Colors.black54),
            tooltip: 'Write a new note',
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.black54)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: PopupMenuButton<String>(
              onSelected: (value) => _onMenuItemSelected(value, context),
              offset: const Offset(0, 40),
              child: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Text(
                  currentUser?.email?.isNotEmpty == true
                      ? currentUser!.email!.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'profile', child: ListTile(leading: Icon(Icons.person_outline), title: Text('Profil'))),
                const PopupMenuItem<String>(value: 'library', child: ListTile(leading: Icon(Icons.bookmark_border), title: Text('Perpustakaan'))),
                const PopupMenuItem<String>(value: 'notes', child: ListTile(leading: Icon(Icons.note_alt_outlined), title: Text('Catatan'))),
                const PopupMenuItem<String>(value: 'stats', child: ListTile(leading: Icon(Icons.bar_chart_outlined), title: Text('Statistik'))),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(value: 'settings', child: ListTile(leading: Icon(Icons.settings_outlined), title: Text('Pengaturan'))),
                const PopupMenuItem<String>(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Keluar'))),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_searchKeyword.isEmpty)
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return _buildCategoryTab(category);
                        },
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
                          child: Text(
                            'Results for "${_searchController.text}"',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _buildSearchTab('Notes'),
                            const SizedBox(width: 20),
                            _buildSearchTab('People'),
                          ],
                        ),
                      ],
                    ),
                  const Divider(height: 1),
                  Expanded(
                    child: _searchKeyword.isEmpty
                        ? _buildCategoryNotesStreamBuilder()
                        : _activeSearchTab == 'Notes'
                            ? _buildSearchNotesStreamBuilder()
                            : _buildSearchPeopleStreamBuilder(),
                  ),
                ],
              ),
            ),
            if (MediaQuery.of(context).size.width > 768)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(left: 24.0, top: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOP PICKS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Menggunakan StreamBuilder untuk mengambil data Top Picks
                        StreamBuilder<QuerySnapshot>(
                          stream: firestoreService.getTopPicksNotesStream(limit: 4), // Ambil 4 Top Picks
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Text('Belum ada Top Picks.', style: TextStyle(color: Colors.grey));
                            }

                            // Tampilkan daftar Top Picks
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: snapshot.data!.docs.map((document) {
                                Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                                return _buildTopPickItem(
                                  title: data['title'] ?? 'Catatan Tanpa Judul',
                                  readTime: '${data['bookmarkCount'] ?? 0} bookmark${(data['bookmarkCount'] ?? 0) != 1 ? 's' : ''}', // Menampilkan jumlah bookmark
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(String categoryName) {
    final bool isActive = _selectedCategory == categoryName;
    return InkWell(
      onTap: () => _onCategorySelected(categoryName),
      hoverColor: Colors.grey[200],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.blueAccent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          categoryName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.blueAccent : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchTab(String tabName) {
    final bool isActive = _activeSearchTab == tabName;
    return InkWell(
      onTap: () {
        setState(() {
          _activeSearchTab = tabName;
        });
      },
      hoverColor: Colors.grey[200],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.blueAccent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          tabName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.blueAccent : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryNotesStreamBuilder() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getPublicNotesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada catatan publik."));

        final allNotes = snapshot.data!.docs;

        final filteredNotes = allNotes.where((document) {
          final data = document.data()! as Map<String, dynamic>;
          final category = (data['category'] ?? 'Umum').toString().toLowerCase();
          return _selectedCategory == 'For you' || category == _selectedCategory.toLowerCase();
        }).toList();

        if (filteredNotes.isEmpty) {
          return const Center(child: Text("Tidak ada catatan yang cocok di kategori ini."));
        }

        return ListView.builder(
          itemCount: filteredNotes.length,
          itemBuilder: (context, index) {
            DocumentSnapshot document = filteredNotes[index];
            String docID = document.id;
            Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
            bool isMyNote = currentUser?.uid == data['ownerId']; // Menggunakan ownerId

            return _buildNoteCard(
              docId: docID,
              title: data['title'] ?? 'Tanpa Judul',
              content: data['content'] ?? 'Tanpa Konten',
              userEmail: data['userEmail'] ?? 'Pengguna Anonim',
              isMyNote: isMyNote,
              category: data['category'] ?? 'Umum',
              isBookmarkedStream: firestoreService.isNoteBookmarked(docID), // Meneruskan status bookmark
              onEdit: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CreateNoteScreen(
                  docID: docID,
                  initialTitle: data['title'],
                  initialContent: data['content'],
                  initialCategory: data['category'],
                  initialIsPublic: data['isPublic'] ?? false,
                )));
              },
              onDelete: () => firestoreService.deleteNote(docID),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchNotesStreamBuilder() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getPublicNotesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada catatan publik."));

        final allNotes = snapshot.data!.docs;

        final filteredNotes = allNotes.where((document) {
          final data = document.data()! as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final content = (data['content'] ?? '').toString().toLowerCase();
          final category = (data['category'] ?? 'Umum').toString().toLowerCase();
          final userEmail = (data['userEmail'] ?? '').toString().toLowerCase();

          return title.contains(_searchKeyword) ||
                 content.contains(_searchKeyword) ||
                 category.contains(_searchKeyword) ||
                 userEmail.contains(_searchKeyword);
        }).toList();

        if (filteredNotes.isEmpty) {
          return const Center(child: Text("Tidak ada catatan yang cocok dengan pencarian Anda."));
        }

        return ListView.builder(
          itemCount: filteredNotes.length,
          itemBuilder: (context, index) {
            DocumentSnapshot document = filteredNotes[index];
            String docID = document.id;
            Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
            bool isMyNote = currentUser?.uid == data['ownerId']; // Menggunakan ownerId

            return _buildNoteCard(
              docId: docID,
              title: data['title'] ?? 'Tanpa Judul',
              content: data['content'] ?? 'Tanpa Konten',
              userEmail: data['userEmail'] ?? 'Pengguna Anonim',
              isMyNote: isMyNote,
              category: data['category'] ?? 'Umum',
              isBookmarkedStream: firestoreService.isNoteBookmarked(docID), // Meneruskan status bookmark
              onEdit: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CreateNoteScreen(
                  docID: docID,
                  initialTitle: data['title'],
                  initialContent: data['content'],
                  initialCategory: data['category'],
                  initialIsPublic: data['isPublic'] ?? false,
                )));
              },
              onDelete: () => firestoreService.deleteNote(docID),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchPeopleStreamBuilder() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.users.snapshots(), // Menggunakan users dari firestoreService
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada pengguna terdaftar."));

        final allUsers = snapshot.data!.docs;

        final filteredUsers = allUsers.where((document) {
          final data = document.data()! as Map<String, dynamic>;
          final userEmail = (data['email'] ?? '').toString().toLowerCase();
          // Asumsi Anda memiliki bidang 'username' di dokumen pengguna jika ingin dicari
          // final userName = (data['username'] ?? '').toString().toLowerCase();
          // return userEmail.contains(_searchKeyword) || userName.contains(_searchKeyword);
          return userEmail.contains(_searchKeyword); // Hanya mencari berdasarkan email untuk saat ini
        }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(child: Text("Tidak ada pengguna yang cocok dengan pencarian Anda."));
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            DocumentSnapshot document = filteredUsers[index];
            Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
            final userEmail = data['email'] ?? 'Pengguna Anonim';
            // final userName = data['username'] ?? userEmail.split('@').first; // Fallback jika username tidak ada
            final userName = userEmail.split('@').first; // Menggunakan bagian sebelum '@' sebagai nama sementara

            return _buildPeopleCard(userEmail: userEmail, userName: userName);
          },
        );
      },
    );
  }

  // Widget untuk membuat kartu catatan (MODIFIED untuk bookmarking)
  Widget _buildNoteCard({
    required String docId,
    required String title,
    required String content,
    required String userEmail,
    required bool isMyNote,
    required String category,
    required Stream<bool> isBookmarkedStream, // Parameter baru untuk status bookmark
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final String initial = userEmail.isNotEmpty ? userEmail.substring(0, 1).toUpperCase() : 'U';

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => NoteDetailScreen(noteId: docId)));
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.blueAccent.withOpacity(0.7),
                  child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Text(
                  userEmail,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[800], fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isMyNote) ...[
                  IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey), onPressed: onEdit),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: onDelete),
                ],
                // Tombol Bookmark dengan StreamBuilder untuk status real-time
                StreamBuilder<bool>(
                  stream: isBookmarkedStream,
                  builder: (context, snapshot) {
                    bool isBookmarked = snapshot.data ?? false; // Default ke false jika tidak ada data
                    return IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked ? Colors.blueAccent : Colors.grey,
                      ),
                      onPressed: () async {
                        if (currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Anda harus masuk untuk membookmark catatan.')),
                          );
                          return;
                        }
                        try {
                          await firestoreService.toggleBookmark(docId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isBookmarked ? 'Catatan di-unbookmark!' : 'Catatan di-bookmark!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal mengubah status bookmark: $e')),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleCard({required String userEmail, required String userName}) {
    final String initial = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.purpleAccent,
            child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                Text(
                  userEmail,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Melihat profil ${userName} (belum diimplementasikan)')),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('View', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPickItem({required String title, required String readTime}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            readTime, // Sekarang akan menampilkan "X bookmark(s)"
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}