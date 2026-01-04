class MahasiswaModel {
   final String id;
   final String nrp;
   final String nama;
   final String email;
   final String password;
   final String fotoProfil;
   final String ipk;
   final String judul;
   final String nip; // NIP dosen pembimbing

   MahasiswaModel({
      required this.id,
      required this.nrp,
      required this.nama,
      required this.email,
      required this.password,
      required this.fotoProfil,
      required this.ipk,
      required this.judul,
      required this.nip,
   });

   factory MahasiswaModel.fromJson(Map data) {
      return MahasiswaModel(
         id: data['_id'] ?? data['id'] ?? '',
         nrp: data['nrp'] ?? '',
         nama: data['nama'] ?? '',
         email: data['email'] ?? '',
         password: data['password'] ?? '',
         fotoProfil: data['foto_profile'] ?? '',
         ipk: data['ipk'] ?? '',
         judul: data['judul'] ?? '',
         nip: data['nip'] ?? '',
      );
   }

   Map<String, dynamic> toJson() {
      return {
         '_id': id,
         'nrp': nrp,
         'nama': nama,
         'email': email,
         'password': password,
         'foto_profile': fotoProfil,
         'ipk': ipk,
         'judul': judul,
         'nip': nip,
      };
   }
}