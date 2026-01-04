// ignore_for_file: prefer_interpolation_to_compose_strings, non_constant_identifier_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/bimbingan_model.dart';
import '../model/dosen_model.dart';
import '../model/mahasiswa_model.dart';
import '../model/permintaan_model.dart';
import '../model/slot_model.dart';
import 'config.dart';

/// Class wrapper untuk REST API dengan method yang mudah digunakan
class RestApi {
  // Singleton pattern
  static final RestApi _instance = RestApi._internal();
  static RestApi get instance => _instance;
  RestApi._internal();

  final DataService _dataService = DataService();

  // ==================== UTILITY ====================

  /// Helper untuk parsing response JSON yang bisa berupa List atau Map
  List<dynamic> _parseJsonResponse(String response) {
    final decoded = jsonDecode(response);
    if (decoded is List) {
      return decoded;
    } else if (decoded is Map) {
      // Cek apakah ada key 'data' yang berisi array (format dari gocloud API)
      if (decoded.containsKey('data') && decoded['data'] is List) {
        return decoded['data'] as List<dynamic>;
      }
      // Jika Map kosong atau tidak ada data, return empty list
      if (decoded.isEmpty) return [];
      return [decoded];
    }
    return [];
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_${(DateTime.now().microsecond).toString().padLeft(6, '0')}';
  }

  /// Method seed tidak diperlukan lagi karena data dari cloud
  void seed() {
    // Data sekarang diambil dari cloud, tidak perlu seed lokal
  }

  // ==================== AUTH ====================

  /// Login sebagai mahasiswa
  Future<MahasiswaModel?> loginMahasiswa(String nrp, String password) async {
    try {
      final response = await _dataService.selectWhere(
        token,
        project,
        'mahasiswa_model',
        appid,
        'nrp',
        nrp,
      );

      print('DEBUG loginMahasiswa - NRP: $nrp');
      print('DEBUG loginMahasiswa - Response: $response');

      final List<dynamic> data = _parseJsonResponse(response);
      print('DEBUG loginMahasiswa - Parsed data: $data');

      if (data.isEmpty) {
        print('DEBUG loginMahasiswa - Data kosong, user tidak ditemukan');
        return null;
      }

      final mahasiswa = MahasiswaModel.fromJson(data.first);
      print('DEBUG loginMahasiswa - Password di DB: ${mahasiswa.password}');
      print('DEBUG loginMahasiswa - Password input: $password');

      if (mahasiswa.password == password) {
        print('DEBUG loginMahasiswa - Login berhasil');
        return mahasiswa;
      }
      print('DEBUG loginMahasiswa - Password tidak cocok');
      return null;
    } catch (e) {
      print('Error loginMahasiswa: $e');
      return null;
    }
  }

  /// Login sebagai dosen (juga cek isKoordinator)
  Future<DosenModel?> loginDosen(String nip, String password) async {
    try {
      final response = await _dataService.selectWhere(
        token,
        project,
        'dosen_model',
        appid,
        'nip',
        nip,
      );

      print('DEBUG loginDosen - NIP: $nip');
      print('DEBUG loginDosen - Response: $response');

      final List<dynamic> data = _parseJsonResponse(response);
      print('DEBUG loginDosen - Parsed data: $data');

      if (data.isEmpty) {
        print('DEBUG loginDosen - Data kosong, dosen tidak ditemukan');
        return null;
      }

      final dosen = DosenModel.fromJson(data.first);
      print('DEBUG loginDosen - Password di DB: ${dosen.password}');
      print('DEBUG loginDosen - Password input: $password');

      if (dosen.password == password) {
        print('DEBUG loginDosen - Login berhasil');
        return dosen;
      }
      print('DEBUG loginDosen - Password tidak cocok');
      return null;
    } catch (e) {
      print('Error loginDosen: $e');
      return null;
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email, String newPassword) async {
    try {
      // Cek apakah email ada di database mahasiswa
      final daftarMahasiswa = await semuaMahasiswa();
      final mahasiswa = daftarMahasiswa
          .where((mhs) => mhs.email.toLowerCase() == email.toLowerCase())
          .toList();

      if (mahasiswa.isNotEmpty) {
        // Email ditemukan di mahasiswa, update password menggunakan NRP
        final nrp = mahasiswa.first.nrp;
        final result = await _dataService.updateWhere(
          'nrp',
          nrp,
          'password',
          newPassword,
          token,
          project,
          'mahasiswa_model',
          appid,
        );
        print('DEBUG resetPassword - Update mahasiswa result: $result');
        return result == true;
      }

      // Cek apakah email ada di database dosen
      final daftarDosen = await semuaDosen();
      final dosen = daftarDosen
          .where((dsn) => dsn.email.toLowerCase() == email.toLowerCase())
          .toList();

      if (dosen.isNotEmpty) {
        // Email ditemukan di dosen, update password menggunakan NIP
        final nip = dosen.first.nip;
        final result = await _dataService.updateWhere(
          'nip',
          nip,
          'password',
          newPassword,
          token,
          project,
          'dosen_model',
          appid,
        );
        print('DEBUG resetPassword - Update dosen result: $result');
        return result == true;
      }

      // Email tidak ditemukan di mahasiswa maupun dosen
      print('DEBUG resetPassword - Email tidak ditemukan: $email');
      return false;
    } catch (e) {
      print('Error resetPassword: $e');
      return false;
    }
  }

  // ==================== DOSEN ====================

  /// Ambil semua dosen
  Future<List<DosenModel>> semuaDosen() async {
    try {
      final response = await _dataService.selectAll(
        token,
        project,
        'dosen_model',
        appid,
      );

      final List<dynamic> data = _parseJsonResponse(response);
      return data.map((json) => DosenModel.fromJson(json)).toList();
    } catch (e) {
      print('Error semuaDosen: $e');
      return [];
    }
  }

  /// Cari dosen berdasarkan NIP
  Future<DosenModel?> cariDosenByNip(String nip) async {
    try {
      final response = await _dataService.selectWhere(
        token,
        project,
        'dosen_model',
        appid,
        'nip',
        nip,
      );

      final List<dynamic> data = _parseJsonResponse(response);
      if (data.isEmpty) return null;
      return DosenModel.fromJson(data.first);
    } catch (e) {
      print('Error cariDosenByNip: $e');
      return null;
    }
  }

  /// Validasi apakah string Base64 adalah gambar yang valid
  /// Memeriksa header Base64 untuk menentukan tipe file
  bool _isValidBase64Image(String base64String) {
    try {
      // Cek apakah punya prefix data URI
      if (base64String.startsWith('data:')) {
        // Format: data:image/jpeg;base64,/9j/4AAQ...
        final mimeType = base64String
            .split(';')
            .first
            .split(':')
            .last
            .toLowerCase();
        return [
          'image/jpg',
          'image/jpeg',
          'image/png',
          'image/webp',
        ].contains(mimeType);
      }

      // Untuk Base64 tanpa prefix, cek magic bytes
      final bytes = base64Decode(
        base64String.length > 100
            ? base64String.substring(0, 100)
            : base64String,
      );
      if (bytes.length >= 3) {
        // JPEG: FF D8 FF
        if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF)
          return true;
        // PNG: 89 50 4E 47
        if (bytes.length >= 4 &&
            bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4E &&
            bytes[3] == 0x47)
          return true;
        // WEBP: 52 49 46 46 (RIFF)
        if (bytes.length >= 4 &&
            bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46)
          return true;
      }

      // Jika tidak bisa detect, anggap valid (sudah divalidasi di frontend)
      return true;
    } catch (e) {
      print('Error validating Base64 image: $e');
      return false;
    }
  }

