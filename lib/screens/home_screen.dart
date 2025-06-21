import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/auth/auth_gate.dart';
import 'package:noteshare/auth/auth_service.dart';
import 'package:noteshare/screens/create_note_screen.dart';
import 'package:noteshare/screens/my_bookmarks_screen.dart';
import 'package:noteshare/screens/my_notes_screen.dart';
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

  // --- State untuk Search & Filter ---
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  String _activeSearchTab = 'Catatan';
  String _selectedCategory = 'Untuk Anda'; 

  // -- UI Colors & Styles --
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color bgColor = Color(0xFFFFFFFF);
  static const Color sidebarBgColor = Color(0xFFF9FAFB);
  static const Color textColor = Color(0xFF1F2937);
  static const Color subtleTextColor = Color(0xFF6B7280);

  final List<String> _categories = ['Untuk Anda', 'Umum', 'Fisika', 'Matematika', 'Sejarah', 'Biologi', 'Kimia'];

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
      _searchKeyword = _searchController.text.trim().toLowerCase();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchKeyword = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main content area
              Expanded(
                flex: 2,
                child: _buildMainContent(),
              ),
              // Right sidebar for Top Picks
              if (MediaQuery.of(context).size.width > 800)
                Container(
                  width: 350,
                  padding: const EdgeInsets.only(left: 24.0, top: 16.0),
                  child: _buildTopPicksSidebar(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Image.asset(
                  'assets/Logo.png',
                  height: 20,
                  errorBuilder: (context, error, stackTrace) => const Text('NoteShare'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari catatan atau pengguna...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: subtleTextColor),
                      suffixIcon: _searchKeyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20, color: subtleTextColor),
                              onPressed: _clearSearch,
                            )
                          : null,
                      filled: true,
                      fillColor: sidebarBgColor,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateNoteScreen())),
                icon: const Icon(Icons.edit_outlined, color: subtleTextColor, size: 20),
                label: Text('Tulis', style: GoogleFonts.lato(color: subtleTextColor)),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[100]),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: subtleTextColor)),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) => _onMenuItemSelected(value, context),
                offset: const Offset(0, 40),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryBlue,
                  child: Text(
                    currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(value: 'profile', child: ListTile(leading: Icon(Icons.person_outline), title: Text('Profil'))),
                  const PopupMenuItem<String>(value: 'library', child: ListTile(leading: Icon(Icons.bookmark_border), title: Text('Disimpan'))),
                  const PopupMenuItem<String>(value: 'notes', child: ListTile(leading: Icon(Icons.note_alt_outlined), title: Text('Catatan Saya'))),
                  const PopupMenuItem<String>(value: 'stats', child: ListTile(leading: Icon(Icons.bar_chart_outlined), title: Text('Statistik'))),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Keluar'))),
                ],
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _searchKeyword.isEmpty ? _buildCategoryTabs() : _buildSearchHeader(),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        Expanded(
          child: _searchKeyword.isEmpty
              ? _buildNotesList()
              : _activeSearchTab == 'Catatan'
                  ? _buildSearchNotesList()
                  : _buildSearchPeopleList(),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final bool isActive = _selectedCategory == category;
          return InkWell(
            onTap: () => setState(() => _selectedCategory = category),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  category,
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? primaryBlue : subtleTextColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildSearchTab('Catatan'),
          const SizedBox(width: 20),
          _buildSearchTab('Pengguna'),
        ],
      ),
    );
  }

  Widget _buildSearchTab(String tabName) {
    final bool isActive = _activeSearchTab == tabName;
    return InkWell(
      onTap: () => setState(() => _activeSearchTab = tabName),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? textColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          tabName,
          style: GoogleFonts.lato(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? textColor : subtleTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildNotesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getPublicNotesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final notes = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _selectedCategory == 'Untuk Anda' || (data['category'] ?? '').toString().toLowerCase() == _selectedCategory.toLowerCase();
        }).toList();

        if (notes.isEmpty) return const Center(child: Text("Tidak ada catatan di kategori ini."));

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: notes.length,
          itemBuilder: (context, index) => _buildNoteCard(notes[index].id, notes[index].data() as Map<String, dynamic>),
        );
      },
    );
  }

  Widget _buildSearchNotesList() {
    return StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getPublicNotesStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final filteredNotes = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toLowerCase();
            final content = (data['content'] ?? '').toLowerCase();
            return title.contains(_searchKeyword) || content.contains(_searchKeyword);
          }).toList();

          if (filteredNotes.isEmpty) return const Center(child: Text("Tidak ada catatan yang cocok."));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredNotes.length,
            itemBuilder: (context, index) => _buildNoteCard(filteredNotes[index].id, filteredNotes[index].data() as Map<String, dynamic>),
          );
        });
  }

  Widget _buildSearchPeopleList() {
    return StreamBuilder<QuerySnapshot>(
        stream: firestoreService.users.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final filteredUsers = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final email = (data['email'] ?? '').toLowerCase();
            return email.contains(_searchKeyword);
          }).toList();

          if (filteredUsers.isEmpty) return const Center(child: Text("Pengguna tidak ditemukan."));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) => _buildPeopleCard(filteredUsers[index].data() as Map<String, dynamic>),
          );
        });
  }
  
  Widget _buildNoteCard(String docId, Map<String, dynamic> data) {
    // --- FIX: Calculate likes count from the 'likes' array length ---
    final likesCount = (data['likes'] as List<dynamic>? ?? []).length;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = timestamp != null ? DateFormat('d MMM', 'id_ID').format(timestamp) : '';

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NoteDetailScreen(noteId: docId))),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 12, backgroundColor: primaryBlue.withOpacity(0.8)),
                      const SizedBox(width: 8),
                      Text(data['userEmail'] ?? 'User', style: GoogleFonts.lato(fontSize: 14, color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data['title'] ?? 'Tanpa Judul',
                    style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['content'] ?? 'Tidak ada konten',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(fontSize: 16, color: subtleTextColor, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(formattedDate, style: GoogleFonts.lato(fontSize: 13, color: subtleTextColor)),
                      const SizedBox(width: 16),
                      Icon(Icons.favorite_border, size: 16, color: subtleTextColor),
                      const SizedBox(width: 4),
                      Text('$likesCount', style: GoogleFonts.lato(fontSize: 13, color: subtleTextColor)),
                      const SizedBox(width: 16),
                      Icon(Icons.chat_bubble_outline, size: 16, color: subtleTextColor),
                      const SizedBox(width: 4),
                      StreamBuilder<QuerySnapshot>(
                        stream: firestoreService.getCommentsStream(docId),
                        builder: (context, commentSnapshot) {
                          final count = commentSnapshot.data?.docs.length ?? 0;
                          return Text(count.toString(), style: GoogleFonts.lato(fontSize: 13, color: subtleTextColor));
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: StreamBuilder<bool>(
                          stream: firestoreService.isNoteBookmarked(docId),
                          builder: (context, snapshot) {
                            final isBookmarked = snapshot.data ?? false;
                            return Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: subtleTextColor);
                          },
                        ),
                        onPressed: () => firestoreService.toggleBookmark(docId),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.more_horiz, color: subtleTextColor),
                        onPressed: () { /* TODO: Implement more options */ },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    data['imageUrl'],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(width: 120, height: 120, color: Colors.grey[200]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleCard(Map<String, dynamic> data) {
    final email = data['email'] ?? 'No email';
    return Container(
       padding: const EdgeInsets.symmetric(vertical: 16.0),
       decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
       child: Row(
         children: [
            CircleAvatar(radius: 24, backgroundColor: primaryBlue.withOpacity(0.8)),
            const SizedBox(width: 16),
            Expanded(child: Text(email, style: GoogleFonts.lato(fontSize: 16, color: textColor, fontWeight: FontWeight.bold))),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Ikuti'),
              style: OutlinedButton.styleFrom(
                foregroundColor: subtleTextColor,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
            )
         ],
       ),
    );
  }

  Widget _buildTopPicksSidebar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: sidebarBgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOP PICKS', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue, letterSpacing: 1)),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getTopPicksNotesStream(limit: 10),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                if (snapshot.data!.docs.isEmpty) return const Text('Belum ada Top Picks.');
                
                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    return _buildTopPickItem(index + 1, doc.id, doc.data() as Map<String, dynamic>);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopPickItem(int number, String docId, Map<String, dynamic> data) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NoteDetailScreen(noteId: docId))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number.toString().padLeft(2, '0'), 
            style: GoogleFonts.lato(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade300)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Tanpa Judul',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  data['userEmail'] ?? 'User',
                  style: GoogleFonts.lato(fontSize: 14, color: subtleTextColor),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _onMenuItemSelected(String value, BuildContext context) {
    switch (value) {
      case 'notes':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyNotesScreen()));
        break;
      case 'library':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookmarksScreen()));
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
          SnackBar(content: Text('Fitur "$value" belum tersedia.')),
        );
        break;
    }
  }
}
