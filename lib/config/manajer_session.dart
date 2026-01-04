import 'package:flutter/widgets.dart';
import '../model/mahasiswa_model.dart';
import '../model/dosen_model.dart';

class ManajerSession extends ChangeNotifier {
  ManajerSession._privateConstructor();
  static final ManajerSession instance = ManajerSession._privateConstructor();

  MahasiswaModel? mahasiswa;
  DosenModel? dosen;
  bool isLoginAsKoordinator = false; // Track apakah login sebagai koordinator

  /// Flag untuk mencegah race condition saat proses login/logout/navigasi
  /// Ketika true, session listener tidak boleh melakukan redirect
  bool isNavigating = false;

  bool get isLoggedIn => mahasiswa != null || dosen != null;

  /// Memulai proses navigasi (login/logout)
  /// Panggil sebelum melakukan navigasi untuk mencegah listener redirect
  void startNavigation() {
    isNavigating = true;
  }

  /// Mengakhiri proses navigasi
  /// Panggil setelah navigasi selesai
  void endNavigation() {
    isNavigating = false;
  }

  void loginMahasiswa(MahasiswaModel m) {
    mahasiswa = m;
    dosen = null;
    isLoginAsKoordinator = false;
    notifyListeners();
  }

  void loginDosen(DosenModel d) {
    dosen = d;
    mahasiswa = null;
    isLoginAsKoordinator = false;
    notifyListeners();
  }

  void loginKoordinator(DosenModel d) {
    dosen = d;
    mahasiswa = null;
    isLoginAsKoordinator = true;
    notifyListeners();
  }

  /// Update data dosen yang sedang login (untuk update profil)
  void setDosen(DosenModel d) {
    dosen = d;
    notifyListeners();
  }

  /// Update data mahasiswa yang sedang login (untuk update profil)
  void setMahasiswa(MahasiswaModel m) {
    mahasiswa = m;
    notifyListeners();
  }

  /// Logout dan clear semua session data
  /// Pastikan panggil startNavigation() sebelum logout jika akan navigasi
  void logout() {
    mahasiswa = null;
    dosen = null;
    isLoginAsKoordinator = false;
    notifyListeners();
  }

  /// Clear semua session tanpa notify listeners
  /// Gunakan saat ingin reset session tanpa trigger rebuild UI
  void clearSessionSilent() {
    mahasiswa = null;
    dosen = null;
    isLoginAsKoordinator = false;
    isNavigating = false;
  }
}
