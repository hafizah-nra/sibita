class DosenModel {
   final String id;
   final String nip;
   final String nama;
   final String email;
   final String password;
   final String fotoProfil;
   final String isKoordinator;

   DosenModel({
      required this.id,
      required this.nip,
      required this.nama,
      required this.email,
      required this.password,
      required this.fotoProfil,
      required this.isKoordinator,
   });

   factory DosenModel.fromJson(Map data) {
      return DosenModel(
         id: data['_id'] ?? data['id'] ?? '',
         nip: data['nip'] ?? '',
         nama: data['nama'] ?? '',
         email: data['email'] ?? '',
         password: data['password'] ?? '',
         fotoProfil: data['foto_profil'] ?? '',
         isKoordinator: data['is_koordinator'] ?? 'false',
      );
   }

   Map<String, dynamic> toJson() {
      return {
         '_id': id,
         'nip': nip,
         'nama': nama,
         'email': email,
         'password': password,
         'foto_profil': fotoProfil,
         'is_koordinator': isKoordinator,
      };
   }
}