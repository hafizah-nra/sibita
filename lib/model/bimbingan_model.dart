/// Enum untuk status bimbingan
enum BimbinganStatus {
  pending,
  disetujui,
  ditolak,
  selesai,
  dibatalkan,
  lewat;

  /// Label untuk tampilan umum
  String get nama {
    switch (this) {
      case BimbinganStatus.pending:
        return 'Diajukan';
      case BimbinganStatus.disetujui:
        return 'Proses';
      case BimbinganStatus.ditolak:
        return 'Ditolak';
      case BimbinganStatus.selesai:
        return 'Selesai';
      case BimbinganStatus.dibatalkan:
        return 'Dibatalkan';
      case BimbinganStatus.lewat:
        return 'Lewat';
    }
  }

  String get labelMahasiswa {
    switch (this) {
      case BimbinganStatus.pending:
        return 'Diajukan';
      case BimbinganStatus.disetujui:
        return 'Di-ACC';
      case BimbinganStatus.ditolak:
        return 'Ditolak';
      case BimbinganStatus.selesai:
        return 'Selesai';
      case BimbinganStatus.dibatalkan:
        return 'Dibatalkan';
      case BimbinganStatus.lewat:
        return 'Lewat';
    }
  }

  /// Label untuk tampilan dosen (disetujui = Proses)
  String get labelDosen {
    switch (this) {
      case BimbinganStatus.pending:
        return 'Diajukan';
      case BimbinganStatus.disetujui:
        return 'Proses';
      case BimbinganStatus.ditolak:
        return 'Ditolak';
      case BimbinganStatus.selesai:
        return 'Selesai';
      case BimbinganStatus.dibatalkan:
        return 'Dibatalkan';
      case BimbinganStatus.lewat:
        return 'Lewat';
    }
  }

  static BimbinganStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'disetujui':
        return BimbinganStatus.disetujui;
      case 'ditolak':
        return BimbinganStatus.ditolak;
      case 'selesai':
        return BimbinganStatus.selesai;
      case 'dibatalkan':
        return BimbinganStatus.dibatalkan;
      case 'lewat':
        return BimbinganStatus.lewat;
      default:
        return BimbinganStatus.pending;
    }
  }
}

/// Enum untuk pilihan Bab
enum BabBimbingan {
  bab1,
  bab2,
  bab3,
  bab4,
  bab5;

  String get nama {
    switch (this) {
      case BabBimbingan.bab1:
        return 'Bab 1';
      case BabBimbingan.bab2:
        return 'Bab 2';
      case BabBimbingan.bab3:
        return 'Bab 3';
      case BabBimbingan.bab4:
        return 'Bab 4';
      case BabBimbingan.bab5:
        return 'Bab 5';
    }
  }

  static BabBimbingan fromString(String value) {
    switch (value.toLowerCase()) {
      case 'bab 1':
      case 'bab1':
        return BabBimbingan.bab1;
      case 'bab 2':
      case 'bab2':
        return BabBimbingan.bab2;
      case 'bab 3':
      case 'bab3':
        return BabBimbingan.bab3;
      case 'bab 4':
      case 'bab4':
        return BabBimbingan.bab4;
      case 'bab 5':
      case 'bab5':
        return BabBimbingan.bab5;
      default:
        return BabBimbingan.bab1;
    }
  }

  static List<String> get daftarBab => [
    'Bab 1',
    'Bab 2',
    'Bab 3',
    'Bab 4',
    'Bab 5',
  ];
}

class BimbinganModel {
  final String id;
  final String nrp; // NRP mahasiswa
  final String nip; // NIP dosen pembimbing
  final String idSlot; // ID slot yang didaftar
  final String tanggal;
  final String jamMulai;
  final String jamSelesai;
  final String bab;
  final String deskripsiBimbingan;
  final String status;
  final String file; // URL/path file (opsional)
  final String catatanBimbingan; // Catatan dari dosen

  BimbinganModel({
    required this.id,
    required this.nrp,
    required this.nip,
    required this.idSlot,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.bab,
    required this.deskripsiBimbingan,
    required this.status,
    this.file = '',
    this.catatanBimbingan = '',
  });

  factory BimbinganModel.fromJson(Map data) {
    return BimbinganModel(
      id: data['_id'] ?? data['id'] ?? '',
      nrp: data['nrp'] ?? '',
      nip: data['nip'] ?? '',
      idSlot: data['id_slot'] ?? '',
      tanggal: data['tanggal'] ?? '',
      jamMulai: data['jam_mulai'] ?? '',
      jamSelesai: data['jam_selesai'] ?? '',
      bab: data['bab'] ?? '',
      deskripsiBimbingan: data['deskripsi_bimbingan'] ?? '',
      status: data['status'] ?? 'pending',
      file: data['file'] ?? '',
      catatanBimbingan: data['catatan_bimbingan'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nrp': nrp,
      'nip': nip,
      'id_slot': idSlot,
      'tanggal': tanggal,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'bab': bab,
      'deskripsi_bimbingan': deskripsiBimbingan,
      'status': status,
      'file': file,
      'catatan_bimbingan': catatanBimbingan,
    };
  }

  /// Status sebagai enum
  BimbinganStatus get statusEnum => BimbinganStatus.fromString(status);

  /// Bab sebagai enum
  BabBimbingan get babEnum => BabBimbingan.fromString(bab);

  /// Cek apakah ada file
  bool get hasFile => file.isNotEmpty;

  /// Parse tanggal dari string
  DateTime get tanggalDateTime {
    try {
      return DateTime.parse(tanggal);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Parse jam mulai dari string (gabungkan dengan tanggal)
  DateTime get jamMulaiDateTime {
    try {
      // Coba parse langsung jika sudah format lengkap
      return DateTime.parse(jamMulai);
    } catch (e) {
      // Jika hanya jam (HH:mm), gabungkan dengan tanggal
      try {
        final tanggalDate = tanggalDateTime;
        final parts = jamMulai.split(':');
        if (parts.length >= 2) {
          return DateTime(
            tanggalDate.year,
            tanggalDate.month,
            tanggalDate.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }
      } catch (_) {}
      return DateTime.now();
    }
  }

  /// Parse jam selesai dari string (gabungkan dengan tanggal)
  DateTime get jamSelesaiDateTime {
    try {
      // Coba parse langsung jika sudah format lengkap
      return DateTime.parse(jamSelesai);
    } catch (e) {
      // Jika hanya jam (HH:mm), gabungkan dengan tanggal
      try {
        final tanggalDate = tanggalDateTime;
        final parts = jamSelesai.split(':');
        if (parts.length >= 2) {
          return DateTime(
            tanggalDate.year,
            tanggalDate.month,
            tanggalDate.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }
      } catch (_) {}
      return DateTime.now();
    }
  }
}
