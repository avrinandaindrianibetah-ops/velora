import 'package:flutter/material.dart';

void main() {
  runApp(const VeloraApp());
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
          seedColor: const Color(0xFF3157D5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FC),
      ),
      home: const LoginPage(),
    );
  }
}

// HALAMAN LOGIN
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final nimController = TextEditingController();
  final namaController = TextEditingController();
  final passwordController = TextEditingController();

  bool passwordTersembunyi = true;

  void login() {
    // Memeriksa apakah semua kolom sudah diisi
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            nim: nimController.text.trim(),
            nama: namaController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    nimController.dispose();
    namaController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LOGO VELORA
                  const Icon(
                    Icons.school_rounded,
                    size: 76,
                    color: Color(0xFF3157D5),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'VELORA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF233D91),
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Sistem Monitoring Kehadiran Mahasiswa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Selamat Datang!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Silakan masuk menggunakan data mahasiswa.',
                    style: TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 24),

                  // INPUT NIM
                  TextFormField(
                    controller: nimController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'NIM Mahasiswa',
                      hintText: 'Masukkan NIM',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'NIM wajib diisi';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // INPUT NAMA
                  TextFormField(
                    controller: namaController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nama Mahasiswa',
                      hintText: 'Masukkan nama lengkap',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama wajib diisi';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // INPUT PASSWORD
                  TextFormField(
                    controller: passwordController,
                    obscureText: passwordTersembunyi,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Masukkan password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          passwordTersembunyi
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            passwordTersembunyi =
                            !passwordTersembunyi;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // TOMBOL LOGIN
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3157D5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'LOGIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'VELORA • Monitoring Kehadiran Mahasiswa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
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

// HALAMAN DASHBOARD
class DashboardPage extends StatelessWidget {
  final String nim;
  final String nama;

  const DashboardPage({
    super.key,
    required this.nim,
    required this.nama,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'VELORA Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF3157D5),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Selamat Datang,',
            style: TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 4),

          Text(
            nama,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'NIM: $nim',
            style: const TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 24),

          // KARTU KEHADIRAN
          Card(
            color: const Color(0xFFE6ECFF),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 36,
                    color: Color(0xFF3157D5),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Persentase Kehadiran',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Belum ada data',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF233D91),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Data akan ditampilkan setelah terhubung '
                        'dengan sistem presensi.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // KARTU JADWAL
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.schedule,
                color: Color(0xFF3157D5),
                size: 32,
              ),
              title: const Text('Jadwal Kuliah'),
              subtitle: const Text(
                'Belum ada jadwal yang ditambahkan.',
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),

          const SizedBox(height: 16),

          // TOMBOL PRESENSI
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Fitur presensi belum diaktifkan.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.fingerprint),
              label: const Text('PRESENSI SEKARANG'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3157D5),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
