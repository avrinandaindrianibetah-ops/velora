import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/course.dart';
import '../services/local_queue.dart';
import '../services/sync_service.dart';
import 'presence_screen.dart';

const int kKelas = 1;
const bool kModeUji = true;
const int kTotalMeetings = 16;
const double kMinPercent = 75;
const kNavy = Color(0xFF0B1F4B), kBlue = Color(0xFF1E5AA8), kTeal = Color(0xFF1B8A9E);

String _ymd(DateTime d) => '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
String recordId(String uid, Course c) => '${uid}_${c.code}_${_ymd(DateTime.now())}';

void showVSnack(BuildContext c, String msg, Color color, IconData icon) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(children: [Icon(icon, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(msg))]),
    ));
}

enum PresenceResult { online, offline }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _user = FirebaseAuth.instance.currentUser!;
  late final String uid = _user.uid;
  late final String nim = (_user.email ?? '').split('@').first;
  late final List<Course> courses = buildCourses(kKelas);
  int alpha = 0;
  Set<String> done = {}, pending = {};
  final _subs = <StreamSubscription>[];

  int get hadir => done.length;
  double get percent => hadir / kTotalMeetings * 100;
  int get sisaAlpha => (kTotalMeetings - (kTotalMeetings * kMinPercent / 100).ceil()) - alpha;
  Color get statusColor => percent > 80 ? Colors.green.shade600 : percent >= kMinPercent ? Colors.amber.shade700 : Colors.red.shade700;

  @override
  void initState() {
    super.initState();
    final db = FirebaseFirestore.instance;
    _subs.add(db.collection('users').doc(uid).snapshots().listen((d) {
      if (mounted) setState(() => alpha = (d.data()?['total_alpha'] as num?)?.toInt() ?? 0);
    }));
    _subs.add(db.collection('attendance_records').where('mahasiswa_id', isEqualTo: uid).snapshots().listen((q) {
      if (mounted) setState(() => done = q.docs.map((e) => e.id).toSet());
    }));
    _subs.add(Connectivity().onConnectivityChanged.listen((r) {
      if (!r.contains(ConnectivityResult.none)) _sync();
    }));
    _loadPending();
    _sync();
    _initFcm();
  }

  @override
  void dispose() {
    for (final s in _subs) { s.cancel(); }
    super.dispose();
  }

  Future<void> _initFcm() async {
    try {
      final m = FirebaseMessaging.instance;
      await m.requestPermission();
      final t = await m.getToken();
      if (t != null) await FirebaseFirestore.instance.collection('users').doc(uid).update({'fcm_token': t});
    } catch (_) {}
  }

  Future<void> _loadPending() async {
    final rows = await LocalQueue.all(uid);
    if (mounted) setState(() => pending = rows.map((r) => r['id'] as String).toSet());
  }

  Future<void> _sync({bool manual = false}) async {
    final n = await SyncService.flush().catchError((_) => 0);
    await _loadPending();
    if (!mounted) return;
    if (n > 0) {
      showVSnack(context, '$n presensi tertunda berhasil disinkronkan.', Colors.green.shade700, Icons.cloud_done);
    } else if (manual) {
      showVSnack(context, pending.isEmpty ? 'Tidak ada antrean.' : 'Belum bisa sinkron. Periksa koneksi.', Colors.amber.shade800, Icons.sync_problem);
    }
  }

  Future<void> _startPresence(Course c) async {
    final r = await Navigator.of(context).push<PresenceResult>(
        MaterialPageRoute(builder: (_) => PresenceScreen(course: c, uid: uid)));
    await _loadPending();
    if (!mounted || r == null) return;
    if (r == PresenceResult.online) {
      showVSnack(context, 'Presensi Berhasil Tercatat di Server!', Colors.green.shade700, Icons.check_circle);
    } else {
      showVSnack(context, 'Sinyal Lemah. Data tersimpan lokal dan diunggah otomatis nanti.', Colors.amber.shade800, Icons.sync);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kNavy, foregroundColor: Colors.white,
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Badge(isLabelVisible: pending.isNotEmpty, smallSize: 9, child: const Icon(Icons.notifications_none)),
            onPressed: () => showVSnack(context, 'Sisa jatah Alpha Anda: $sisaAlpha pertemuan.', Colors.amber.shade800, Icons.warning_amber),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _progressCard(),
        const SizedBox(height: 14),
        _warningCard(),
        if (pending.isNotEmpty) ...[const SizedBox(height: 10), _pendingCard()],
        const SizedBox(height: 18),
        const Text('Jadwal Kuliah Semester 5', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kNavy)),
        const SizedBox(height: 10),
        for (final c in courses) _courseCard(c),
      ]),
    );
  }

  Widget _progressCard() => Card(
        elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const Text('Persentase Kehadiran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kNavy)),
            const SizedBox(height: 16),
            SizedBox(
              width: 170, height: 170,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: (percent / 100).clamp(0, 1).toDouble(), strokeWidth: 14, strokeCap: StrokeCap.round,
                  backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation(statusColor),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${percent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: statusColor)),
                  Text('$hadir / $kTotalMeetings pertemuan', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ]),
              ]),
            ),
          ]),
        ),
      );

  Widget _warningCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFFFF4CC), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.amber.shade700)),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 30),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Early Warning System', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.amber.shade900)),
            Text('Sisa Jatah Alpha Anda: $sisaAlpha Pertemuan', style: const TextStyle(fontWeight: FontWeight.w700)),
          ])),
        ]),
      );

  Widget _pendingCard() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.orange.shade400)),
        child: Row(children: [
          const Icon(Icons.cloud_upload_outlined, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(child: Text('${pending.length} presensi menunggu sinkronisasi', style: const TextStyle(fontWeight: FontWeight.w600))),
          TextButton(onPressed: () => _sync(manual: true), child: const Text('Paksa Sinkron')),
        ]),
      );

  Widget _courseCard(Course c) {
    final id = recordId(uid, c);
    final isDone = done.contains(id), isPending = pending.contains(id);
    final canStart = c.isToday || kModeUji;
    return Card(
      margin: const EdgeInsets.only(bottom: 10), elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kNavy))),
            if (c.isToday) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: kTeal, borderRadius: BorderRadius.circular(8)),
              child: const Text('HARI INI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 6),
          Text('${c.hari}, ${c.jam}  •  ${c.ruang}', style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
          Text(c.dosen, style: const TextStyle(color: Colors.black45, fontSize: 12)),
          if (canStart || isDone || isPending) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: (isDone || isPending)
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 11), alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDone ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDone ? Colors.green.shade600 : Colors.orange.shade600),
                      ),
                      child: Text(isDone ? '✓ SUDAH ABSEN' : '✓ SUDAH ABSEN • menunggu sinkron',
                          style: TextStyle(color: isDone ? Colors.green.shade800 : Colors.orange.shade800, fontWeight: FontWeight.w800)),
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: kBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => _startPresence(c),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('MULAI PRESENSI', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
            ),
          ],
        ]),
      ),
    );
  }
}