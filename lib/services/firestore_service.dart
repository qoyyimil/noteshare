// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- ADDED: Enum for notification types for easier management ---
enum NotificationType { like, comment, follow, purchase }

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

  // ===============================================================
  // --- NEW FUNCTIONS FOR CREATOR EARNINGS & WITHDRAWALS ---
  // ===============================================================

  // Request a dummy withdrawal
  Future<void> requestWithdrawal({
    required String userId,
    required int amount,
    required String method,
    required String accountNumber,
  }) async {
    final userRef = users.doc(userId);
    final userSnapshot = await userRef.get();
    
    if (!userSnapshot.exists) {
      throw Exception("User not found.");
    }

    final userData = userSnapshot.data() as Map<String, dynamic>;
    final currentCoins = userData['coins'] ?? 0;

    if (amount <= 0) {
      throw Exception("Withdrawal amount must be greater than zero.");
    }
    if (currentCoins < amount) {
      throw Exception("Insufficient coins for withdrawal.");
    }

    // Use a transaction to ensure atomicity
    await _firestore.runTransaction((transaction) async {
      // 1. Deduct coins from the user's wallet
      transaction.update(userRef, {'coins': FieldValue.increment(-amount)});

      // 2. Create a record in the withdrawals sub-collection
      final withdrawalRef = userRef.collection('withdrawals').doc();
      transaction.set(withdrawalRef, {
        'amount': amount,
        'method': method,
        'accountDetails': accountNumber,
        'status': 'Pending', // In a real app, this would be processed by an admin
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  // Get the stream of earnings for a creator
  Stream<QuerySnapshot> getEarningsHistory(String userId) {
    return users
        .doc(userId)
        .collection('earnings')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get the stream of withdrawal history for a creator
  Stream<QuerySnapshot> getWithdrawalHistory(String userId) {
    return users
        .doc(userId)
        .collection('withdrawals')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  
  // ===============================================================
  // --- EXISTING FUNCTIONS (Unchanged or Modified) ---
  // ===============================================================

  // Get user data stream in real-time (includes coins and premium status)
  Stream<DocumentSnapshot> getUserStream(String userId) {
    return users.doc(userId).snapshots();
  }

  // Add coins to a user's account (for the dummy top-up system)
  Future<void> addCoinsToUser(String userId, int coinsToAdd) {
    if (coinsToAdd <= 0) {
      throw Exception("Coin amount must be positive.");
    }
    final userRef = users.doc(userId);
    return userRef.update({
      'coins': FieldValue.increment(coinsToAdd),
    });
  }

  // MODIFIED: This function now logs earnings and sends notifications.
  Future<String> purchaseNote(String userId, String noteId) async {
    final userRef = users.doc(userId);
    final noteRef = notes.doc(noteId);

    return await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final noteSnapshot = await transaction.get(noteRef);

      if (!userSnapshot.exists || !noteSnapshot.exists) {
        throw Exception("User or Note not found!");
      }

      final userData = userSnapshot.data() as Map<String, dynamic>;
      final noteData = noteSnapshot.data() as Map<String, dynamic>;

      final int userCoins = userData['coins'] ?? 0;
      final int notePrice = noteData['coinPrice'] ?? 0;
      final String authorId = noteData['ownerId'];
      final String noteTitle = noteData['title'] ?? 'Untitled Note';
      final String authorName = noteData['fullName'] ?? 'An author';

      if (userCoins < notePrice) {
        return "Not enough coins!";
      }

      // 1. Deduct coins from the buyer
      transaction.update(userRef, {'coins': FieldValue.increment(-notePrice)});

      // 2. Add the buyer's UID to the note's purchasedBy list
      transaction.update(
          noteRef, {'purchasedBy': FieldValue.arrayUnion([userId])});

      // 3. Give a share of the coins to the author and log the earning
      final int authorShare = (notePrice * 0.8).toInt();
      if (authorShare > 0) {
        final authorRef = users.doc(authorId);
        transaction
            .update(authorRef, {'coins': FieldValue.increment(authorShare)});

        final earningRef = authorRef.collection('earnings').doc();
        transaction.set(earningRef, {
          'noteId': noteId,
          'noteTitle': noteTitle,
          'coinsEarned': authorShare,
          'buyerId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // --- TAMBAHAN: KIRIM NOTIFIKASI ---
      // Notifikasi untuk Pembeli
      await addNotification(
        targetUserId: userId,
        type: NotificationType.purchase,
        fromUserName: "System", // Atau nama aplikasi Anda
        noteId: noteId,
        noteTitle: noteTitle,
        message: "You have successfully purchased '$noteTitle'.",
      );

      return "Purchase successful!";
    });
  }

  // Check if a user is eligible to post premium content.
  Future<bool> checkPremiumEligibility(String userId) async {
    const int requiredFollowers = 50;
    const int requiredLikes = 100;

    final followersSnapshot = await users.doc(userId).collection('followers').get();
    if (followersSnapshot.docs.length < requiredFollowers) return false;

    final notesSnapshot = await notes.where('ownerId', isEqualTo: userId).get();
    int totalLikes = 0;
    for (var doc in notesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalLikes += (data['likes'] as List?)?.length ?? 0;
    }
    if (totalLikes < requiredLikes) return false;

    return true;
  }

  // --- NOTIFICATION FUNCTIONS ---
  Future<void> addNotification({
    required String targetUserId,
    required NotificationType type,
    required String fromUserName,
    String? noteId,
    String? noteTitle,
    String? message, // Tambahkan parameter message
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || targetUserId == currentUser.uid) return;

    await users.doc(targetUserId).collection('notifications').add({
      'type': type.name,
      'fromUserId': currentUser.uid,
      'fromUserName': fromUserName,
      'noteId': noteId,
      'noteTitle': noteTitle,
      'message': message, // Simpan pesan kustom
      'timestamp': Timestamp.now(),
      'isRead': false,
    });
  }

  Stream<QuerySnapshot> getNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return users
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  
  Stream<int> getUnreadNotificationsCountStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);
    return users
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAllNotificationsAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final unreadNotifs = await users
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    WriteBatch batch = _firestore.batch();
    for (var doc in unreadNotifs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // --- CORE NOTE AND USER FUNCTIONS ---
  Future<void> saveUserRecord(User user) {
    return users.doc(user.uid).set({
      'email': user.email,
      'uid': user.uid,
      'coins': 0,
      'canPostPremium': false,
    }, SetOptions(merge: true));
  }

  Future<void> addNote(
    String title,
    String content,
    String category,
    bool isPublic, {
    required String fullName,
    required String userId,
    required String? userEmail,
    bool isPremium = false,
    int coinPrice = 0,
  }) {
    return notes.add({
      'title': title,
      'content': content,
      'category': category,
      'isPublic': isPublic,
      'timestamp': Timestamp.now(),
      'ownerId': userId,
      'userEmail': userEmail,
      'fullName': fullName, 
      'allowed_users': [userId],
      'bookmarkCount': 0,
      'likes': [],
      'readCount': 0,
      'isPremium': isPremium,
      'coinPrice': coinPrice,
      'purchasedBy': [],
    });
  }

  Future<void> updateNote(String docID, String newTitle, String newContent,
      String newCategory, bool newIsPublic, {bool isPremium = false, int coinPrice = 0}) {
    return notes.doc(docID).update({
      'title': newTitle,
      'content': newContent,
      'category': newCategory,
      'isPublic': newIsPublic,
      'timestamp': Timestamp.now(),
      'isPremium': isPremium,
      'coinPrice': coinPrice,
    });
  }

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

  Stream<QuerySnapshot> getMyNotesStream() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();
    return notes
        .where('allowed_users', arrayContains: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // =======================================================
  // --- INI FUNGSI BARU YANG SAYA TAMBAHKAN ---
  Stream<QuerySnapshot> getNotesByOwner(String userId) {
    return notes
        .where('ownerId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  // =======================================================

  Stream<QuerySnapshot> getPublicNotesStream() {
    return notes
        .where('isPublic', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPublicNotesByOwnerIdStream(String ownerId) {
    return notes
        .where('ownerId', isEqualTo: ownerId)
        .where('isPublic', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getNoteStream(String noteId) {
    return notes.doc(noteId).snapshots();
  }

  Future<void> incrementReadCount(String noteId) {
    return notes.doc(noteId).update({
      'readCount': FieldValue.increment(1),
    });
  }

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
        Map<DateTime, Map<String, int>> dailyStats = {};
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalLikes += (data['likes'] as List?)?.length ?? 0;
          totalReads += (data['readCount'] as int?) ?? 0;
          final timestamp = (data['timestamp'] as Timestamp).toDate();
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

  Future<void> deleteNote(String docID) {
    return notes.doc(docID).delete();
  }

  Future<void> toggleLike(String noteId, String userId, bool isLiked) async {
    final noteRef = notes.doc(noteId);
    if (isLiked) {
      await noteRef.update({'likes': FieldValue.arrayRemove([userId])});
    } else {
      await noteRef.update({'likes': FieldValue.arrayUnion([userId])});
      final noteDoc = await noteRef.get();
      if (noteDoc.exists) {
        final noteData = noteDoc.data() as Map<String, dynamic>;
        await addNotification(
          targetUserId: noteData['ownerId'], 
          type: NotificationType.like, 
          fromUserName: _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? "Someone", 
          noteId: noteId,
          noteTitle: noteData['title']
        );
      }
    }
  }
  
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
  }) async { 
    await notes.doc(noteId).collection('comments').add({
      'text': text,
      'userId': userId,
      'userEmail': userEmail,
      'timestamp': Timestamp.now(),
      'parentCommentId': parentCommentId,
      'likes': [],
    });
    final noteDoc = await notes.doc(noteId).get();
    if (noteDoc.exists) {
      final noteData = noteDoc.data() as Map<String, dynamic>;
      await addNotification(
        targetUserId: noteData['ownerId'], 
        type: NotificationType.comment, 
        fromUserName: userEmail,
        noteId: noteId,
        noteTitle: noteData['title']
      );
    }
  }

  Future<void> deleteComment(String noteId, String commentId) async {
    try {
      await notes.doc(noteId).collection('comments').doc(commentId).delete();
    } catch (e) {
      rethrow;
    }
  }

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

  Future<void> toggleBookmark(String noteId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in.");

    final userBookmarkRef =
        users.doc(user.uid).collection('userBookmarks').doc(noteId);
    final noteRef = notes.doc(noteId);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot userBookmarkSnapshot = await transaction.get(userBookmarkRef);
      DocumentSnapshot noteSnapshot = await transaction.get(noteRef);

      if (!noteSnapshot.exists) throw Exception("Note does not exist!");

      if (userBookmarkSnapshot.exists) {
        transaction.delete(userBookmarkRef);
        transaction.update(noteRef, {'bookmarkCount': FieldValue.increment(-1)});
      } else {
        transaction.set(userBookmarkRef, {'timestamp': FieldValue.serverTimestamp()});
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

  Stream<QuerySnapshot> getTopPicksNotesStream({int limit = 4}) {
    return notes
        .where('isPublic', isEqualTo: true)
        .orderBy('bookmarkCount', descending: true)
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

  Future<void> toggleFollowUser(String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    if (user.uid == targetUserId) throw Exception("Cannot follow yourself");

    final currentUserRef = users.doc(user.uid);
    final targetUserRef = users.doc(targetUserId);

    final followingRef = currentUserRef.collection('following').doc(targetUserId);
    final followerRef = targetUserRef.collection('followers').doc(user.uid);

    final followingDoc = await followingRef.get();

    if (followingDoc.exists) {
      await followingRef.delete();
      await followerRef.delete();
    } else {
      await followingRef.set({'userId': targetUserId, 'timestamp': FieldValue.serverTimestamp()});
      await followerRef.set({'userId': user.uid, 'timestamp': FieldValue.serverTimestamp()});
      await addNotification(
        targetUserId: targetUserId, 
        type: NotificationType.follow, 
        fromUserName: user.displayName ?? user.email ?? "Someone"
      );
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