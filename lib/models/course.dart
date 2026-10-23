const _raw = [
  '5532516MB|Cloud Computing|SELASA|13:00-14:40|RK.10|Dr. Arje Cerullo Djamen, S.T., M.T; Abraham Yano Suharmanto, S.Kom., M.Kom|RK.11|Dr. Johan Reimon Batmetan, S.Pd., M.T; Victor Tuilan, S.Pd., M.Pd',
  '5532520MB|Internet of Things|SELASA|15:00-16:40|RK.10|Dr. Arje Cerullo Djamen, S.T., M.T; Dedi Sorongan, S.Pd., M.Pd|RK.11|Dr. Keith Ratumbuisang, S.Pd., M.Pd., M.Sc; Nadya Kamasi, S.Pd., M.Pd',
  '5552501MB|Data Science|RABU|08:00-09:40|RK.1|Dr. Stralen Pratasik, S.T., M.T; Indra Rianto, S.Kom., M.T|RK.2|Dr. Irene R. H. T. Tangkawarow, ST, MISD; Ameiliani Barahama, S.Pd., M.Pd',
  '5552502MB|Pemrograman Perangkat Bergerak (Mobile)|RABU|10:00-11:40|RK.1|Indra Rianto, S.Kom., M.T; Dedi Sorongan, S.Pd., M.Pd|RK.2|Trudi Komansilan, S.T., M.Sc; Victor Tuilan, S.Pd., M.Pd',
  '5552503MB|Konfigurasi, Administrasi Sistem dan Jaringan|RABU|13:00-14:40|RK.1|Rudy H. W. Pardanus, S.T., M.Eng; Ray Pelealu, S.Pd., M.Pd|RK.2|Dr. Wensi Ronald Lesli Paat, S.T., M.T; Ray Pelealu, S.Pd., M.Pd',
  '5552504MB|Sistem Informasi Manajemen|KAMIS|08:00-09:40|RK.3|Dr. Kebri Pajung, S.Kom., MT; Dr. Olivia E. S. Liando, S.T., M.Sc., M.Pd|RK.4|Dr. Alfrina Mewengkang, S.Kom., M.Eng; Indra Rianto, S.Kom., M.T',
  '5552505MB|IT Governance|KAMIS|10:00-11:40|RK.3|Dr. Wensi Ronald Lesli Paat, S.T., M.T; Dr. Mario Parinsi, S.Kom, MTI|RK.4|Dr. Johan Reimon Batmetan, S.Pd., M.T; Rudy H. W. Pardanus, S.T., M.Eng',
  '5552506MB|Teknik Musik Digital|KAMIS|13:00-14:40|RK.10|Trudi Komansilan, S.T., M.Sc; Merriam Modeong, S.Pd., M.Pd|RK.11|Dr. Keith Ratumbuisang, S.Pd., M.Pd., M.Sc; Dedi Sorongan, S.Pd., M.Pd',
  '5552509MB|Sistem Informasi Geografis|JUMAT|13:00-14:40|RK.7|Indra Rianto, S.Kom., M.T|RK.8|Ir. Gladly Rorimpandey, S.T, MISD, M.Pd',
  '5552507MB|Desain Grafis|JUMAT|15:00-16:40|RK.6|Trudi Komansilan, S.T., M.Sc; Dedi Sorongan, S.Pd., M.Pd|RK.9|Dr. Keith Ratumbuisang, S.Pd., M.Pd., M.Sc; Merriam Modeong, S.Pd., M.Pd',
];
const _wd = {'SENIN': 1, 'SELASA': 2, 'RABU': 3, 'KAMIS': 4, 'JUMAT': 5};

class Course {
  final String code, name, hari, jam, ruang, dosen;
  final int wd;
  const Course(this.code, this.name, this.hari, this.jam, this.ruang, this.dosen, this.wd);
  bool get isToday => DateTime.now().weekday == wd;
}

List<Course> buildCourses(int kelas) {
  final i = kelas == 1 ? 4 : 6;
  return _raw.map((s) {
    final f = s.split('|');
    return Course(f[0], f[1], f[2], f[3], f[i], f[i + 1], _wd[f[2]]!);
  }).toList();
}