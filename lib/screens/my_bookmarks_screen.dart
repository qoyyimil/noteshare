import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/screens/note_detail_screen.dart';
import 'package:noteshare/services/firestore_service.dart';

class MyBookmarksScreen extends StatefulWidget {
  const MyBookmarksScreen({super.key});

  @override
  State<MyBookmarksScreen> createState() => _MyBookmarksScreenState();
}

class _MyBookmarksScreenState extends State<MyBookmarksScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // -- UI Colors & Styles from HomeScreen --
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color textColor = Color(0xFF1F2937);
  static const Color subtleTextColor = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catatan Disimpan', style: GoogleFonts.lato(color: textColor)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: textColor),
        elevation: 1,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getUserBookmarksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Anda belum menyimpan catatan apapun.',
                style: GoogleFonts.lato(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final bookmarkedNotes = snapshot.data!;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: bookmarkedNotes.length,
                itemBuilder: (context, index) {
                  final noteData = bookmarkedNotes[index];
                  final docId = noteData['id'];
                  return _buildNoteCard(docId, noteData);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // Menggunakan widget kartu yang sama seperti di HomeScreen untuk konsistensi
  Widget _buildNoteCard(String docId, Map<String, dynamic> data) {
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
                        stream: _firestoreService.getCommentsStream(docId),
                        builder: (context, commentSnapshot) {
                          final count = commentSnapshot.data?.docs.length ?? 0;
                          return Text(count.toString(), style: GoogleFonts.lato(fontSize: 13, color: subtleTextColor));
                        },
                      ),
                      const Spacer(),
                      // Di halaman "Disimpan", bookmark selalu aktif
                      Icon(Icons.bookmark, color: primaryBlue),
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
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(width: 100, height: 100, color: Colors.grey[200]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
