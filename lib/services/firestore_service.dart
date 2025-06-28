import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final CollectionReference notes;
  late final CollectionReference users;
  late final CollectionReference reports;

  FirestoreService() {
    notes = _firestore.collection('notes');
    users = _firestore.collection('users');
    reports = _firestore.collection('reports');
  }

  // Save user record
  Future<void> saveUserRecord(User user) {
    return users.doc(user.uid).set({
      'email': user.email,
      'uid': user.uid,
    }, SetOptions(merge: true));
  }

  // Add a new note
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
      'likes': [],
      'readCount': 0, // Inisialisasi readCount saat note baru dibuat
    });
  }

  // Invite user to note by email
  Future<String> inviteUserToNote(
      {required String noteId, required String email}) async {
    try {
      final querySnapshot =
          await users.where('email', isEqualTo: email).limit(1).get();
      if (querySnapshot.docs.isEmpty) {
        return "Error: User with email $email not found.";
      }
      final invitedUserId = querySnapshot.docs.first.id;
      await notes.doc(noteId).update({
        'allowed_users': FieldValue.arrayUnion([invitedUserId])
      });
      return "Success: $email has been invited to collaborate.";
    } catch (e) {
      return "Error: An error occurred. ${e.toString()}";
    }
  }

  // Get private notes (where user is in allowed_users)
  Stream<QuerySnapshot> getMyNotesStream() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();
    return notes
        .where('allowed_users', arrayContains: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get all public notes
  Stream<QuerySnapshot> getPublicNotesStream() {
    return notes
        .where('isPublic', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get public notes by ownerId (for public profile)
  Stream<QuerySnapshot> getPublicNotesByOwnerIdStream(String ownerId) {
    return notes
        .where('ownerId', isEqualTo: ownerId)
        .where('isPublic', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get a single note stream
  Stream<DocumentSnapshot> getNoteStream(String noteId) {
    return notes.doc(noteId).snapshots();
  }

  // --- FUNGSI UNTUK MENAIKKAN JUMLAH PEMBACA ---
  Future<void> incrementReadCount(String noteId) {
    return notes.doc(noteId).update({
      'readCount': FieldValue.increment(1),
    });
  }

  // --- FUNGSI STATISTIK YANG DIPERBAIKI ---
  Stream<Map<String, dynamic>> getNotesAndStatsForUser(String userId) {
    return notes.where('ownerId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return {'totalLikes': 0, 'totalReads': 0, 'dailyStats': <DateTime, Map<String, int>>{}};
        }

        int totalLikes = 0;
        int totalReads = 0;
        // Map<Tanggal Penuh, Map<Tipe, Jumlah>>
        Map<DateTime, Map<String, int>> dailyStats = {};

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          
          totalLikes += (data['likes'] as List?)?.length ?? 0;
          totalReads += (data['readCount'] as int?) ?? 0;
          
          final timestamp = (data['timestamp'] as Timestamp).toDate();
          // Membuat kunci berdasarkan tanggal (tanpa jam, menit, detik)
          final dayKey = DateTime(timestamp.year, timestamp.month, timestamp.day);

          if (!dailyStats.containsKey(dayKey)) {
            dailyStats[dayKey] = {'likes': 0, 'reads': 0};
          }
          
          dailyStats[dayKey]!['likes'] = (dailyStats[dayKey]!['likes'] ?? 0) + ((data['likes'] as List?)?.length ?? 0);
          dailyStats[dayKey]!['reads'] = (dailyStats[dayKey]!['reads'] ?? 0) + ((data['readCount'] as int?) ?? 0);
        }
        
        return {
          'totalLikes': totalLikes,
          'totalReads': totalReads,
          'dailyStats': dailyStats,
        };
      });
  }


  // Update a note
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

  // Delete a note
  Future<void> deleteNote(String docID) {
    return notes.doc(docID).delete();
  }

  // Toggle like on a note
  Future<void> toggleLike(String noteId, String userId, bool isLiked) {
    if (isLiked) {
      return notes.doc(noteId).update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } else {
      return notes.doc(noteId).update({
        'likes': FieldValue.arrayUnion([userId])
      });
    }
  }

  // ===================== KOMENTAR =====================
  
  Stream<QuerySnapshot> getCommentsStream(String noteId) {
    return notes
        .doc(noteId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> addComment({
    required String noteId,
    required String text,
    required String userId,
    required String userEmail,
    String? parentCommentId,
  }) {
    return notes.doc(noteId).collection('comments').add({
      'text': text,
      'userId': userId,
      'userEmail': userEmail,
      'timestamp': Timestamp.now(),
      'parentCommentId': parentCommentId,
      'likes': [],
    });
  }

  Future<void> deleteComment(String noteId, String commentId) async {
    try {
      await notes.doc(noteId).collection('comments').doc(commentId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // ===================== REPORT =====================

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
      'status': 'pending',
    });
  }

  // ===================== BOOKMARK =====================

  Future<void> toggleBookmark(String noteId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in.");

    final userBookmarkRef =
        users.doc(user.uid).collection('userBookmarks').doc(noteId);
    final noteRef = notes.doc(noteId);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot userBookmarkSnapshot =
          await transaction.get(userBookmarkRef);
      DocumentSnapshot noteSnapshot = await transaction.get(noteRef);

      if (!noteSnapshot.exists) throw Exception("Note does not exist!");

      if (userBookmarkSnapshot.exists) {
        transaction.delete(userBookmarkRef);
        transaction
            .update(noteRef, {'bookmarkCount': FieldValue.increment(-1)});
      } else {
        transaction
            .set(userBookmarkRef, {'timestamp': FieldValue.serverTimestamp()});
        transaction.update(noteRef, {'bookmarkCount': FieldValue.increment(1)});
      }
    });
  }

  Stream<bool> isNoteBookmarked(String noteId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
    return users
        .doc(user.uid)
        .collection('userBookmarks')
        .doc(noteId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // Get top picks notes (diurutkan berdasarkan jumlah bookmark)
  Stream<QuerySnapshot> getTopPicksNotesStream({int limit = 4}) {
    return notes
        .where('isPublic', isEqualTo: true)
        .orderBy('bookmarkCount', descending: true) // <-- DIKEMBALIKAN ke bookmarkCount
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  Stream<List<Map<String, dynamic>>> getUserBookmarksStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    return users
        .doc(user.uid)
        .collection('userBookmarks')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((bookmarkSnapshot) async {
      List<Map<String, dynamic>> bookmarkedNotes = [];
      if (bookmarkSnapshot.docs.isEmpty) return bookmarkedNotes;

      List<String> bookmarkedNoteIds =
          bookmarkSnapshot.docs.map((doc) => doc.id).toList();

      for (String noteId in bookmarkedNoteIds) {
        final noteDoc = await notes.doc(noteId).get();
        if (noteDoc.exists) {
          final noteData = noteDoc.data() as Map<String, dynamic>;
          bookmarkedNotes.add({'id': noteId, ...noteData});
        }
      }
      return bookmarkedNotes;
    });
  }

  // ===================== FOLLOW/UNFOLLOW =====================
  
  Future<void> toggleFollowUser(String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    if (user.uid == targetUserId) throw Exception("Cannot follow yourself");

    final currentUserRef = users.doc(user.uid);
    final targetUserRef = users.doc(targetUserId);

    final followingRef =
        currentUserRef.collection('following').doc(targetUserId);
    final followerRef = targetUserRef.collection('followers').doc(user.uid);

    final followingDoc = await followingRef.get();

    if (followingDoc.exists) {
      await followingRef.delete();
      await followerRef.delete();
    } else {
      await followingRef.set({
        'userId': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await followerRef.set({
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<bool> isFollowingUser(String targetUserId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
    if (user.uid == targetUserId) return Stream.value(false);

    return users
        .doc(user.uid)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<int> getFollowersCount(String userId) {
    return users
        .doc(userId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getFollowingCount(String userId) {
    return users
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final doc = await users.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print("Error getting user: $e");
      return null;
    }
  }

  Future<void> followUser(String targetUserId, String currentUserId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId)
        .set({'timestamp': FieldValue.serverTimestamp()});
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }

  Future<void> unfollowUser(String targetUserId, String currentUserId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId)
        .delete();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .delete();
  }

  Stream<bool> isFollowing(String targetUserId, String currentUserId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
