
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditService {
  AuditService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static Future<void> log(
    String action, {
    String? detail,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      await _firestore.collection('audit_logs').add({
        'action': action,
        'detail': detail ?? '',
        'uid': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Kegagalan pencatatan audit tidak boleh
      // menghentikan proses utama aplikasi.
      // Catat error saat proses debugging.
    }
  }
}
