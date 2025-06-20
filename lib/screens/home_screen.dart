import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:noteshare/auth/auth_gate.dart';
import 'package:noteshare/auth/auth_service.dart';
import 'package:noteshare/screens/create_note_screen.dart';
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

  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  void _onMenuItemSelected(String value, BuildContext context) {
    switch (value) {
      case 'notes':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const MyNotesScreen()));
        break;
      case 'logout':
        final authService =
            Provider.of<AuthService>(context, listen: false);
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
        elevation: 1,
        title: Row(
          children: [
            const Text('NoteShare', style: TextStyle(color: Colors.black)),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 40,
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari catatan...',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreateNoteScreen())),
            icon: const Icon(Icons.drive_file_rename_outline,
                color: Colors.black54),
            tooltip: 'Tulis catatan baru',
          ),
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none,
                  color: Colors.black54)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: PopupMenuButton<String>(
              onSelected: (value) => _onMenuItemSelected(value, context),
              offset: const Offset(0, 40),
              child: const CircleAvatar(backgroundColor: Colors.blueAccent),
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                    value: 'profile',
                    child: ListTile(
                        leading: Icon(Icons.person_outline),
                        title: Text('Profil'))),
                const PopupMenuItem<String>(
                    value: 'library',
                    child: ListTile(
                        leading: Icon(Icons.bookmark_border),
                        title: Text('Perpustakaan'))),
                const PopupMenuItem<String>(
                    value: 'notes',
                    child: ListTile(
                        leading: Icon(Icons.note_alt_outlined),
                        title: Text('Catatan'))),
                const PopupMenuItem<String>(
                    value: 'stats',
                    child: ListTile(
                        leading: Icon(Icons.bar_chart_outlined),
                        title: Text('Statistik'))),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                    value: 'settings',
                    child: ListTile(
                        leading: Icon(Icons.settings_outlined),
                        title: Text('Pengaturan'))),
                const PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                        leading: Icon(Icons.logout, color: Colors.red),
                        title: Text('Keluar'))),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNoteListColumn(),
                  if (MediaQuery.of(context).size.width > 768)
                    _buildSidebar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteListColumn() {
    return Expanded(
      flex: 3,
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['For you', 'Physics', 'Math', 'History', 'Biology']
                  .map((category) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 20.0),
                        child: Text(category,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black54)),
                      ))
                  .toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getPublicNotesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada catatan publik."));
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  return title.contains(searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                      child: Text("Tidak ditemukan catatan yang cocok."));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final document = filteredDocs[index];
                    String docID = document.id;
                    Map<String, dynamic> data =
                        document.data()! as Map<String, dynamic>;
                    bool isMyNote = currentUser?.uid == data['userId'];

                    return _buildNoteCard(
                      docId: docID,
                      title: data['title'] ?? 'Tanpa Judul',
                      content: data['content'] ?? 'Tanpa Konten',
                      userEmail: data['userEmail'] ?? 'Pengguna Anonim',
                      isMyNote: isMyNote,
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateNoteScreen(
                              docID: docID,
                              initialTitle: data['title'],
                              initialContent: data['content'],
                              initialCategory: data['category'],
                              initialIsPublic: data['isPublic'],
                            ),
                          ),
                        );
                      },
                      onDelete: () => firestoreService.deleteNote(docID),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0, top: 24.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
              color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
          child: const Text('TOP PICKS\n(Placeholder)'),
        ),
      ),
    );
  }

  Widget _buildNoteCard({
    required String docId,
    required String title,
    required String content,
    required String userEmail,
    required bool isMyNote,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NoteDetailScreen(noteId: docId)));
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                    radius: 12,
                    child: Text(userEmail.isNotEmpty
                        ? userEmail.substring(0, 1).toUpperCase()
                        : 'U')),
                const SizedBox(width: 8),
                Text(userEmail, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 8),
            Text(content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[800], fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isMyNote) ...[
                  IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                      onPressed: onEdit),
                  IconButton(
                      icon:
                          const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: onDelete),
                ],
                IconButton(
                    icon: const Icon(Icons.bookmark_border,
                        color: Colors.grey),
                    onPressed: () {}),
              ],
            )
          ],
        ),
      ),
    );
  }
}