import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final CollectionReference notes;
  late final CollectionReference users;

  FirestoreService() {
    notes = _firestore.collection('notes');
    users = _firestore.collection('users');
  }

  // FUNGSI BARU: Menyimpan data pengguna ke koleksi 'users'
  Future<void> saveUserRecord(User user) {
    return users.doc(user.uid).set({
      'email': user.email,
      'uid': user.uid,
    }, SetOptions(merge: true)); 
  }

  // CREATE: add a new note
  Future<void> addNote(String title, String content, String category, bool isPublic) {
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
      'bookmarkCount': 0, // <-- NEW: Initialize bookmark count
    });
  }

  // FUNGSI BARU: Undang pengguna ke catatan berdasarkan email
  Future<String> inviteUserToNote({required String noteId, required String email}) async {
    try {
      final querySnapshot = await users.where('email', isEqualTo: email).limit(1).get();

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
    return notes.where('isPublic', isEqualTo: true).orderBy('timestamp', descending: true).snapshots();
  }

  // UPDATE: update an existing note
  Future<void> updateNote(String docID, String newTitle, String newContent, String newCategory, bool newIsPublic) {
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

  // --- NEW BOOKMARKING AND TOP PICKS FUNCTIONS ---

  // Method to toggle bookmark status and update bookmarkCount
  Future<void> toggleBookmark(String noteId) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User not logged in. Cannot bookmark.");
      // Consider throwing an error or showing a SnackBar here
      throw Exception("User not logged in.");
    }

    // Reference to the user's specific bookmark document for this note
    final userBookmarkRef = users.doc(user.uid).collection('userBookmarks').doc(noteId);
    // Reference to the note document
    final noteRef = notes.doc(noteId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot userBookmarkSnapshot = await transaction.get(userBookmarkRef);
      DocumentSnapshot noteSnapshot = await transaction.get(noteRef);

      if (!noteSnapshot.exists) {
        throw Exception("Note does not exist!");
      }

      // Ensure bookmarkCount exists and is an integer, default to 0 if not
      int currentBookmarkCount = (noteSnapshot.data() as Map<String, dynamic>)['bookmarkCount'] as int? ?? 0;

      if (userBookmarkSnapshot.exists) {
        // User has bookmarked it, so unbookmark
        transaction.delete(userBookmarkRef);
        transaction.update(noteRef, {'bookmarkCount': FieldValue.increment(-1)});
        print("Note $noteId unbookmarked by user ${user.uid}. New count: ${currentBookmarkCount - 1}");
      } else {
        // User has not bookmarked it, so bookmark
        transaction.set(userBookmarkRef, {'timestamp': FieldValue.serverTimestamp()});
        transaction.update(noteRef, {'bookmarkCount': FieldValue.increment(1)});
        print("Note $noteId bookmarked by user ${user.uid}. New count: ${currentBookmarkCount + 1}");
      }
    }).catchError((error) {
      print("Failed to toggle bookmark: $error");
      // Re-throw or handle more gracefully in UI
      throw error;
    });
  }

  // Method to check if a user has bookmarked a specific note
  Stream<bool> isNoteBookmarked(String noteId) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(false); // Return false if no user is logged in
    }
    return users.doc(user.uid).collection('userBookmarks').doc(noteId).snapshots().map((snapshot) => snapshot.exists);
  }

  // Stream to get Top Picks (notes ordered by bookmarkCount)
  Stream<QuerySnapshot> getTopPicksNotesStream({int limit = 4}) {
    return notes
        .where('isPublic', isEqualTo: true)
        .orderBy('bookmarkCount', descending: true)
        .orderBy('timestamp', descending: true) // Secondary sort for tie-breaking
        .limit(limit)
        .snapshots();
  }

  // Stream to get a user's bookmarked notes for "Perpustakaan"
  Stream<List<Map<String, dynamic>>> getUserBookmarksStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]); // Return an empty list if no user
    }

    // First, get the list of note IDs bookmarked by the user
    return users
        .doc(user.uid)
        .collection('userBookmarks')
        .orderBy('timestamp', descending: true) // Order by when they were bookmarked
        .snapshots()
        .asyncMap((bookmarkSnapshot) async {
      List<Map<String, dynamic>> bookmarkedNotes = [];
      if (bookmarkSnapshot.docs.isEmpty) {
        return bookmarkedNotes;
      }

      // Collect all note IDs from bookmarks
      List<String> bookmarkedNoteIds = bookmarkSnapshot.docs.map((doc) => doc.id).toList();

      // Firestore 'in' query can handle up to 10 items. For more, you'd need multiple queries or a Cloud Function.
      // For simplicity, let's assume limit is not an issue here for typical bookmark counts,
      // or you can implement batching if many bookmarks are expected.
      // If you anticipate more than 10-30 bookmarks per user, consider fetching notes one by one
      // or implementing a more advanced querying strategy.

      if (bookmarkedNoteIds.isNotEmpty) {
        // Fetch the actual note documents based on their IDs
        // Note: Firestore 'whereIn' clause has a limit of 10 items.
        // For more than 10 bookmarks, you would need to break this into multiple queries
        // or fetch each note individually. For this example, assuming a manageable number.
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