  /// Update profil dosen
  Future<bool> updateDosenProfile({
    required String nip,
    String? nama,
    String? email,
    String? password,
    String? fotoProfil,
  }) async {
    try {
      // Validasi foto profil jika ada
      if (fotoProfil != null && !_isValidBase64Image(fotoProfil)) {
        print('Error updateDosenProfile: Format file tidak valid');
        return false;
      }

      if (nama != null) {
        await _dataService.updateWhere(
          'nip',
          nip,
          'nama',
          nama,
          token,
          project,
          'dosen_model',
          appid,
        );
        await Future.delayed(Duration(milliseconds: 200));
      }
      if (email != null) {
        await _dataService.updateWhere(
          'nip',
          nip,
          'email',
          email,
          token,
          project,
          'dosen_model',
          appid,
        );
        await Future.delayed(Duration(milliseconds: 200));
      }
      if (password != null) {
        await _dataService.updateWhere(
          'nip',
          nip,
          'password',
          password,
          token,
          project,
          'dosen_model',
          appid,
        );
        await Future.delayed(Duration(milliseconds: 200));
      }
      if (fotoProfil != null) {
        await _dataService.updateWhere(
          'nip',
          nip,
          'foto_profil',
          fotoProfil,
          token,
          project,
          'dosen_model',
          appid,
        );
      }
      return true;
    } catch (e) {
      print('Error updateDosenProfile: $e');
      return false;
    }
  }

  // ==================== MAHASISWA ====================

  /// Ambil semua mahasiswa
  Future<List<MahasiswaModel>> semuaMahasiswa() async {
    try {
      final response = await _dataService.selectAll(
        token,
        project,
        'mahasiswa_model',
        appid,
      );

      final List<dynamic> data = _parseJsonResponse(response);
      return data.map((json) => MahasiswaModel.fromJson(json)).toList();
    } catch (e) {
      print('Error semuaMahasiswa: $e');
      return [];
    }
  }

