import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noteshare/screens/create_note_screen.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/home/home_app_bar.dart';

class MyNotesScreen extends StatefulWidget {
  const MyNotesScreen({super.key});

  @override
  State<MyNotesScreen> createState() => _MyNotesScreenState();
}

class _MyNotesScreenState extends State<MyNotesScreen> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // -- UI Colors & Styles --
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color textColor = Color(0xFF1F2937);
  static const Color subtleTextColor = Color(0xFF6B7280);
  static const Color bgColor = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Update UI when search text changes
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onClearSearch() {
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: HomeAppBar(
        searchController: _searchController,
        searchKeyword: _searchController.text,
        onClearSearch: _onClearSearch,
        currentUser: _currentUser,
        primaryBlue: primaryBlue,
        subtleTextColor: subtleTextColor,
        sidebarBgColor: bgColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getMyNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "You haven't written any notes yet.",
                style: GoogleFonts.lato(fontSize: 16, color: subtleTextColor),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot document = snapshot.data!.docs[index];
                  String docID = document.id;
                  Map<String, dynamic> data =
                      document.data() as Map<String, dynamic>;

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
              ),
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPublic
                      ? primaryBlue.withOpacity(0.1)
                      : subtleTextColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isPublic ? 'Public' : 'Private',
                  style: GoogleFonts.lato(
                    color: isPublic ? primaryBlue : subtleTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        color: subtleTextColor, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Edit note',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete note',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.lora(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.sourceSerif4(
              color: subtleTextColor,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
