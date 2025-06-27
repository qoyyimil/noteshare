import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:noteshare/widgets/home/home_app_bar.dart';
import 'package:noteshare/screens/edit_profile.dart';
import 'package:noteshare/widgets/home/note_card.dart';
import 'package:noteshare/services/firestore_service.dart';

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
  String searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    searchController.addListener(() {
      setState(() {
        searchKeyword = searchController.text;
      });
    });
  }

  Future<void> _fetchUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    setState(() {
      userData = doc.data();
      _loading = false;
    });
  }

  Widget _buildNotesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notes')
          .where('ownerId', isEqualTo: currentUser!.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("You haven't created any notes yet.");
        }
        final notes = snapshot.data!.docs;
        final filteredNotes = searchKeyword.isEmpty
            ? notes
            : notes.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = (data['title'] ?? '').toString().toLowerCase();
                final content =
                    (data['content'] ?? '').toString().toLowerCase();
                return title.contains(searchKeyword.toLowerCase()) ||
                    content.contains(searchKeyword.toLowerCase());
              }).toList();

        return ListView.separated(
          itemCount: filteredNotes.length,
          separatorBuilder: (context, i) => const SizedBox(height: 24),
          itemBuilder: (context, i) {
            final doc = filteredNotes[i];
            final data = doc.data() as Map<String, dynamic>;
            return NoteCard(
              docId: doc.id,
              data: data,
              firestoreService: FirestoreService(),
              primaryBlue: const Color(0xFF3B82F6),
              textColor: Colors.black,
              subtleTextColor: const Color(0xFF6B7280),
            );
          },
        );
      },
    );
  }

  Widget _buildStatColumn(String userId, bool isFollowers) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection(isFollowers ? 'followers' : 'following')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              isFollowers ? 'Followers' : 'Following',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3B82F6);

    return Scaffold(
      appBar: HomeAppBar(
        searchController: searchController,
        searchKeyword: searchKeyword,
        onClearSearch: () {
          searchController.clear();
        },
        currentUser: currentUser,
        primaryBlue: primaryBlue,
        subtleTextColor: const Color(0xFF6B7280),
        sidebarBgColor: const Color(0xFFF9FAFB),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT: My Notes
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData?['fullName'] ?? '',
                              style: const TextStyle(
                                  fontSize: 40, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: _buildNotesList(),
                            ),
                          ],
                        ),
                      ),
                      // RIGHT: Sidebar Card
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(left: 32),
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                children: [
                                  const CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.grey,
                                    child: Icon(Icons.person,
                                        size: 60, color: Colors.white),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const EditProfilePage()),
                                      ).then((_) => _fetchUserData());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                    ),
                                    child: const Text("Edit Profile"),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    userData?['fullName'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 20),
                                  // Followers & Following sejajar, angka besar, label kecil
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildStatColumn(currentUser!.uid, true),
                                      const SizedBox(width: 40),
                                      _buildStatColumn(currentUser!.uid, false),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Padding(
                              padding: EdgeInsets.only(left: 32, bottom: 8),
                              child: Text("About Me",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ),
                            Container(
                              margin: const EdgeInsets.only(left: 32),
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                userData?['about'] ?? "",
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