  /// Ambil mahasiswa bimbingan berdasarkan NIP dosen
  Future<List<MahasiswaModel>> getMahasiswaBimbingan(String nipDosen) async {
    try {
      print('DEBUG getMahasiswaBimbingan - NIP Dosen: $nipDosen');

      // Gunakan field 'nip' karena di mahasiswa_model field dosen pembimbing adalah 'nip'
      final response = await _dataService.selectWhere(
        token,
        project,
        'mahasiswa_model',
        appid,
        'nip',
        nipDosen,
      );

      print('DEBUG getMahasiswaBimbingan - Response: $response');

      final List<dynamic> data = _parseJsonResponse(response);
      print(
        'DEBUG getMahasiswaBimbingan - Total mahasiswa bimbingan: ${data.length}',
      );

      return data.map((json) => MahasiswaModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getMahasiswaBimbingan: $e');
      return [];
    }
  }

  /// Cari mahasiswa berdasarkan NRP
  Future<MahasiswaModel?> cariMahasiswaByNrp(String nrp) async {
    try {
      final response = await _dataService.selectWhere(
        token,
        project,
        'mahasiswa_model',
        appid,
        'nrp',
        nrp,
      );

      final List<dynamic> data = _parseJsonResponse(response);
      if (data.isEmpty) return null;
      return MahasiswaModel.fromJson(data.first);
    } catch (e) {
      print('Error cariMahasiswaByNrp: $e');
      return null;
    }
  }

  /// Update profil mahasiswa
  Future<bool> updateMahasiswaProfile({
    required String nrp,
    String? nama,
    String? email,
    String? password,
    double? ipk,
    String? fotoProfil,
  }) async {
    try {
      // Validasi foto profil jika ada
      if (fotoProfil != null && !_isValidBase64Image(fotoProfil)) {
        print('Error updateMahasiswaProfile: Format file tidak valid');
        return false;
      }

      if (nama != null) {
        await _dataService.updateWhere(
          'nrp',
          nrp,
          'nama',
          nama,
          token,
          project,
          'mahasiswa_model',
          appid,
        );
        await Future.delayed(Duration(milliseconds: 200));
      }
      if (email != null) {
        await _dataService.updateWhere(
          'nrp',
          nrp,
          'email',
          email,
          token,
          project,
          'mahasiswa_model',
          appid,
        );
        await Future.delayed(Duration(milliseconds: 200));
      }
      if (password != null) {
        await _dataService.updateWhere(
          'nrp',
          nrp,
          'password',
          password,
          token,
          project,
          'mahasiswa_model',
          appid,
        );
        await Future.delayed(Duration(milliseconds: 200));
      }
      if (ipk != null) {
        await _dataService.updateWhere(
          'nrp',
          nrp,
          'ipk',
          ipk.toString(),
          token,
          project,
          'mahasiswa_model',
          appid,
        );
        await Future.delayed(Duration(milliseconds: 200));
      }
      if (fotoProfil != null) {
        await _dataService.updateWhere(
          'nrp',
          nrp,
          'foto_profile',
          fotoProfil,
          token,
          project,
          'mahasiswa_model',
          appid,
        );
      }
      return true;
    } catch (e) {
      print('Error updateMahasiswaProfile: $e');
      return false;
    }
  }

  // ==================== SLOT ====================

  /// Ambil semua slot
  Future<List<SlotModel>> semuaSlot() async {
    try {
      final response = await _dataService.selectAll(
        token,
        project,
        'slot_model',
        appid,
      );

      final List<dynamic> data = _parseJsonResponse(response);
      return data.map((json) => SlotModel.fromJson(json)).toList();
    } catch (e) {
      print('Error semuaSlot: $e');
      return [];
    }
  }

  /// Ambil semua slot untuk dosen tertentu
  Future<List<SlotModel>> semuaSlotUntukDosen(String nipDosen) async {
    try {
      final response = await _dataService.selectWhere(
        token,
        project,
        'slot_model',
        appid,
        'nip',
        nipDosen,
      );

      print('DEBUG semuaSlotUntukDosen - NIP: $nipDosen');
      print('DEBUG semuaSlotUntukDosen - Response: $response');

      final List<dynamic> data = _parseJsonResponse(response);
      print('DEBUG semuaSlotUntukDosen - Total data: ${data.length}');

      return data.map((json) => SlotModel.fromJson(json)).toList();
    } catch (e) {
      print('Error semuaSlotUntukDosen: $e');
      return [];
    }
  }

  /// Ambil daftar slot yang tersedia (belum full dan tanggal masih valid)
  Future<List<SlotModel>> daftarSlotTersedia() async {
    try {
      final allSlots = await semuaSlot();
      final now = DateTime.now();

      return allSlots.where((slot) {
        // Filter: belum full, dan tanggal >= hari ini
        return !slot.isFull &&
            slot.tanggalDateTime.isAfter(now.subtract(Duration(days: 1)));
      }).toList();
    } catch (e) {
      print('Error daftarSlotTersedia: $e');
      return [];
    }
  }

  /// Cari slot berdasarkan ID
  /// Karena API tidak mendukung pencarian langsung dengan field 'id',
  /// kita ambil semua slot dan filter di client
  Future<SlotModel?> cariSlotById(String id) async {
    try {
      print('DEBUG cariSlotById - ID: $id');

      // Ambil semua slot dan filter berdasarkan id
      final allSlots = await semuaSlot();
      print('DEBUG cariSlotById - Total slots: ${allSlots.length}');

      final slot = allSlots.where((s) => s.id == id).firstOrNull;

      if (slot == null) {
        print('DEBUG cariSlotById - Slot tidak ditemukan');
        return null;
      }

      print('DEBUG cariSlotById - Slot ditemukan: ${slot.id}');
      return slot;
    } catch (e) {
      print('Error cariSlotById: $e');
      return null;
    }
  }

  /// Buat slot baru (fleksibel)
  Future<SlotModel?> createSlot({
    required String nip,
    required DateTime tanggal,
    required DateTime jamMulai,
    required DateTime jamSelesai,
    required String lokasi,
    required int kapasitas,
  }) async {
    try {
      final idBimbingan = _generateId();
      final slot = SlotModel(
        id: '',
        idBimbingan: idBimbingan,
        nip: nip,
        tanggal: tanggal.toIso8601String(),
        jamMulai: jamMulai.toIso8601String(),
        jamSelesai: jamSelesai.toIso8601String(),
        lokasi: lokasi,
        kapasitas: kapasitas.toString(),
        pendaftar: '',
        tipe: TipeSlot.fleksibel.nama.toLowerCase(),
        hari: '',
      );

      await _dataService.insertSlotModel(
        appid,
        slot.idBimbingan,
        slot.nip,
        slot.tanggal,
        slot.jamMulai,
        slot.jamSelesai,
        slot.lokasi,
        slot.kapasitas,
        slot.pendaftar,
        slot.tipe,
        slot.hari,
      );

      return slot;
    } catch (e) {
      print('Error createSlot: $e');
      return null;
    }
  }

  /// Buat slot tetap (recurring)
  Future<List<SlotModel>> createSlotTetap({
    required String nip,
    required HariSlot hari,
    required DateTime jamMulai,
    required DateTime jamSelesai,
    required String lokasi,
    required int kapasitas,
    required int jumlahMinggu,
  }) async {
    try {
      final slots = <SlotModel>[];
      final now = DateTime.now();

      // Cari tanggal pertama yang sesuai dengan hari yang dipilih
      var startDate = now;
      while (startDate.weekday != hari.weekday) {
        startDate = startDate.add(Duration(days: 1));
      }

      for (int i = 0; i < jumlahMinggu; i++) {
        final tanggal = startDate.add(Duration(days: 7 * i));
        final idBimbingan = _generateId() + '_$i';
        final jamMulaiSlot = DateTime(
          tanggal.year,
          tanggal.month,
          tanggal.day,
          jamMulai.hour,
          jamMulai.minute,
        );
        final jamSelesaiSlot = DateTime(
          tanggal.year,
          tanggal.month,
          tanggal.day,
          jamSelesai.hour,
          jamSelesai.minute,
        );

        final slot = SlotModel(
          id: '',
          idBimbingan: idBimbingan,
          nip: nip,
          tanggal: tanggal.toIso8601String(),
          jamMulai: jamMulaiSlot.toIso8601String(),
          jamSelesai: jamSelesaiSlot.toIso8601String(),
          lokasi: lokasi,
          kapasitas: kapasitas.toString(),
          pendaftar: '',
          tipe: TipeSlot.tetap.nama.toLowerCase(),
          hari: hari.nama.toLowerCase(),
        );

        await _dataService.insertSlotModel(
          appid,
          slot.idBimbingan,
          slot.nip,
          slot.tanggal,
          slot.jamMulai,
          slot.jamSelesai,
          slot.lokasi,
          slot.kapasitas,
          slot.pendaftar,
          slot.tipe,
          slot.hari,
        );

        slots.add(slot);
      }

      return slots;
    } catch (e) {
      print('Error createSlotTetap: $e');
      return [];
    }
  }

  /// Edit slot - menggunakan id_bimbingan karena lebih reliable
  Future<bool> editSlot({
    required String id,
    DateTime? tanggal,
    DateTime? jamMulai,
    DateTime? jamSelesai,
    String? lokasi,
    int? kapasitas,
    bool? isAktif,
  }) async {
    try {
      // Pertama, cari slot untuk mendapatkan id_bimbingan
      final slot = await cariSlotById(id);
      if (slot == null) {
        print('DEBUG editSlot - Slot tidak ditemukan dengan ID: $id');
        return false;
      }

      final idBimbingan = slot.idBimbingan;
      print('DEBUG editSlot - Menggunakan id_bimbingan: $idBimbingan');

      if (tanggal != null) {
        await _dataService.updateWhere(
          'id_bimbingan',
          idBimbingan,
          'tanggal',
          tanggal.toIso8601String(),
          token,
          project,
          'slot_model',
          appid,
        );
        await Future.delayed(Duration(milliseconds: 200));
      }
      if (jamMulai != null) {
        await _dataService.updateWhere(
          'id_bimbingan',
          idBimbingan,
          'jam_mulai',
          jamMulai.toIso8601String(),
          token,
          project,
          'slot_model',
          appid,
        );
        await Future.delayed(Duration(milliseconds: 200));
      }
      if (jamSelesai != null) {
        await _dataService.updateWhere(
          'id_bimbingan',
          idBimbingan,
          'jam_selesai',
          jamSelesai.toIso8601String(),
          token,
          project,
          'slot_model',
          appid,
        );
        await Future.delayed(Duration(milliseconds: 200));
      }
      if (lokasi != null) {
        await _dataService.updateWhere(
          'id_bimbingan',
          idBimbingan,
          'lokasi',
          lokasi,
          token,
          project,
          'slot_model',
          appid,
        );
        await Future.delayed(Duration(milliseconds: 200));
      }
      if (kapasitas != null) {
        await _dataService.updateWhere(
          'id_bimbingan',
          idBimbingan,
          'kapasitas',
          kapasitas.toString(),
          token,
          project,
          'slot_model',
          appid,
        );
        await Future.delayed(Duration(milliseconds: 200));
      }
      if (isAktif != null) {
        await _dataService.updateWhere(
          'id_bimbingan',
          idBimbingan,
          'isaktif',
          isAktif ? 'true' : 'false',
          token,
          project,
          'slot_model',
          appid,
        );
      }

      print('DEBUG editSlot - Update selesai untuk id_bimbingan: $idBimbingan');
      return true;
    } catch (e) {
      print('Error editSlot: $e');
      return false;
    }
  }

  /// Hapus slot - menggunakan removeId untuk hard delete dari database
  Future<bool> hapusSlot(String id) async {
    try {
      print('DEBUG hapusSlot - Hard delete slot dengan _id: $id');

      // Hard delete menggunakan removeId
      final result = await _dataService.removeId(
        token,
        project,
        'slot_model',
        appid,
        id,
      );

      print('DEBUG hapusSlot - Hard delete result: $result');
      return result == true;
    } catch (e) {
      print('Error hapusSlot: $e');
      return false;
    }
  }

  /// Daftar ke slot
  Future<bool> daftarKeSlot(String slotId, String nrp) async {
    try {
      print('DEBUG daftarKeSlot - Slot ID: $slotId, NRP: $nrp');

      // Ambil slot saat ini
      final slot = await cariSlotById(slotId);
      if (slot == null) {
        print('DEBUG daftarKeSlot - Slot tidak ditemukan');
        return false;
      }

      print(
        'DEBUG daftarKeSlot - Kapasitas: ${slot.kapasitas}, Pendaftar saat ini: ${slot.pendaftar}',
      );
      print('DEBUG daftarKeSlot - ID Bimbingan: ${slot.idBimbingan}');

      // Validasi: Cek apakah slot sudah lewat waktu
      final now = DateTime.now();
      final slotDate = slot.tanggalDateTime;
      final slotEndTime = DateTime(
        slotDate.year,
        slotDate.month,
        slotDate.day,
        slot.jamSelesaiDateTime.hour,
        slot.jamSelesaiDateTime.minute,
      );

      if (now.isAfter(slotEndTime)) {
        print('DEBUG daftarKeSlot - Slot sudah lewat waktu');
        return false;
      }

      // Cek apakah sudah full
      if (slot.isFull) {
        print('DEBUG daftarKeSlot - Slot sudah penuh');
        return false;
      }

      // Cek apakah sudah terdaftar
      if (slot.listPendaftar.contains(nrp)) {
        print('DEBUG daftarKeSlot - Mahasiswa sudah terdaftar');
        return false;
      }

      // Tambah ke pendaftar
      final listPendaftar = List<String>.from(slot.listPendaftar);
      listPendaftar.add(nrp);
      final pendaftarStr = listPendaftar.join(',');

      print('DEBUG daftarKeSlot - Pendaftar baru: $pendaftarStr');

      // Update pendaftar menggunakan id_bimbingan sebagai where field
      final result = await _dataService.updateWhere(
        'id_bimbingan',
        slot.idBimbingan,
        'pendaftar',
        pendaftarStr,
        token,
        project,
        'slot_model',
        appid,
      );

      print('DEBUG daftarKeSlot - Update result: $result');

      return result == true;
    } catch (e) {
      print('Error daftarKeSlot: $e');
      return false;
    }
  }

  /// Batalkan pendaftaran dari slot
  Future<bool> batalDariSlot(String slotId, String nrp) async {
    try {
      // Ambil slot saat ini
      final slot = await cariSlotById(slotId);
      if (slot == null) return false;

      // Hapus dari pendaftar
      final listPendaftar = List<String>.from(slot.listPendaftar);
      listPendaftar.remove(nrp);
      final pendaftarStr = listPendaftar.join(',');

      // Update pendaftar menggunakan id_bimbingan sebagai where field
      final result = await _dataService.updateWhere(
        'id_bimbingan',
        slot.idBimbingan,
        'pendaftar',
        pendaftarStr,
        token,
        project,
        'slot_model',
        appid,
      );

      return result == true;
    } catch (e) {
      print('Error batalDariSlot: $e');
      return false;
    }
  }

  // ==================== PERMINTAAN ====================

  /// Ambil daftar permintaan untuk mahasiswa
  Future<List<PermintaanModel>> daftarPermintaanUntukMahasiswa(
    String nrp,
  ) async {
    try {
      final response = await _dataService.selectWhere(
        token,
        project,
        'permintaan_model',
        appid,
        'nrp',
        nrp,
      );

      final List<dynamic> data = _parseJsonResponse(response);
      return data.map((json) => PermintaanModel.fromJson(json)).toList();
    } catch (e) {
      print('Error daftarPermintaanUntukMahasiswa: $e');
      return [];
    }
  }

  /// Ambil permintaan yang diterima oleh dosen
  Future<List<PermintaanModel>> getPermintaanDiterima(String nipDosen) async {
    try {
      final response = await _dataService.selectWhere(
        token,
        project,
        'permintaan_model',
        appid,
        'pembimbingnip',
        nipDosen,
      );

      final List<dynamic> data = _parseJsonResponse(response);
      return data
          .map((json) => PermintaanModel.fromJson(json))
          .where((p) => p.status == PermintaanStatus.terima)
          .toList();
    } catch (e) {
      print('Error getPermintaanDiterima: $e');
      return [];
    }
  }

  /// Ambil semua permintaan
  Future<List<PermintaanModel>> semuaPermintaan() async {
    try {
      final response = await _dataService.selectAll(
        token,
        project,
        'permintaan_model',
        appid,
      );

      final List<dynamic> data = _parseJsonResponse(response);
      print('DEBUG semuaPermintaan - Raw data: $data');
      return data.map((json) => PermintaanModel.fromJson(json)).toList();
    } catch (e) {
      print('Error semuaPermintaan: $e');
      return [];
    }
  }

  /// Buat permintaan baru
  Future<PermintaanModel?> createPermintaan({
    required String nrp,
    required String judul,
    required String bidang,
    String? nip,
    String? ipk,
  }) async {
    try {
      final permintaan = PermintaanModel(
        id: '',
        nrp: nrp,
        judul: judul,
        bidang: bidang,
        nip: nip ?? '',
        status: PermintaanStatus.pending.name,
        ipk: ipk ?? '',
      );

      await _dataService.insertPermintaanModel(
        appid,
        permintaan.nrp,
        permintaan.judul,
        permintaan.bidang,
        permintaan.nip,
        permintaan.status,
        permintaan.ipk,
      );

      return permintaan;
    } catch (e) {
      print('Error createPermintaan: $e');
      return null;
    }
  }

  /// Update status permintaan
  Future<bool> updateStatusPermintaan(
    String id,
    PermintaanStatus status, {
    String? pembimbingNip,
  }) async {
    try {
      print(
        'DEBUG updateStatusPermintaan - ID: $id, Status: ${status.name}, Nip: $pembimbingNip',
      );

      // Update status terlebih dahulu (gunakan _id untuk API 247go)
      final statusResult = await _dataService.updateWhere(
        '_id',
        id,
        'status',
        status.name,
        token,
        project,
        'permintaan_model',
        appid,
      );
      print(
        'DEBUG updateStatusPermintaan - Status update result: $statusResult',
      );

      // Tunggu sebentar untuk memastikan update pertama selesai
      await Future.delayed(Duration(milliseconds: 300));

      // Update nip (dosen pembimbing) jika ada
      if (pembimbingNip != null) {
        final nipResult = await _dataService.updateWhere(
          '_id',
          id,
          'nip',
          pembimbingNip,
          token,
          project,
          'permintaan_model',
          appid,
        );
        print('DEBUG updateStatusPermintaan - NIP update result: $nipResult');

        // Tunggu sebentar
        await Future.delayed(Duration(milliseconds: 300));

        // Jika status terima dan ada pembimbingNip, update juga di mahasiswa
        if (status == PermintaanStatus.terima && pembimbingNip.isNotEmpty) {
          // Ambil NRP dari permintaan
          final response = await _dataService.selectWhere(
            token,
            project,
            'permintaan_model',
            appid,
            '_id',
            id,
          );
          final List<dynamic> data = _parseJsonResponse(response);
          print('DEBUG updateStatusPermintaan - Permintaan data: $data');

          if (data.isNotEmpty) {
            final nrp = data.first['nrp'];
            print(
              'DEBUG updateStatusPermintaan - Updating mahasiswa NRP: $nrp with pembimbing: $pembimbingNip',
            );

            final mahasiswaResult = await _dataService.updateWhere(
              'nrp',
              nrp,
              'nip',
              pembimbingNip,
              token,
              project,
              'mahasiswa_model',
              appid,
            );
            print(
              'DEBUG updateStatusPermintaan - Mahasiswa update result: $mahasiswaResult',
            );
          }
        }
      }

      print(
        'DEBUG updateStatusPermintaan - All updates completed successfully',
      );
      return true;
    } catch (e) {
      print('Error updateStatusPermintaan: $e');
      return false;
    }
  }

  /// Update status permintaan by NRP (alternatif jika ID tidak tersedia)
  /// Fungsi ini akan:
  /// 1. Update status permintaan
  /// 2. Update NIP pembimbing di permintaan_model
  /// 3. Update NIP pembimbing di mahasiswa_model (relasi utama untuk bimbingan)
  Future<bool> updateStatusPermintaanByNrp(
    String nrp,
    PermintaanStatus status, {
    String? pembimbingNip,
  }) async {
    try {
      print(
        'DEBUG updateStatusPermintaanByNrp - NRP: $nrp, Status: ${status.name}, Nip: $pembimbingNip',
      );

      // 1. Update status permintaan
      final statusResult = await _dataService.updateWhere(
        'nrp',
        nrp,
        'status',
        status.name,
        token,
        project,
        'permintaan_model',
        appid,
      );
      print(
        'DEBUG updateStatusPermintaanByNrp - Status update result: $statusResult',
      );

      await Future.delayed(Duration(milliseconds: 300));

      // 2. Update nip (dosen pembimbing) di permintaan_model
      if (pembimbingNip != null && pembimbingNip.isNotEmpty) {
        final nipResult = await _dataService.updateWhere(
          'nrp',
          nrp,
          'nip',
          pembimbingNip,
          token,
          project,
          'permintaan_model',
          appid,
        );
        print(
          'DEBUG updateStatusPermintaanByNrp - NIP permintaan update result: $nipResult',
        );

        await Future.delayed(Duration(milliseconds: 300));

        // 3. Update NIP pembimbing di mahasiswa_model
        // Ini adalah relasi utama yang menghubungkan mahasiswa dengan dosen pembimbing
        // Digunakan untuk:
        // - Menampilkan mahasiswa di daftar bimbingan dosen
        // - Menampilkan slot bimbingan yang sesuai untuk mahasiswa
        final mahasiswaResult = await _dataService.updateWhere(
          'nrp',
          nrp,
          'nip',
          pembimbingNip,
          token,
          project,
          'mahasiswa_model',
          appid,
        );
        print(
          'DEBUG updateStatusPermintaanByNrp - Mahasiswa NIP update result: $mahasiswaResult',
        );
      }

      print(
        'DEBUG updateStatusPermintaanByNrp - All updates completed successfully',
      );
      return true;
    } catch (e) {
      print('Error updateStatusPermintaanByNrp: $e');
      return false;
    }
  }

  /// Hapus permintaan
  Future<bool> hapusPermintaan(String id) async {
    try {
      return await _dataService.removeWhere(
        token,
        project,
        'permintaan_model',
        appid,
        'id',
        id,
      );
    } catch (e) {
      print('Error hapusPermintaan: $e');
      return false;
    }
  }

  bool tetapkanPembimbing(String nrp, String nipDosen) {
    _tetapkanPembimbingAsync(nrp, nipDosen);
    return true;
  }

  Future<void> _tetapkanPembimbingAsync(String nrp, String nipDosen) async {
    try {
      // Update dosen pembimbing di mahasiswa
      await _dataService.updateWhere(
        'nrp',
        nrp,
        'nip',
        nipDosen,
        token,
        project,
        'mahasiswa_model',
        appid,
      );
    } catch (e) {
      print('Error _tetapkanPembimbingAsync: $e');
    }
  }

  /// Hapus dosen pembimbing dari mahasiswa
  bool hapusPembimbing(String nrp) {
    _hapusPembimbingAsync(nrp);
    return true;
  }

  Future<void> _hapusPembimbingAsync(String nrp) async {
    try {
      // Hapus dosen pembimbing dari mahasiswa
      await _dataService.updateWhere(
        'nrp',
        nrp,
        'nip',
        '',
        token,
        project,
        'mahasiswa_model',
        appid,
      );
    } catch (e) {
      print('Error _hapusPembimbingAsync: $e');
    }
  }

  /// Hapus pembimbing dan reset status permintaan ke pending
  Future<bool> hapusPembimbingDanResetStatus(String nrp) async {
    try {
      print('DEBUG hapusPembimbingDanResetStatus - NRP: $nrp');

      // 1. Update status permintaan ke pending
      final statusResult = await _dataService.updateWhere(
        'nrp',
        nrp,
        'status',
        'pending',
        token,
        project,
        'permintaan_model',
        appid,
      );
      print(
        'DEBUG hapusPembimbingDanResetStatus - Status update result: $statusResult',
      );

      await Future.delayed(Duration(milliseconds: 300));

      // 2. Hapus nip dari permintaan (set ke kosong)
      final nipPermintaanResult = await _dataService.updateWhere(
        'nrp',
        nrp,
        'nip',
        '',
        token,
        project,
        'permintaan_model',
        appid,
      );
      print(
        'DEBUG hapusPembimbingDanResetStatus - NIP permintaan update result: $nipPermintaanResult',
      );

      await Future.delayed(Duration(milliseconds: 300));

      // 3. Hapus nip dari mahasiswa (set ke kosong)
      final nipMahasiswaResult = await _dataService.updateWhere(
        'nrp',
        nrp,
        'nip',
        '',
        token,
        project,
        'mahasiswa_model',
        appid,
      );
      print(
        'DEBUG hapusPembimbingDanResetStatus - NIP mahasiswa update result: $nipMahasiswaResult',
      );

      print('DEBUG hapusPembimbingDanResetStatus - All updates completed');
      return true;
    } catch (e) {
      print('Error hapusPembimbingDanResetStatus: $e');
      return false;
    }
  }

  // ==================== BIMBINGAN ====================

  /// Daftar ke slot bimbingan dengan detail lengkap
  Future<bool> daftarBimbingan({
    required String slotId,
    required String nrp,
    required String nip,
    required String bab,
    required String deskripsiBimbingan,
    String? fileUrl,
  }) async {
    try {
      print('DEBUG daftarBimbingan - Slot ID: $slotId, NRP: $nrp, Bab: $bab');

      // Ambil slot saat ini
      final slot = await cariSlotById(slotId);
      if (slot == null) {
        print('DEBUG daftarBimbingan - Slot tidak ditemukan');
        return false;
      }

      // Cek apakah sudah full
      if (slot.isFull) {
        print('DEBUG daftarBimbingan - Slot sudah penuh');
        return false;
      }

      // Cek apakah sudah terdaftar di slot ini
      if (slot.listPendaftar.contains(nrp)) {
        print('DEBUG daftarBimbingan - Mahasiswa sudah terdaftar di slot ini');
        return false;
      }

      // 1. Insert ke bimbingan_model
      await _dataService.insertBimbinganModel(
        appid,
        nrp,
        nip,
        slotId,
        slot.tanggal,
        slot.jamMulai,
        slot.jamSelesai,
        bab,
        deskripsiBimbingan,
        'pending',
        fileUrl ?? '',
        '',
      );

      // 2. Update pendaftar di slot_model
      final listPendaftar = List<String>.from(slot.listPendaftar);
      listPendaftar.add(nrp);
      final pendaftarStr = listPendaftar.join(',');

      final result = await _dataService.updateWhere(
        'id_bimbingan',
        slot.idBimbingan,
        'pendaftar',
        pendaftarStr,
        token,
        project,
        'slot_model',
        appid,
      );

      print('DEBUG daftarBimbingan - Update slot result: $result');

      return result == true;
    } catch (e) {
      print('Error daftarBimbingan: $e');
      return false;
    }
  }

  /// Ambil daftar bimbingan untuk mahasiswa
  Future<List<BimbinganModel>> getBimbinganMahasiswa(String nrp) async {
    try {
      final response = await _dataService.selectWhere(
        token,
        project,
        'bimbingan_model',
        appid,
        'nrp',
        nrp,
      );

      final List<dynamic> data = _parseJsonResponse(response);
      return data.map((json) => BimbinganModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getBimbinganMahasiswa: $e');
      return [];
    }
  }

  /// Ambil daftar bimbingan untuk dosen
  Future<List<BimbinganModel>> getBimbinganDosen(String nip) async {
    try {
      print('DEBUG getBimbinganDosen - Fetching for NIP: $nip');

      final response = await _dataService.selectWhere(
        token,
        project,
        'bimbingan_model',
        appid,
        'nip',
        nip,
      );

      final List<dynamic> data = _parseJsonResponse(response);
      final result = data.map((json) => BimbinganModel.fromJson(json)).toList();

      // Debug: tampilkan status setiap bimbingan
      for (var b in result) {
        print('DEBUG getBimbinganDosen - ID: ${b.id}, Status: ${b.status}');
      }

      return result;
    } catch (e) {
      print('Error getBimbinganDosen: $e');
      return [];
    }
  }

  /// Update status bimbingan
  Future<bool> updateStatusBimbingan(
    String id,
    String status, {
    String? catatan,
  }) async {
    try {
      print('DEBUG updateStatusBimbingan - ID: $id, New Status: $status');

      // Update status menggunakan updateId (bukan updateWhere)
      final statusResult = await _dataService.updateId(
        'status',
        status,
        token,
        project,
        'bimbingan_model',
        appid,
        id,
      );

      print(
        'DEBUG updateStatusBimbingan - statusResult: $statusResult (type: ${statusResult.runtimeType})',
      );

      // Update catatan jika ada (menggunakan updateId)
      if (catatan != null && catatan.isNotEmpty) {
        await Future.delayed(Duration(milliseconds: 300));
        await _dataService.updateId(
          'catatan_bimbingan',
          catatan,
          token,
          project,
          'bimbingan_model',
          appid,
          id,
        );
      }

      final result = statusResult == true;
      print('DEBUG updateStatusBimbingan - Final return: $result');
      return result;
    } catch (e) {
      print('Error updateStatusBimbingan: $e');
      return false;
    }
  }

  /// Batalkan bimbingan
  Future<bool> batalkanBimbingan(
    String bimbinganId,
    String slotId,
    String nrp,
  ) async {
    try {
      // 1. Update status bimbingan ke dibatalkan
      await _dataService.updateWhere(
        '_id',
        bimbinganId,
        'status',
        'dibatalkan',
        token,
        project,
        'bimbingan_model',
        appid,
      );

      // 2. Hapus dari pendaftar slot
      final slot = await cariSlotById(slotId);
      if (slot != null) {
        final listPendaftar = List<String>.from(slot.listPendaftar);
        listPendaftar.remove(nrp);
        final pendaftarStr = listPendaftar.join(',');

        await _dataService.updateWhere(
          'id_bimbingan',
          slot.idBimbingan,
          'pendaftar',
          pendaftarStr,
          token,
          project,
          'slot_model',
          appid,
        );
      }

      return true;
    } catch (e) {
      print('Error batalkanBimbingan: $e');
      return false;
    }
  }
}

class DataService {
  Future insertDosenModel(
    String appid,
    String nip,
    String nama,
    String email,
    String password,
    String foto_profil,
    String is_koordinator,
  ) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': '68f2edcd25bcf6243d214a00',
          'project': 'sibita',
          'collection': 'dosen_model',
          'appid': appid,
          'nip': nip,
          'nama': nama,
          'email': email,
          'password': password,
          'foto_profil': foto_profil,
          'is_koordinator': is_koordinator,
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertMahasiswaModel(
    String appid,
    String nrp,
    String nama,
    String email,
    String password,
    String foto_profile,
    String ipk,
    String judul,
    String nip,
  ) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': '68f2edcd25bcf6243d214a00',
          'project': 'sibita',
          'collection': 'mahasiswa_model',
          'appid': appid,
          'nrp': nrp,
          'nama': nama,
          'email': email,
          'password': password,
          'foto_profile': foto_profile,
          'ipk': ipk,
          'judul': judul,
          'nip': nip,
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertPermintaanModel(
    String appid,
    String nrp,
    String judul,
    String bidang,
    String nip,
    String status,
    String ipk,
  ) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': '68f2edcd25bcf6243d214a00',
          'project': 'sibita',
          'collection': 'permintaan_model',
          'appid': appid,
          'nrp': nrp,
          'judul': judul,
          'bidang': bidang,
          'nip': nip,
          'status': status,
          'ipk': ipk,
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertSlotModel(
    String appid,
    String id_bimbingan,
    String nip,
    String tanggal,
    String jam_mulai,
    String jam_selesai,
    String lokasi,
    String kapasitas,
    String pendaftar,
    String tipe,
    String hari,
  ) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': '68f2edcd25bcf6243d214a00',
          'project': 'sibita',
          'collection': 'slot_model',
          'appid': appid,
          'id_bimbingan': id_bimbingan,
          'nip': nip,
          'tanggal': tanggal,
          'jam_mulai': jam_mulai,
          'jam_selesai': jam_selesai,
          'lokasi': lokasi,
          'kapasitas': kapasitas,
          'pendaftar': pendaftar,
          'tipe': tipe,
          'hari': hari,
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future insertBimbinganModel(
    String appid,
    String nrp,
    String nip,
    String id_slot,
    String tanggal,
    String jam_mulai,
    String jam_selesai,
    String bab,
    String deskripsi_bimbingan,
    String status,
    String file,
    String catatan_bimbingan,
  ) async {
    String uri = 'https://api.247go.app/v5/insert/';

    try {
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': '68f2edcd25bcf6243d214a00',
          'project': 'sibita',
          'collection': 'bimbingan_model',
          'appid': appid,
          'nrp': nrp,
          'nip': nip,
          'id_slot': id_slot,
          'tanggal': tanggal,
          'jam_mulai': jam_mulai,
          'jam_selesai': jam_selesai,
          'bab': bab,
          'deskripsi_bimbingan': deskripsi_bimbingan,
          'status': status,
          'file': file,
          'catatan_bimbingan': catatan_bimbingan,
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectAll(
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_all/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectId(
    String token,
    String project,
    String collection,
    String appid,
    String id,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_id/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/id/' +
        id;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectWhere(
    String token,
    String project,
    String collection,
    String appid,
    String where_field,
    String where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/where_field/' +
        where_field +
        '/where_value/' +
        where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectOrWhere(
    String token,
    String project,
    String collection,
    String appid,
    String or_where_field,
    String or_where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_or_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/or_where_field/' +
        or_where_field +
        '/or_where_value/' +
        or_where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectWhereLike(
    String token,
    String project,
    String collection,
    String appid,
    String wlike_field,
    String wlike_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_where_like/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wlike_field/' +
        wlike_field +
        '/wlike_value/' +
        wlike_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectWhereIn(
    String token,
    String project,
    String collection,
    String appid,
    String win_field,
    String win_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_where_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/win_field/' +
        win_field +
        '/win_value/' +
        win_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future selectWhereNotIn(
    String token,
    String project,
    String collection,
    String appid,
    String wnotin_field,
    String wnotin_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_where_not_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wnotin_field/' +
        wnotin_field +
        '/wnotin_value/' +
        wnotin_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future removeAll(
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_all/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeId(
    String token,
    String project,
    String collection,
    String appid,
    String id,
  ) async {
    // Coba dengan GET method sebagai workaround CORS untuk Flutter Web
    String uri =
        'https://api.247go.app/v5/remove_id/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/id/' +
        id;

    try {
      print('DEBUG removeId - Request URL: $uri');

      // Gunakan GET sebagai workaround (beberapa API support GET untuk delete)
      final response = await http.get(Uri.parse(uri));

      print(
        'DEBUG removeId - Response status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        // Cek response body untuk konfirmasi sukses
        final body = response.body.toLowerCase();
        if (body.contains('success') ||
            body.contains('deleted') ||
            body.contains('removed')) {
          return true;
        }
        // Jika status 200, anggap sukses
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('DEBUG removeId GET - Error: $e');

      // Fallback: coba dengan DELETE jika GET gagal
      try {
        String deleteUri =
            'https://api.247go.app/v5/remove_id/token/' +
            token +
            '/project/' +
            project +
            '/collection/' +
            collection +
            '/appid/' +
            appid +
            '/id/' +
            id;
        final deleteResponse = await http.delete(Uri.parse(deleteUri));

        print(
          'DEBUG removeId DELETE - Response status: ${deleteResponse.statusCode}',
        );

        if (deleteResponse.statusCode == 200) {
          return true;
        }
      } catch (e2) {
        print('DEBUG removeId DELETE - Error: $e2');
      }

      return false;
    }
  }

  Future removeWhere(
    String token,
    String project,
    String collection,
    String appid,
    String where_field,
    String where_value,
  ) async {
    // Gunakan POST method untuk menghindari CORS issue di Flutter Web
    String uri = 'https://api.247go.app/v5/remove_where/';

    try {
      print(
        'DEBUG removeWhere - Request: where_field=$where_field, where_value=$where_value, collection=$collection',
      );

      final response = await http.post(
        Uri.parse(uri),
        body: {
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
          'where_field': where_field,
          'where_value': where_value,
        },
      );

      print(
        'DEBUG removeWhere - Response status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('DEBUG removeWhere - Error: $e');
      return false;
    }
  }

  Future removeOrWhere(
    String token,
    String project,
    String collection,
    String appid,
    String or_where_field,
    String or_where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_or_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/or_where_field/' +
        or_where_field +
        '/or_where_value/' +
        or_where_value;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeWhereLike(
    String token,
    String project,
    String collection,
    String appid,
    String wlike_field,
    String wlike_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_where_like/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wlike_field/' +
        wlike_field +
        '/wlike_value/' +
        wlike_value;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeWhereIn(
    String token,
    String project,
    String collection,
    String appid,
    String win_field,
    String win_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_where_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/win_field/' +
        win_field +
        '/win_value/' +
        win_value;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future removeWhereNotIn(
    String token,
    String project,
    String collection,
    String appid,
    String wnotin_field,
    String wnotin_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_where_not_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wnotin_field/' +
        wnotin_field +
        '/wnotin_value/' +
        wnotin_value;

    try {
      final response = await http.delete(Uri.parse(uri));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Print error here
      return false;
    }
  }

  Future updateAll(
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_all/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateId(
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
    String id,
  ) async {
    String uri = 'https://api.247go.app/v5/update_id/';

    try {
      print(
        'DEBUG updateId - Request: id=$id, update_field=$update_field, update_value=$update_value, collection=$collection',
      );

      // Gunakan POST method untuk menghindari CORS issue di Flutter Web
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
          'id': id,
        },
      );

      print(
        'DEBUG updateId - Response status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('DEBUG updateId - Error: $e');
      return false;
    }
  }

  Future updateWhere(
    String where_field,
    String where_value,
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_where/';

    try {
      print(
        'DEBUG updateWhere - Request: where_field=$where_field, where_value=$where_value, update_field=$update_field, update_value=$update_value, collection=$collection',
      );

      // Gunakan POST method untuk menghindari CORS issue di Flutter Web
      final response = await http.post(
        Uri.parse(uri),
        body: {
          'where_field': where_field,
          'where_value': where_value,
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

      print(
        'DEBUG updateWhere - Response status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final body = response.body;
        // Cek apakah response mengandung "Success"
        if (body.contains('Success')) {
          return true;
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('DEBUG updateWhere - Error: $e');
      return false;
    }
  }

  Future updateOrWhere(
    String or_where_field,
    String or_where_value,
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_or_where/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'or_where_field': or_where_field,
          'or_where_value': or_where_value,
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateWhereLike(
    String wlike_field,
    String wlike_value,
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_where_like/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'wlike_field': wlike_field,
          'wlike_value': wlike_value,
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateWhereIn(
    String win_field,
    String win_value,
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_where_in/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'win_field': win_field,
          'win_value': win_value,
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateWhereNotIn(
    String wnotin_field,
    String wnotin_value,
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_where_not_in/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'wnotin_field': wnotin_field,
          'wnotin_value': wnotin_value,
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future firstAll(
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_all/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future firstWhere(
    String token,
    String project,
    String collection,
    String appid,
    String where_field,
    String where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/where_field/' +
        where_field +
        '/where_value/' +
        where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future firstOrWhere(
    String token,
    String project,
    String collection,
    String appid,
    String or_where_field,
    String or_where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_or_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/or_where_field/' +
        or_where_field +
        '/or_where_value/' +
        or_where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future firstWhereLike(
    String token,
    String project,
    String collection,
    String appid,
    String wlike_field,
    String wlike_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_where_like/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wlike_field/' +
        wlike_field +
        '/wlike_value/' +
        wlike_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future firstWhereIn(
    String token,
    String project,
    String collection,
    String appid,
    String win_field,
    String win_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_where_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/win_field/' +
        win_field +
        '/win_value/' +
        win_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future firstWhereNotIn(
    String token,
    String project,
    String collection,
    String appid,
    String wnotin_field,
    String wnotin_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_where_not_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wnotin_field/' +
        wnotin_field +
        '/wnotin_value/' +
        wnotin_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastAll(
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri =
        'https://api.247go.app/v5/last_all/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastWhere(
    String token,
    String project,
    String collection,
    String appid,
    String where_field,
    String where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/last_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/where_field/' +
        where_field +
        '/where_value/' +
        where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastOrWhere(
    String token,
    String project,
    String collection,
    String appid,
    String or_where_field,
    String or_where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/last_or_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/or_where_field/' +
        or_where_field +
        '/or_where_value/' +
        or_where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastWhereLike(
    String token,
    String project,
    String collection,
    String appid,
    String wlike_field,
    String wlike_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/last_where_like/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wlike_field/' +
        wlike_field +
        '/wlike_value/' +
        wlike_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastWhereIn(
    String token,
    String project,
    String collection,
    String appid,
    String win_field,
    String win_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/last_where_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/win_field/' +
        win_field +
        '/win_value/' +
        win_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future lastWhereNotIn(
    String token,
    String project,
    String collection,
    String appid,
    String wnotin_field,
    String wnotin_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/last_where_not_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wnotin_field/' +
        wnotin_field +
        '/wnotin_value/' +
        wnotin_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomAll(
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri =
        'https://api.247go.app/v5/random_all/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomWhere(
    String token,
    String project,
    String collection,
    String appid,
    String where_field,
    String where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/random_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/where_field/' +
        where_field +
        '/where_value/' +
        where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomOrWhere(
    String token,
    String project,
    String collection,
    String appid,
    String or_where_field,
    String or_where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/random_or_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/or_where_field/' +
        or_where_field +
        '/or_where_value/' +
        or_where_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomWhereLike(
    String token,
    String project,
    String collection,
    String appid,
    String wlike_field,
    String wlike_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/random_where_like/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wlike_field/' +
        wlike_field +
        '/wlike_value/' +
        wlike_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomWhereIn(
    String token,
    String project,
    String collection,
    String appid,
    String win_field,
    String win_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/random_where_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/win_field/' +
        win_field +
        '/win_value/' +
        win_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }

  Future randomWhereNotIn(
    String token,
    String project,
    String collection,
    String appid,
    String wnotin_field,
    String wnotin_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/random_where_not_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wnotin_field/' +
        wnotin_field +
        '/wnotin_value/' +
        wnotin_value;

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return an empty array
        return '[]';
      }
    } catch (e) {
      // Print error here
      return '[]';
    }
  }
}
