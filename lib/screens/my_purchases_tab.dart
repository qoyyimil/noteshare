import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:noteshare/screens/note_detail_screen.dart';

class MyPurchasesTab extends StatelessWidget {
  const MyPurchasesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Please login.'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notes')
          .where('isPremium', isEqualTo: true)
          .where('purchasedBy', arrayContains: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final notes = snapshot.data!.docs;
        if (notes.isEmpty) {
          return const Center(child: Text('You have not purchased any premium notes yet.'));
        }
        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final data = notes[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['title'] ?? 'No title'),
              subtitle: Text('Purchased'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteDetailScreen(noteId: notes[index].id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}