# VELORA (Aplikasi Monitoring Kehadiran Mahasiswa)

## 📌 Tujuan Proyek
Aplikasi mobile berbasis Flutter yang dikembangkan sebagai Proyek Akhir / Kelas Mandiri Pemrograman Perangkat Bergerak. VELORA dirancang untuk memantau kehadiran mahasiswa secara mandiri dengan mengusung sistem anti-kecurangan (*Hardware Binding*) dan ketahanan jaringan (*Offline-First* berbasis SQLite serta *Background Sync*).

## 👥 Anggota Kelompok & Peran
- **Christian Rambing** - Project Manager / Scrum Master
- **Eirene Sumeke** - UI/UX Designer
- **Heru Nawipa** - Flutter Developer (Backend & Logic)
- **Chersy Moningka** - Flutter Developer (Frontend & UI)
- **Avrinanda Indriani Betah** - QA Engineer & Developer

## 🛠️ Teknologi yang Digunakan
- **Framework:** Flutter (Dart)
- **Backend-as-a-Service:** Firebase (Authentication, Cloud Firestore, Firebase Cloud Messaging)
- **Local Storage:** SQLite / Hive
- **Version Control:** Git & GitHub

## 📱 Fitur Utama MVP (Minimum Viable Product)
1. **Authentication & Hardware Device Binding:** Mencegah praktik titip absen dengan mengunci akun pada satu ID perangkat keras unik.
2. **Offline-First Resilience:** Memungkinkan penyimpanan data presensi secara lokal saat terjadi *blank spot* di ruang kelas, dan melakukan sinkronisasi otomatis (*background sync*) saat jaringan pulih.
3. **Dashboard Analitik & Early Warning System (EWS):** Visualisasi persentase kehadiran dan notifikasi otomatis batas aman kehadiran mahasiswa.
4. **Validasi Spasial & Anti-Fake GPS:** Pengecekan radius *geo-fencing* 50 meter dari titik kampus dan deteksi *Mock Location*.

## 🚀 Cara Menjalankan Proyek
1. Clone repository ini ke perangkat lokal Anda:
   ```bash
   git clone [https://github.com/avrinandaindrianibetah-ops/velora.git](https://github.com/avrinandaindrianibetah-ops/velora.git)
