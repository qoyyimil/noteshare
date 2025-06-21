import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noteshare/screens/note_detail_screen.dart';
import 'package:noteshare/services/firestore_service.dart';

class TopPicksSidebar extends StatelessWidget {
  final FirestoreService firestoreService;
  final Color primaryBlue;
  final Color textColor;
  final Color subtleTextColor;
  final Color sidebarBgColor;

  const TopPicksSidebar({
    super.key,
    required this.firestoreService,
    required this.primaryBlue,
    required this.textColor,
    required this.subtleTextColor,
    required this.sidebarBgColor,
  });

  @override
  Widget build(BuildContext context) {
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
                    return _buildTopPickItem(context, index + 1, doc.id, doc.data() as Map<String, dynamic>); // Pass context
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPickItem(BuildContext context, int number, String docId, Map<String, dynamic> data) {
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
}