import 'package:flutter/material.dart';
import '../../../config/restapi.dart';
import '../../../config/manajer_session.dart';
import '../../../model/permintaan_model.dart';

class DaftarPermintaanTa extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final nrp = ManajerSession.instance.mahasiswa?.nrp ?? '';
    return Scaffold(
      appBar: AppBar(title: Text('Daftar Permintaan')),
      body: FutureBuilder<List<PermintaanModel>>(
        future: RestApi.instance.daftarPermintaanUntukMahasiswa(nrp),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          final daftar = snapshot.data ?? [];
          if (daftar.isEmpty) {
            return Center(child: Text('Tidak ada permintaan'));
          }
          return ListView(
            children: daftar
                .map(
                  (p) => Card(
                    child: ListTile(
                      title: Text(p.judul),
                      subtitle: Text(
                        'Status: ${p.status.toString().split('.').last}',
                      ),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/mahasiswa/permintaan/detail',
                        arguments: p.id,
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
