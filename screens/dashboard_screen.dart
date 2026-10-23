import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'presence_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  static const Color navyBlue = Color(0xFF0B1F4B);
  static const Color brightBlue = Color(0xFF1E5AA8);
  static const Color bgLight = Color(0xFFF4F7FC);

  // Data Angka Clean (Kosong dulu sebelum diisi presensi)
  double? persentaseKehadiran;
  int? sisaJatahAlpha;

  final List<Map<String, String>> jadwalHariIni = [
    {
      'matkul': 'Pemrograman Perangkat Bergerak',
      'waktu': 'Pukul 10:00 WITA',
      'ruang': 'Ruang : RK 1',
    },
    {
      'matkul': 'Jaringan Komputer',
      'waktu': 'Pukul 13:00 WITA',
      'ruang': 'Ruang : Lab 1',
    },
  ];

  String _selectedMatkulFilter = 'Semua Mata Kuliah';
  final List<String> _daftarMatkulFilter = [
    'Semua Mata Kuliah',
    'Pemrograman Perangkat Bergerak',
    'Jaringan Komputer',
    'Basis Data',
  ];

  final List<Map<String, String>> _riwayatPresensi = [];

  // Warna otomatis: Hijau (>80%), Kuning (76-80%), Merah (<75%), Abu-abu (jika kosong)
  Color _getProgressColor(double? percentage) {
    if (percentage == null) return const Color(0xFFCBD5E1);
    if (percentage > 80) return const Color(0xFF2E9B68);
    if (percentage >= 76) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  void _bukaHalamanPresensi() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PresenceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String rawName = user?.email?.split('@')[0] ?? 'Mahasiswa';
    String displayName = rawName.isNotEmpty
        ? rawName[0].toUpperCase() + rawName.substring(1)
        : 'Mahasiswa';

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: navyBlue,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentIndex == 0
                  ? 'Halo, $displayName!'
                  : _currentIndex == 1
                      ? 'Riwayat Presensi'
                      : 'Profil Pengguna',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_currentIndex == 0)
              const Text(
                'Status Kehadiran Akademik',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: _buildBodyContent(displayName),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: navyBlue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(String displayName) {
    if (_currentIndex == 1) {
      return _buildLayar5Riwayat();
    } else if (_currentIndex == 2) {
      return _buildProfilSingkat(displayName);
    }
    return _buildLayar2Dashboard();
  }

  // LAYAR 2: DASHBOARD MAHASISWA (ANALYTIC HUB)
  Widget _buildLayar2Dashboard() {
    final Color indicatorColor = _getProgressColor(persentaseKehadiran);
    final double progressValue = persentaseKehadiran != null
        ? (persentaseKehadiran! / 100.0).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kartu Grafik Donat & Early Warning System
          Card(
            elevation: 2,
            shadowColor: Colors.black12,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progressValue,
                          strokeWidth: 12,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                persentaseKehadiran != null
                                    ? '${persentaseKehadiran!.toInt()}%'
                                    : '--%',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: navyBlue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Kehadiran',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Banner Early Warning System (Sudah diperbaiki dengan Flexible agar bebas Overflow)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFF57C00),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Sisa Jatah Alpha Anda: ${sisaJatahAlpha != null ? "$sisaJatahAlpha" : "--"} Pertemuan',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF795548),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Visual Bawah: Kartu Jadwal Kelas Hari Ini
          const Text(
            'Jadwal Kelas Hari Ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: navyBlue,
            ),
          ),
          const SizedBox(height: 12),
          ...jadwalHariIni.map((jadwal) {
            return Card(
              elevation: 3,
              shadowColor: Colors.black12,
              margin: const EdgeInsets.only(bottom: 14),
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: bgLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.calendar_today, color: brightBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                jadwal['matkul']!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: navyBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${jadwal['waktu']}  |  ${jadwal['ruang']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brightBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _bukaHalamanPresensi,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'MULAI PRESENSI',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // LAYAR 5: RIWAYAT PRESENSI DAN REKAP
  Widget _buildLayar5Riwayat() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                const Text(
                  'Filter:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: navyBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMatkulFilter,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: navyBlue),
                      style: const TextStyle(
                        fontSize: 13,
                        color: navyBlue,
                        fontWeight: FontWeight.w600,
                      ),
                      items: _daftarMatkulFilter.map((String matkul) {
                        return DropdownMenuItem<String>(
                          value: matkul,
                          child: Text(matkul, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedMatkulFilter = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendBadge(const Color(0xFF2E9B68), 'Hadir'),
              _buildLegendBadge(const Color(0xFFF59E0B), 'Izin'),
              _buildLegendBadge(const Color(0xFFDC2626), 'Alpha'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _riwayatPresensi.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_toggle_off, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada data riwayat presensi.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Rekam jejak kehadiran Anda akan tampil di sini.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _riwayatPresensi.length,
                    itemBuilder: (context, index) {
                      final item = _riwayatPresensi[index];
                      final String status = item['status'] ?? 'Hadir';
                      Color badgeColor = const Color(0xFF2E9B68);
                      if (status == 'Alpha') badgeColor = const Color(0xFFDC2626);
                      if (status == 'Izin') badgeColor = const Color(0xFFF59E0B);

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: badgeColor.withValues(alpha: 0.15),
                            child: Icon(
                              status == 'Hadir'
                                  ? Icons.check_circle
                                  : status == 'Izin'
                                      ? Icons.info
                                      : Icons.cancel,
                              color: badgeColor,
                            ),
                          ),
                          title: Text(
                            '${item['tanggal']} • ${item['jam']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: navyBlue,
                            ),
                          ),
                          subtitle: Text(
                            item['matkul'] ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBadge(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilSingkat(String displayName) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '-';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 42,
              backgroundColor: navyBlue,
              child: Icon(Icons.person, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: navyBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'Keluar Akun',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
