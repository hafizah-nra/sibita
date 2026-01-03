/// Enum untuk tipe slot bimbingan
enum TipeSlot {
  fleksibel,
  tetap;

  String get nama {
    switch (this) {
      case TipeSlot.fleksibel:
        return 'Fleksibel';
      case TipeSlot.tetap:
        return 'Tetap';
    }
  }

  static TipeSlot fromString(String value) {
    switch (value.toLowerCase()) {
      case 'tetap':
        return TipeSlot.tetap;
      default:
        return TipeSlot.fleksibel;
    }
  }
}

/// Enum untuk hari dalam seminggu
enum HariSlot {
  senin,
  selasa,
  rabu,
  kamis,
  jumat,
  sabtu,
  minggu;

  String get nama {
    switch (this) {
      case HariSlot.senin:
        return 'Senin';
      case HariSlot.selasa:
        return 'Selasa';
      case HariSlot.rabu:
        return 'Rabu';
      case HariSlot.kamis:
        return 'Kamis';
      case HariSlot.jumat:
        return 'Jumat';
      case HariSlot.sabtu:
        return 'Sabtu';
      case HariSlot.minggu:
        return 'Minggu';
    }
  }

  int get weekday {
    switch (this) {
      case HariSlot.senin:
        return DateTime.monday;
      case HariSlot.selasa:
        return DateTime.tuesday;
      case HariSlot.rabu:
        return DateTime.wednesday;
      case HariSlot.kamis:
        return DateTime.thursday;
      case HariSlot.jumat:
        return DateTime.friday;
      case HariSlot.sabtu:
        return DateTime.saturday;
      case HariSlot.minggu:
        return DateTime.sunday;
    }
  }

  static HariSlot fromString(String value) {
    switch (value.toLowerCase()) {
      case 'senin':
        return HariSlot.senin;
      case 'selasa':
        return HariSlot.selasa;
      case 'rabu':
        return HariSlot.rabu;
      case 'kamis':
        return HariSlot.kamis;
      case 'jumat':
        return HariSlot.jumat;
      case 'sabtu':
        return HariSlot.sabtu;
      case 'minggu':
        return HariSlot.minggu;
      default:
        return HariSlot.senin;
    }
  }
}

class SlotModel {
   final String id;
   final String idBimbingan;
   final String nip; // NIP dosen
   final String tanggal;
   final String jamMulai;
   final String jamSelesai;
   final String lokasi;
   final String kapasitas;
   final String pendaftar; // List NRP dipisah koma, misal: "123,456,789"
   final String tipe;
   final String hari;

   SlotModel({
      required this.id,
      required this.idBimbingan,
      required this.nip,
      required this.tanggal,
      required this.jamMulai,
      required this.jamSelesai,
      required this.lokasi,
      required this.kapasitas,
      required this.pendaftar,
      required this.tipe,
      required this.hari,
   });

   factory SlotModel.fromJson(Map data) {
      return SlotModel(
         id: data['_id'] ?? data['id'] ?? '',
         idBimbingan: data['id_bimbingan'] ?? '',
         nip: data['nip'] ?? '',
         tanggal: data['tanggal'] ?? '',
         jamMulai: data['jam_mulai'] ?? '',
         jamSelesai: data['jam_selesai'] ?? '',
         lokasi: data['lokasi'] ?? '',
         kapasitas: data['kapasitas'] ?? '0',
         pendaftar: data['pendaftar'] ?? '',
         tipe: data['tipe'] ?? '',
         hari: data['hari'] ?? '',
      );
   }

   Map<String, dynamic> toJson() {
      return {
         '_id': id,
         'id_bimbingan': idBimbingan,
         'nip': nip,
         'tanggal': tanggal,
         'jam_mulai': jamMulai,
         'jam_selesai': jamSelesai,
         'lokasi': lokasi,
         'kapasitas': kapasitas,
         'pendaftar': pendaftar,
         'tipe': tipe,
         'hari': hari,
      };
   }

   /// Mendapatkan list NRP pendaftar
   List<String> get listPendaftar {
      if (pendaftar.isEmpty) return [];
      return pendaftar.split(',').where((e) => e.isNotEmpty).toList();
   }

   /// Cek apakah kapasitas unlimited (-1)
   bool get isUnlimited => kapasitasInt == -1;

   /// Cek apakah slot sudah penuh
   bool get isFull {
      // Unlimited tidak pernah penuh
      if (isUnlimited) return false;
      final kap = kapasitasInt;
      if (kap <= 0) return true; // Kapasitas 0 atau invalid = penuh
      return listPendaftar.length >= kap;
   }

   /// Sisa kapasitas
   int get sisaKapasitas {
      if (isUnlimited) return -1; // -1 indicates unlimited
      final kap = kapasitasInt;
      return kap - listPendaftar.length;
   }

   /// Kapasitas sebagai int
   int get kapasitasInt => int.tryParse(kapasitas) ?? 0;

   /// Format kapasitas untuk tampilan (contoh: "3/5" atau "3 Terdaftar")
   String get kapasitasDisplay {
      final jumlahPendaftar = listPendaftar.length;
      if (isUnlimited) {
         return '$jumlahPendaftar Terdaftar';
      }
      return '$jumlahPendaftar/$kapasitas';
   }

   /// Label kapasitas untuk tampilan yang user-friendly
   String get kapasitasLabel {
      if (isUnlimited) {
         return 'Tak Terbatas';
      }
      return '$kapasitas Mahasiswa';
   }

   /// Cek apakah slot sudah lewat (berdasarkan waktu selesai)
   bool get isExpired {
      final now = DateTime.now();
      final slotDate = tanggalDateTime;
      final slotEndTime = DateTime(
         slotDate.year, slotDate.month, slotDate.day,
         jamSelesaiDateTime.hour, jamSelesaiDateTime.minute,
      );
      return now.isAfter(slotEndTime);
   }

   /// Cek apakah slot hari ini
   bool get isToday {
      final now = DateTime.now();
      final slotDate = tanggalDateTime;
      return now.year == slotDate.year && 
             now.month == slotDate.month && 
             now.day == slotDate.day;
   }

   /// Cek apakah slot masih tersedia untuk didaftari
   bool get isAvailable {
      if (isExpired) return false;
      if (isFull) return false;
      return true;
   }

   /// Status waktu slot
   String get statusWaktu {
      if (isExpired) return 'Sudah Lewat';
      if (isToday) return 'Hari Ini';
      return 'Mendatang';
   }

   /// Status ketersediaan slot
   String get statusSlot {
      if (isExpired) return 'Lewat';
      if (isFull) return 'Penuh';
      if (isUnlimited) return 'Tak Terbatas';
      return 'Tersedia';
   }

   /// Tipe slot sebagai enum
   TipeSlot get tipeSlot => TipeSlot.fromString(tipe);

   /// Hari sebagai enum
   HariSlot get hariSlot => HariSlot.fromString(hari);

   /// Parse tanggal dari string
   DateTime get tanggalDateTime {
      try {
         return DateTime.parse(tanggal);
      } catch (e) {
         return DateTime.now();
      }
   }

   /// Parse jam mulai dari string
   DateTime get jamMulaiDateTime {
      try {
         return DateTime.parse(jamMulai);
      } catch (e) {
         return DateTime.now();
      }
   }

   /// Parse jam selesai dari string  
   DateTime get jamSelesaiDateTime {
      try {
         return DateTime.parse(jamSelesai);
      } catch (e) {
         return DateTime.now();
      }
   }
}