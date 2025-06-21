import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final CollectionReference notes;
  late final CollectionReference users;
  late final CollectionReference reports; // <-- ADDED for reports

  FirestoreService() {
    notes = _firestore.collection('notes');
    users = _firestore.collection('users');
    reports = _firestore.collection('reports'); // <-- ADDED for reports
  }

  // FUNGSI BARU: Menyimpan data pengguna ke koleksi 'users'
  Future<void> saveUserRecord(User user) {
    return users.doc(user.uid).set({
      'email': user.email,
      'uid': user.uid,
    }, SetOptions(merge: true));
  }

  // CREATE: add a new note
  Future<void> addNote(
      String title, String content, String category, bool isPublic) {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not logged in.");

    return notes.add({
      'title': title,
      'content': content,
      'category': category,
      'isPublic': isPublic,
      'timestamp': Timestamp.now(),
      'ownerId': currentUser.uid,
      'userEmail': currentUser.email,
      'allowed_users': [currentUser.uid],
      'bookmarkCount': 0,
      'likes': [], // <-- NEW: Initialize likes array
    });
  }

  // FUNGSI BARU: Undang pengguna ke catatan berdasarkan email
  Future<String> inviteUserToNote(
      {required String noteId, required String email}) async {
    try {
      final querySnapshot =
          await users.where('email', isEqualTo: email).limit(1).get();

      if (querySnapshot.docs.isEmpty) {
        return "Error: Pengguna dengan email tersebut tidak ditemukan.";
      }

      final invitedUserId = querySnapshot.docs.first.id;

      await notes.doc(noteId).update({
        'allowed_users': FieldValue.arrayUnion([invitedUserId])
      });

      return "Sukses: $email telah diundang untuk berkolaborasi.";
    } catch (e) {
      return "Error: Terjadi kesalahan. ${e.toString()}";
    }
  }

  // READ (Privat): Ambil catatan di mana ID saya ada di dalam daftar 'allowed_users'
  Stream<QuerySnapshot> getMyNotesStream() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return notes
        .where('allowed_users', arrayContains: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // READ (Public): Ambil catatan publik
  Stream<QuerySnapshot> getPublicNotesStream() {
    return notes
        .where('isPublic', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get a stream of a single note document for real-time updates
  Stream<DocumentSnapshot> getNoteStream(String noteId) {
    return notes.doc(noteId).snapshots();
  }

  // UPDATE: update an existing note
  Future<void> updateNote(String docID, String newTitle, String newContent,
      String newCategory, bool newIsPublic) {
    return notes.doc(docID).update({
      'title': newTitle,
      'content': newContent,
      'category': newCategory,
      'isPublic': newIsPublic,
      'timestamp': Timestamp.now(),
    });
  }

  // DELETE: delete a note
  Future<void> deleteNote(String docID) {
    return notes.doc(docID).delete();
  }

  // --- LIKE, COMMENT, AND REPORT METHODS ---

  // Toggle like on a note
  Future<void> toggleLike(String noteId, String userId, bool isLiked) {
    if (isLiked) {
      // Atomically remove user's ID from the 'likes' array
      return notes.doc(noteId).update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } else {
      // Atomically add user's ID to the 'likes' array
      return notes.doc(noteId).update({
        'likes': FieldValue.arrayUnion([userId])
      });
    }
  }

  // Get a stream of comments for a note, ordered by timestamp
  Stream<QuerySnapshot> getCommentsStream(String noteId) {
    return notes
        .doc(noteId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Add a new comment or reply
  Future<void> addComment({
    required String noteId,
    required String text,
    required String userId,
    required String userEmail,
    String? parentCommentId, // Optional: for replies
  }) {
    return notes.doc(noteId).collection('comments').add({
      'text': text,
      'userId': userId,
      'userEmail': userEmail,
      'timestamp': Timestamp.now(),
      'parentCommentId': parentCommentId,
      'likes': [], // Array of userIds who liked the comment
    });
  }

  // Add a report for a note
  Future<void> addReport({
    required String noteId,
    required String noteOwnerId,
    required String reporterId,
    required String reason,
    required String details,
  }) {
    return reports.add({
      'noteId': noteId,
      'noteOwnerId': noteOwnerId,
      'reporterId': reporterId,
      'reason': reason,
      'details': details,
      'timestamp': Timestamp.now(),
      'status': 'pending', // e.g., pending, reviewed, resolved
    });
  }


  // --- BOOKMARKING AND TOP PICKS FUNCTIONS ---

  // Method to toggle bookmark status and update bookmarkCount
  Future<void> toggleBookmark(String noteId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in.");
    }

    final userBookmarkRef =
        users.doc(user.uid).collection('userBookmarks').doc(noteId);
    final noteRef = notes.doc(noteId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot userBookmarkSnapshot =
          await transaction.get(userBookmarkRef);
      DocumentSnapshot noteSnapshot = await transaction.get(noteRef);

      if (!noteSnapshot.exists) {
        throw Exception("Note does not exist!");
      }

      if (userBookmarkSnapshot.exists) {
        // User has bookmarked it, so unbookmark
        transaction.delete(userBookmarkRef);
        transaction.update(noteRef, {'bookmarkCount': FieldValue.increment(-1)});
      } else {
        // User has not bookmarked it, so bookmark
        transaction.set(
            userBookmarkRef, {'timestamp': FieldValue.serverTimestamp()});
        transaction.update(noteRef, {'bookmarkCount': FieldValue.increment(1)});
      }
    }).catchError((error) {
      print("Failed to toggle bookmark: $error");
      throw error;
    });
  }

  // Method to check if a user has bookmarked a specific note
  Stream<bool> isNoteBookmarked(String noteId) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }
    return users
        .doc(user.uid)
        .collection('userBookmarks')
        .doc(noteId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // Stream to get Top Picks (notes ordered by bookmarkCount)
  Stream<QuerySnapshot> getTopPicksNotesStream({int limit = 4}) {
    return notes
        .where('isPublic', isEqualTo: true)
        .orderBy('bookmarkCount', descending: true)
        .orderBy('timestamp',
            descending: true) // Secondary sort for tie-breaking
        .limit(limit)
        .snapshots();
  }

  // Stream to get a user's bookmarked notes for "Perpustakaan"
  Stream<List<Map<String, dynamic>>> getUserBookmarksStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]); // Return an empty list if no user
    }

    return users
        .doc(user.uid)
        .collection('userBookmarks')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((bookmarkSnapshot) async {
      List<Map<String, dynamic>> bookmarkedNotes = [];
      if (bookmarkSnapshot.docs.isEmpty) {
        return bookmarkedNotes;
      }

      List<String> bookmarkedNoteIds =
          bookmarkSnapshot.docs.map((doc) => doc.id).toList();

      if (bookmarkedNoteIds.isNotEmpty) {
        // Firestore 'whereIn' is limited. For many bookmarks, batching is needed.
        // This implementation fetches one by one for simplicity and robustness.
        for (String noteId in bookmarkedNoteIds) {
          final noteDoc = await notes.doc(noteId).get();
          if (noteDoc.exists) {
            final noteData = noteDoc.data() as Map<String, dynamic>;
            bookmarkedNotes.add({'id': noteId, ...noteData});
          }
        }
      }
      return bookmarkedNotes;
    });
  }
}
