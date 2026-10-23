import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:android_id/android_id.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/course.dart';
import '../services/local_queue.dart';
import '../services/sync_service.dart';
import '../services/audit_service.dart';

const double kCenterLat = 1.2931, kCenterLng = 124.9123;
const double kRadius = 50;
const double kMaxGpsAccuracy = 25; // Batas maksimal akurasi GPS dalam meter

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

double haversine(double la1, double lo1, double la2, double lo2) {
  double rad(double d) => d * math.pi / 180;
  final dl = rad(la2 - la1), dn = rad(lo2 - lo1);
  final a = math.pow(math.sin(dl / 2), 2) + math.cos(rad(la1)) * math.cos(rad(la2)) * math.pow(math.sin(dn / 2), 2);
  return 2 * 6371000.0 * math.asin(math.sqrt(a));
}

class PresenceScreen extends StatefulWidget {
  final Course course;
  final String uid;
  const PresenceScreen({super.key, required this.course, required this.uid});
  @override
  State<PresenceScreen> createState() => _PresenceScreenState();
}

class _PresenceScreenState extends State<PresenceScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _scan = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  CameraController? _cam;
  StreamSubscription<Position>? _gps;
  Position? _pos;
  String? _error;
  bool _submitting = false;

  bool get _mock => _pos?.isMocked ?? false;
  double? get _dist => _pos == null ? null : haversine(_pos!.latitude, _pos!.longitude, kCenterLat, kCenterLng);
  bool get _inRadius => _dist != null && _dist! <= kRadius;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) throw 'Izin lokasi ditolak.';
      if (!await Geolocator.isLocationServiceEnabled()) throw 'GPS nonaktif.';
      final cams = await availableCameras();
      final front = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cams.first);
      _cam = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await _cam!.initialize();
      _gps = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)).listen((p) {
        if (mounted) setState(() => _pos = p);
      });
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _gps?.cancel();
    _cam?.dispose();
    _scan.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pos = _pos, cam = _cam;
    if (pos == null || cam == null || !cam.value.isInitialized) return;
    
    // Deteksi Fake GPS
    if (pos.isMocked) {
      await AuditService.log('Fake GPS', detail: 'Presensi ${widget.course.code}');
      if (!mounted) return;
      showVSnack(context, 'Terdeteksi Lokasi Palsu (Fake GPS).', Colors.red.shade700, Icons.gps_off);
      return;
    }

    // Validasi Akurasi GPS (Maksimal 25 meter)
    if (!pos.accuracy.isFinite || pos.accuracy > kMaxGpsAccuracy) {
      if (!mounted) return;
      showVSnack(
        context,
        'Akurasi GPS belum memadai (${pos.accuracy.toStringAsFixed(0)}m). Tunggu hingga maksimal 25 meter.',
        Colors.orange.shade800,
        Icons.gps_not_fixed,
      );
      return;
    }

    // Validasi Radius Geo-fencing
    final d = haversine(pos.latitude, pos.longitude, kCenterLat, kCenterLng);
    if (d > kRadius) {
      if (!mounted) return;
      showVSnack(context, 'Ditolak - Luar Radius (${d.toStringAsFixed(0)} m)', Colors.red.shade700, Icons.location_off);
      return;
    }

    setState(() => _submitting = true);
    try {
      final shot = await cam.takePicture();
      final dir = await getApplicationDocumentsDirectory();
      final id = recordId(widget.uid, widget.course);
      final path = p.join(dir.path, '$id.jpg');
      await File(shot.path).copy(path);
      final uuid = await const AndroidId().getId();
      await LocalQueue.put({
        'id': id, 'uid': widget.uid, 'kode_mk': widget.course.code, 'mata_kuliah': widget.course.name,
        'tanggal': _ymd(DateTime.now()), 'lat': pos.latitude, 'lng': pos.longitude,
        'foto_path': path, 'device_uuid': uuid, 'waktu_lokal': DateTime.now().millisecondsSinceEpoch,
      });
      var online = false;
      try { online = (await SyncService.flush().timeout(const Duration(seconds: 5))) > 0; } catch (_) {}
      
      if (!mounted) return;
      Navigator.of(context).pop(online ? PresenceResult.online : PresenceResult.offline);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        showVSnack(context, 'Gagal memproses presensi: $e', Colors.red.shade700, Icons.error_outline);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _mock;
    final ready = _cam?.value.isInitialized ?? false;
    final dist = _dist;
    final accuracy = _pos?.accuracy;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(widget.course.name)),
      body: SafeArea(
        child: _error != null
            ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white)))
            : Column(children: [
                Expanded(
                  child: !ready
                      ? const Center(child: CircularProgressIndicator())
                      : ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: blocked ? 14 : 0, sigmaY: blocked ? 14 : 0),
                          child: LayoutBuilder(builder: (_, box) {
                            final ovalW = box.maxWidth * 0.55, ovalH = ovalW * 1.3;
                            final cx = box.maxWidth / 2, cy = box.maxHeight / 2;
                            final sz = _cam!.value.previewSize!;
                            return Stack(children: [
                              SizedBox.expand(child: FittedBox(fit: BoxFit.cover, child: SizedBox(width: sz.height, height: sz.width, child: CameraPreview(_cam!)))),
                              Positioned.fill(child: CustomPaint(painter: _FramePainter(Offset(cx, cy), ovalW, ovalH))),
                            ]);
                          }),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16), color: const Color(0xFF111A26),
                  child: Column(children: [
                    Text(
                      dist == null 
                          ? 'Mencari sinyal GPS...' 
                          : 'Jarak: ${dist.toStringAsFixed(0)} m • Akurasi: ±${accuracy?.toStringAsFixed(0) ?? "?"} m', 
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _inRadius ? const Color(0xFF1B8A9E) : Colors.grey,
                        ),
                        onPressed: (blocked || _submitting || !ready || !_inRadius) ? null : _submit,
                        icon: const Icon(Icons.camera),
                        label: Text(_submitting ? 'MEMPROSES...' : (_inRadius ? 'AMBIL FOTO & KIRIM' : 'DI LUAR RADIUS (50M)')),
                      ),
                    ),
                  ]),
                ),
              ]),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  final Offset c;
  final double w, h;
  _FramePainter(this.c, this.w, this.h);
  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromCenter(center: c, width: w, height: h);
    final dim = Path()..addRect(Offset.zero & size)..addOval(oval)..fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = Colors.black.withValues(alpha: 0.6));
    canvas.drawOval(oval, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);
  }
  @override
  bool shouldRepaint(covariant _FramePainter old) => old.c != c || old.w != w || old.h != h;
}