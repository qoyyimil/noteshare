import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- Import FirebaseAuth
import 'package:flutter/material.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/share_dialog.dart';

class NoteDetailScreen extends StatelessWidget {
  final String noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  // Fungsi ini sekarang menerima status kepemilikan
  void _showShareDialog(BuildContext context, String title, bool isOwner) {
    // Buat URL manual yang akan dibagikan
    final String url = "https://noteshare-86d6d.web.app/#/note/$noteId";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShareDialog(
          noteId: noteId,
          noteTitle: title,
          shareUrl: url,
          isOwner: isOwner, // <-- Kirim status kepemilikan ke dialog
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    // Dapatkan info pengguna yang sedang login
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: firestoreService.notes.doc(noteId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Scaffold(appBar: AppBar(), body: const Center(child: Text("Catatan tidak ditemukan.")));
          }

          Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
          String noteTitle = data['title'] ?? 'Tanpa Judul';
          // Dapatkan ID pemilik dari data catatan
          String ownerId = data['ownerId'] ?? '';

          // Cek apakah pengguna saat ini adalah pemilik catatan
          bool isMyNote = (currentUser?.uid == ownerId);

          return Scaffold(
            appBar: AppBar(
              title: Text(noteTitle),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 1,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  // Panggil fungsi dengan status kepemilikan yang benar
                  onPressed: () => _showShareDialog(context, noteTitle, isMyNote),
                  tooltip: 'Bagikan',
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(noteTitle, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Oleh ${data['userEmail'] ?? 'Pengguna Anonim'}", style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                  const Divider(height: 40),
                  Text(data['content'] ?? 'Tidak ada konten.', style: const TextStyle(fontSize: 16, height: 1.5)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}