
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'local_queue.dart';

class SyncService {
  static bool _busy = false;

  static Future<int> flush() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _busy) return 0;

    _busy = true;
    var syncedCount = 0;

    try {
      final rows = await LocalQueue.all(user.uid);

      for (final row in rows) {
        try {
          // Jangan mengunggah antrean milik akun lain.
          if (row['uid'] != user.uid) continue;

          await _push(row).timeout(
            const Duration(seconds: 25),
          );

          await LocalQueue.remove(row['id'] as String);
          syncedCount++;
        } catch (_) {
          // Pertahankan antrean jika proses gagal.
          // Coba lagi pada sinkronisasi berikutnya.
          continue;
        }
      }
    } finally {
      _busy = false;
    }

    return syncedCount;
  }

  static Future<void> _push(
    Map<String, Object?> row,
  ) async {
    final id = row['id'] as String;
    final uid = row['uid'] as String;

    final firestore = FirebaseFirestore.instance;
    final doc = firestore.collection('attendance_records').doc(id);

    final storageRef =
        FirebaseStorage.instance.ref('presensi/$uid/$id.jpg');

    final photoPath = row['foto_path'] as String?;
    if (photoPath == null || photoPath.isEmpty) {
      throw Exception('Lokasi foto presensi tidak tersedia.');
    }

    final file = File(photoPath);

    if (!await file.exists()) {
      throw Exception('Foto lokal tidak ditemukan. Antrean dipertahankan.');
    }

    // Unggah foto terlebih dahulu.
    // Jika gagal, dokumen tidak ditandai selesai.
    final existing = await doc.get();

    String photoUrl;

    if (existing.exists &&
        existing.data()?['foto_url'] is String &&
        (existing.data()!['foto_url'] as String).isNotEmpty) {
      photoUrl = existing.data()!['foto_url'] as String;
    } else {
      await storageRef.putFile(file);
      photoUrl = await storageRef.getDownloadURL();
    }

    final lat = (row['lat'] as num).toDouble();
    final lng = (row['lng'] as num).toDouble();
    final localMillis = row['waktu_lokal'] as int;

    // Merge mempertahankan field lain yang mungkin sudah ada.
    await doc.set({
      'record_id': id,
      'mahasiswa_id': uid,
      'kode_mk': row['kode_mk'],
      'mata_kuliah': row['mata_kuliah'],
      'tanggal': row['tanggal'],
      'status': 'Hadir',
      'waktu_absen': FieldValue.serverTimestamp(),
      'waktu_lokal':
          Timestamp.fromMillisecondsSinceEpoch(localMillis),
      'titik_kordinat': GeoPoint(lat, lng),
      'device_uuid': row['device_uuid'],
      'status_sinkronisasi': true,
      'foto_url': photoUrl,
    }, SetOptions(merge: true));

    // Hapus foto hanya setelah Firestore berhasil ditulis.
    await file.delete();
  }
}
