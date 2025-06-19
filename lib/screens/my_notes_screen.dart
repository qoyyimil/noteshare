import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:noteshare/screens/create_note_screen.dart';
import 'package:noteshare/services/firestore_service.dart';

class MyNotesScreen extends StatefulWidget {
  const MyNotesScreen({super.key});

  @override
  State<MyNotesScreen> createState() => _MyNotesScreenState();
}

class _MyNotesScreenState extends State<MyNotesScreen> {
  final FirestoreService firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getMyNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("You haven't written any notes yet."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              String docID = document.id;
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;

              return _buildNoteCard(
                title: data['title'] ?? 'No Title',
                content: data['content'] ?? 'No Content',
                isPublic: data['isPublic'] ?? false,
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
                onDelete: () {
                  firestoreService.deleteNote(docID);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoteCard({
    required String title,
    required String content,
    required bool isPublic,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPublic ? Colors.green[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPublic ? 'Public' : 'Private',
                  style: TextStyle(
                    color: isPublic ? Colors.green[800] : Colors.grey[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey), onPressed: onEdit),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: onDelete),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          const SizedBox(height: 8),
          Text(content, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[800], fontSize: 16)),
        ],
      ),
    );
  }
}