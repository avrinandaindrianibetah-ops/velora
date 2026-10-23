
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:android_id/android_id.dart';

import '../main.dart';
import '../services/audit_service.dart' as audit;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nimC = TextEditingController();
  final _passC = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nimC.dispose();
    _passC.dispose();
    super.dispose();
  }

  void _showError(
    String message, {
    IconData icon = Icons.error_outline,
  }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _login() async {
    if (_loading) return;

    final nim = _nimC.text.trim();
    final password = _passC.text;

    if (nim.isEmpty || password.isEmpty) {
      _showError('NIM dan password wajib diisi.');
      return;
    }

    if (nim.length < 6) {
      _showError('NIM minimal 6 karakter.');
      return;
    }

    // Pertahankan aturan login sesuai rancangan MVP kamu.
    if (password != nim) {
      _showError(
        'Password salah. Password harus sama dengan NIM.',
        icon: Icons.lock_outline,
      );
      return;
    }

    setState(() => _loading = true);
    kLoggingIn.value = true;

    final auth = FirebaseAuth.instance;

    try {
      final email = '$nim@velora.uniman.ac.id';

      // Login dahulu. Akun baru hanya dibuat jika benar-benar
      // belum terdaftar, bukan untuk setiap kegagalan login.
      try {
        await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          await auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final user = auth.currentUser;

      if (user == null) {
        throw Exception('Pengguna tidak ditemukan setelah login.');
      }

      // Baca Android ID perangkat.
      final deviceId = await const AndroidId().getId();

      if (deviceId == null || deviceId.isEmpty) {
        throw Exception('ID perangkat tidak dapat dibaca.');
      }

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        // Profil awal untuk akun yang baru dibuat.
        await userRef.set({
          'uid': user.uid,
          'nim_nidn': nim,
          'nama_lengkap': 'Mahasiswa $nim',
          'role': 'Mahasiswa',
          'device_uuid': deviceId,
          'total_alpha': 0,
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        final data = userDoc.data();
        final savedDeviceId = data?['device_uuid'];

        if (savedDeviceId == null ||
            savedDeviceId.toString().isEmpty) {
          // Mengikat perangkat jika belum ada.
          await userRef.update({
            'device_uuid': deviceId,
          });
        } else if (savedDeviceId != deviceId) {
          // Tolak login dari perangkat berbeda.
          await audit.AuditService.log(
            'Login perangkat asing',
            detail: 'NIM: $nim',
          );

          await auth.signOut();

          _showError(
            'Login ditolak. Akun terikat pada perangkat lain.',
            icon: Icons.phonelink_lock,
          );

          return;
        }
      }

      // Tidak perlu Navigator.push di sini.
      // main.dart menangani perpindahan ke Dashboard
      // melalui authStateChanges().
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'wrong-password':
          message = 'Password akun tidak sesuai.';
          break;
        case 'invalid-credential':
          message = 'NIM atau password tidak valid.';
          break;
        case 'email-already-in-use':
          message = 'Akun sudah terdaftar. Silakan masuk kembali.';
          break;
        case 'weak-password':
          message = 'Password tidak memenuhi ketentuan Firebase.';
          break;
        case 'network-request-failed':
          message = 'Koneksi internet bermasalah.';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan. Coba lagi nanti.';
          break;
        default:
          message = 'Autentikasi gagal: ${e.message ?? e.code}';
      }

      _showError(message);

      if (auth.currentUser != null) {
        await auth.signOut();
      }
    } catch (e) {
      _showError('Gagal masuk: $e');

      if (auth.currentUser != null) {
        await auth.signOut();
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }

      kLoggingIn.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF06142F),
              Color(0xFF0B1F4B),
              Color(0xFF14506B),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                        border: Border.all(
                          color: Colors.white54,
                          width: 2,
                        ),
                      ),
                      child: const Text(
                        'V',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'VELORA',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Monitoring Kehadiran Mahasiswa\nPTIK FT UNIMA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    _field(
                      _nimC,
                      'NIM',
                      Icons.badge_outlined,
                      keyboard: TextInputType.number,
                    ),
                    const SizedBox(height: 14),

                    _field(
                      _passC,
                      'Password',
                      Icons.lock_outline,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() => _obscure = !_obscure);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.greenAccent.withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 16,
                            color: Colors.greenAccent,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Hardware UUID • Terverifikasi',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1B8A9E),
                          disabledBackgroundColor: Colors.white24,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'MASUK SISTEM',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.lightBlueAccent,
            width: 2,
          ),
        ),
      ),
    );
  }
}
