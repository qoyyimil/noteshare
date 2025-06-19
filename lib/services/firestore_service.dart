import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final CollectionReference notes;
  late final CollectionReference users; // <-- Koleksi baru untuk data pengguna

  FirestoreService() {
    notes = _firestore.collection('notes');
    users = _firestore.collection('users'); // <-- Inisialisasi
  }

  // FUNGSI BARU: Menyimpan data pengguna ke koleksi 'users'
  Future<void> saveUserRecord(User user) {
    return users.doc(user.uid).set({
      'email': user.email,
      'uid': user.uid,
    });
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
      'ownerId': currentUser.uid, // Ganti nama dari 'userId' untuk kejelasan
      'userEmail': currentUser.email,
      // Daftar pengguna yang diizinkan (awal: hanya pemilik)
      'allowed_users': [currentUser.uid], 
    });
  }

  // FUNGSI BARU: Undang pengguna ke catatan berdasarkan email
  Future<String> inviteUserToNote({required String noteId, required String email}) async {
    try {
      // 1. Cari pengguna berdasarkan email di koleksi 'users'
      final querySnapshot = await users.where('email', isEqualTo: email).limit(1).get();

      if (querySnapshot.docs.isEmpty) {
        return "Error: Pengguna dengan email tersebut tidak ditemukan.";
      }

      // 2. Jika ditemukan, dapatkan ID-nya
      final invitedUserId = querySnapshot.docs.first.id;

      // 3. Tambahkan ID pengguna tersebut ke daftar 'allowed_users' pada catatan
      await notes.doc(noteId).update({
        'allowed_users': FieldValue.arrayUnion([invitedUserId])
      });
      
      return "Sukses: ${email} telah diundang untuk berkolaborasi.";
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

  // Fungsi lain tidak berubah
  Future<void> updateNote(String docID, String newTitle, String newContent, String newCategory, bool newIsPublic) {
    return notes.doc(docID).update({ 'title': newTitle, 'content': newContent, 'category': newCategory, 'isPublic': newIsPublic, 'timestamp': Timestamp.now() });
  }
  Future<void> deleteNote(String docID) { return notes.doc(docID).delete(); }
  Stream<QuerySnapshot> getPublicNotesStream() {
    return notes.where('isPublic', isEqualTo: true).orderBy('timestamp', descending: true).snapshots();
  }
}