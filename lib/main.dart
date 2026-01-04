import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';

import 'config/manajer_session.dart';
import 'theme/app_theme.dart';

// Autentikasi
import 'halaman/autentikasi/splash_screen.dart';
import 'halaman/autentikasi/halaman_login.dart';
import 'halaman/autentikasi/halaman_lupa_password.dart';

// Mahasiswa
import 'halaman/mahasiswa/dashboard_mahasiswa.dart';
import 'halaman/mahasiswa/halaman_profil.dart';
import 'halaman/mahasiswa/riwayat_bimbingan.dart';
import 'halaman/mahasiswa/permintaan_ta/form_permintaan_ta.dart';
import 'halaman/mahasiswa/permintaan_ta/daftar_permintaan_ta.dart';
import 'halaman/mahasiswa/slot_bimbingan/daftar_slot_tersedia.dart';
import 'halaman/mahasiswa/slot_bimbingan/daftar_ke_slot.dart';
import 'halaman/mahasiswa/permintaan_ta/detail_bimbingan.dart';

// Dosen
import 'halaman/dosen/dashboard_dosen.dart';
import 'halaman/dosen/mahasiswa_bimbingan.dart';
import 'halaman/dosen/riwayat_bimbingan_dosen.dart';
import 'halaman/dosen/manajemen_slot/daftar_slot_dosen.dart';
import 'halaman/dosen/manajemen_slot/tambah_slot.dart';
import 'halaman/dosen/manajemen_permintaan/daftar_permintaan_masuk.dart';
import 'halaman/dosen/manajemen_permintaan/tinjau_permintaan.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const SibitaApp(),
    ),
  );
}

class SibitaApp extends StatefulWidget {
  const SibitaApp({super.key});

  @override
  State<SibitaApp> createState() => _SibitaAppState();
}

class _SibitaAppState extends State<SibitaApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIBITA',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      builder: DevicePreview.appBuilder,
      home: const SplashScreen(),
      routes: {
        // Autentikasi
        '/login': (_) => HalamanLogin(),
        '/lupa': (_) => HalamanLupaPassword(),

        // Mahasiswa
        '/mahasiswa/dashboard': (_) => DashboardMahasiswa(),
        '/mahasiswa/profil': (_) => HalamanProfil(),
        '/mahasiswa/permintaan/form': (_) => FormPermintaanTa(),
        '/mahasiswa/permintaan/list': (_) => DaftarPermintaanTa(),
        '/mahasiswa/bimbingan/detail': (_) => DetailBimbingan(),
        '/mahasiswa/bimbingan/riwayat': (_) => RiwayatBimbingan(),
        '/mahasiswa/slot/list': (_) => DaftarSlotTersedia(),
        '/mahasiswa/slot/daftar': (_) => DaftarKeSlot(),

        // Dosen
        '/dosen/dashboard': (_) => DashboardDosen(),
        '/dosen/slot/list': (_) => DaftarSlotDosen(),
        '/dosen/slot/tambah': (_) => TambahSlot(),
        '/dosen/permintaan/list': (_) => DaftarPermintaanMasuk(),
        '/dosen/permintaan/tinjau': (_) => TinjauPermintaan(),
        '/dosen/mahasiswa_bimbingan': (_) => MahasiswaBimbingan(),
        '/dosen/bimbingan/riwayat': (_) => RiwayatBimbinganDosen(),
      },
    );
  }
}
