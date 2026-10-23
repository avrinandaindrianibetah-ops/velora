
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

final ValueNotifier<bool> kLoggingIn = ValueNotifier<bool>(false);
const Color kNavy = Color(0xFF0B1F4B);
const Color kBlue = Color(0xFF1E5AA8);
const Color kTeal = Color(0xFF1B8A9E);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();

    runApp(const VeloraApp());
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization error: $error');
    debugPrintStack(stackTrace: stackTrace);

    runApp(
      VeloraStartupError(
        message:
            'VELORA gagal terhubung ke Firebase. '
            'Periksa konfigurasi Firebase dan koneksi aplikasi.',
      ),
    );
  }
}

class VeloraApp extends StatelessWidget {
  const VeloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VELORA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBlue,
          primary: kBlue,
          secondary: kTeal,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F5FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: kNavy,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Mengatur tampilan berdasarkan status autentikasi Firebase.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: kTeal,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const VeloraStartupError(
            message:
                'Gagal memeriksa status login. '
                'Silakan periksa koneksi dan konfigurasi Firebase.',
          );
        }

        if (snapshot.data != null) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

/// Ditampilkan jika aplikasi gagal melakukan inisialisasi.
class VeloraStartupError extends StatelessWidget {
  final String message;

  const VeloraStartupError({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VELORA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kBlue),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 64,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'VELORA tidak dapat dimulai',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () { 
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const VeloraStartupError(
                            message:
                                'Silakan tutup dan buka kembali '
                                'aplikasi setelah konfigurasi diperbaiki.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Informasi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
