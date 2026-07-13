import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cek user yang sedang login
  User? get currentUser => _auth.currentUser;

  // Stream perubahan status login
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Cek apakah dokumen user sudah ada di Firestore
      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      // Kalau belum ada, buat dokumen baru
      if (!doc.exists) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'phone': '',
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Update FCM token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // --- REGISTER dengan Email & Password ---
  Future<UserCredential?> register({
    required String email,
    required String password,
    required String name,
    String phone = '',
  }) async {
    try {
      // 1. Buat akun di Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // 2. Simpan nama ke profil Firebase Auth
      await credential.user?.updateDisplayName(name.trim());

      // 3. Simpan data lengkap ke Firestore koleksi 'users'
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': 'customer', // default role pelanggan
        'createdAt': FieldValue.serverTimestamp(),
      });

      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // --- LOGIN dengan Email & Password ---
  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }

      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();
      if (doc.exists) {
        String role = doc.data()?['role'] ?? 'customer';
        if (role != 'customer') {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'unauthorized-role',
            message: 'Akun ini tidak memiliki akses sebagai pelanggan.',
          );
        }
      } else {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.',
        );
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // --- AMBIL DATA USER dari Firestore ---
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    await _auth.signOut();
  }

  // --- Terjemahan error Firebase ke pesan yang ramah user ---
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan login.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'user-not-found':
        return 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
      case 'wrong-password':
        return 'Password salah. Coba lagi.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba beberapa saat lagi.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }
}
