/// Enum untuk status permintaan bimbingan
enum PermintaanStatus {
  pending,
  terima,
  tolak;

  String get nama {
    switch (this) {
      case PermintaanStatus.pending:
        return 'Menunggu';
      case PermintaanStatus.terima:
        return 'Diterima';
      case PermintaanStatus.tolak:
        return 'Ditolak';
    }
  }

  static PermintaanStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'terima':
        return PermintaanStatus.terima;
      case 'tolak':
        return PermintaanStatus.tolak;
      default:
        return PermintaanStatus.pending;
    }
  }
}

class PermintaanModel {
   final String id;
   final String nrp;
   final String judul;
   final String bidang;
   final String nip; // NIP dosen pembimbing (pembimbingNip)
   final String status;
   final String ipk; // IPK mahasiswa

   PermintaanModel({
      required this.id,
      required this.nrp,
      required this.judul,
      required this.bidang,
      required this.nip,
      required this.status,
      this.ipk = '',
   });

   factory PermintaanModel.fromJson(Map data) {
      return PermintaanModel(
         id: data['_id'] ?? data['id'] ?? '',
         nrp: data['nrp'] ?? '',
         judul: data['judul'] ?? '',
         bidang: data['bidang'] ?? '',
         nip: data['nip'] ?? '',
         status: data['status'] ?? 'pending',
         ipk: data['ipk']?.toString() ?? '',
      );
   }

   Map<String, dynamic> toJson() {
      return {
         '_id': id,
         'nrp': nrp,
         'judul': judul,
         'bidang': bidang,
         'nip': nip,
         'status': status,
         'ipk': ipk,
      };
   }

   /// Getter untuk pembimbingNip (alias dari nip untuk kompatibilitas)
   String? get pembimbingNip => nip.isEmpty ? null : nip;

   /// Status sebagai enum
   PermintaanStatus get statusEnum => PermintaanStatus.fromString(status);
}