import 'package:flutter/material.dart';
import '../../config/restapi.dart';
import '../../config/manajer_session.dart';
import '../../model/mahasiswa_model.dart';
import '../../model/permintaan_model.dart';

// Color Palette (konsisten dengan halaman lain)
class BimbinganColors {
  static const Color buttercream = Color(0xFFEDE2D0);
  static const Color wheat = Color(0xFFE9D2A9);
  static const Color apricotBrandy = Color(0xFFBB6A57);
  static const Color mochaMousse = Color(0xFFA57865);
  static const Color cacaoNibs = Color(0xFF7B5747);
  static const Color spicedApple = Color(0xFF793937);
}

class MahasiswaBimbingan extends StatefulWidget {
  @override
  _MahasiswaBimbinganState createState() => _MahasiswaBimbinganState();
}

class _MahasiswaBimbinganState extends State<MahasiswaBimbingan> {
  String searchQuery = '';
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final d = ManajerSession.instance.dosen;
    if (d != null) {
      _dataFuture = _fetchData(d.nip);
    }
  }

  Future<Map<String, dynamic>> _fetchData(String nip) async {
    final mahasiswa = await RestApi.instance.getMahasiswaBimbingan(nip);
    final permintaan = await RestApi.instance.getPermintaanDiterima(nip);
    return {'mahasiswa': mahasiswa, 'permintaan': permintaan};
  }

  void _refreshData() => setState(() => _loadData());

  Color _getAvatarColor(int index) {
    final colors = [
      BimbinganColors.apricotBrandy,
      BimbinganColors.mochaMousse,
      BimbinganColors.spicedApple,
      BimbinganColors.cacaoNibs,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final d = ManajerSession.instance.dosen;
    
    if (d == null) {
      return Scaffold(
        backgroundColor: BimbinganColors.buttercream,
        body: Center(
          child: Text(
            'Tidak ada dosen aktif',
            style: TextStyle(
              color: BimbinganColors.spicedApple,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: BimbinganColors.buttercream,
      appBar: AppBar(
        title: Text(
          'Mahasiswa Bimbingan',
          style: TextStyle(
            color: BimbinganColors.buttercream,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: BimbinganColors.spicedApple,
        elevation: 0,
        iconTheme: IconThemeData(color: BimbinganColors.buttercream),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _refreshData)],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: BimbinganColors.apricotBrandy),
                  SizedBox(height: 16),
                  Text('Memuat data...', style: TextStyle(color: BimbinganColors.mochaMousse)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: BimbinganColors.spicedApple),
                  SizedBox(height: 16),
                  Text('Gagal memuat data', style: TextStyle(color: BimbinganColors.spicedApple, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    style: ElevatedButton.styleFrom(backgroundColor: BimbinganColors.apricotBrandy),
                    child: Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final List<MahasiswaModel> allMahasiswa = data['mahasiswa'];
          final List<PermintaanModel> permintaanDiterima = data['permintaan'];

          final filteredMahasiswa = allMahasiswa.where((m) {
            if (searchQuery.isEmpty) return true;
            return m.nama.toLowerCase().contains(searchQuery.toLowerCase()) ||
                   m.nrp.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BimbinganColors.spicedApple,
                      BimbinganColors.apricotBrandy,
                      BimbinganColors.mochaMousse,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BimbinganColors.spicedApple.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.groups_rounded,
                        color: BimbinganColors.buttercream,
                        size: 48,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '${allMahasiswa.length} Mahasiswa',
                      style: TextStyle(
                        color: BimbinganColors.buttercream,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Bimbingan Tugas Akhir',
                      style: TextStyle(
                        color: BimbinganColors.buttercream.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              if (allMahasiswa.isNotEmpty)
                Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: BimbinganColors.cacaoNibs.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Cari mahasiswa...',
                      hintStyle: TextStyle(
                        color: BimbinganColors.mochaMousse.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: BimbinganColors.apricotBrandy,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    style: TextStyle(color: BimbinganColors.cacaoNibs),
                  ),
                ),

              // List Section
              Expanded(
                child: allMahasiswa.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_rounded,
                              size: 80,
                              color: BimbinganColors.wheat,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Belum ada mahasiswa',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: BimbinganColors.cacaoNibs,
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Mahasiswa akan muncul setelah koordinator menetapkan Anda sebagai pembimbing',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: BimbinganColors.cacaoNibs.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredMahasiswa.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 80,
                                  color: BimbinganColors.wheat,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Tidak ditemukan',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: BimbinganColors.cacaoNibs,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Coba kata kunci lain',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: BimbinganColors.cacaoNibs.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: filteredMahasiswa.length,
                            itemBuilder: (context, index) {
                              final mahasiswa = filteredMahasiswa[index];

                              // Cari permintaan TA mahasiswa
                              PermintaanModel? permintaan;
                              try {
                                permintaan = permintaanDiterima.firstWhere(
                                  (p) => p.nrp == mahasiswa.nrp,
                                );
                              } catch (e) {
                                permintaan = null;
                              }

                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  // Pastikan opacity selalu dalam rentang valid 0.0 - 1.0
                                  final clampedValue = value.clamp(0.0, 1.0);
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - clampedValue)),
                                    child: Opacity(
                                      opacity: clampedValue,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _buildMahasiswaCard(mahasiswa, permintaan, index),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMahasiswaCard(MahasiswaModel mahasiswa, PermintaanModel? permintaan, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: BimbinganColors.cacaoNibs.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: permintaan != null
              ? () => _showDetailDialog(mahasiswa, permintaan)
              : null,
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getAvatarColor(index),
                        _getAvatarColor(index).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _getAvatarColor(index).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      mahasiswa.nama.isNotEmpty ? mahasiswa.nama[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: BimbinganColors.buttercream,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mahasiswa.nama,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BimbinganColors.cacaoNibs,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_rounded,
                            size: 14,
                            color: BimbinganColors.mochaMousse,
                          ),
                          SizedBox(width: 4),
                          Text(
                            mahasiswa.nrp,
                            style: TextStyle(
                              fontSize: 13,
                              color: BimbinganColors.cacaoNibs.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (permintaan != null) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: BimbinganColors.wheat.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.category_rounded,
                                size: 12,
                                color: BimbinganColors.cacaoNibs,
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  permintaan.bidang,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: BimbinganColors.cacaoNibs,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Arrow Icon
                if (permintaan != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: BimbinganColors.mochaMousse,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(MahasiswaModel mahasiswa, PermintaanModel permintaan) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          padding: EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            BimbinganColors.apricotBrandy,
                            BimbinganColors.mochaMousse,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.article_rounded,
                        color: BimbinganColors.buttercream,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Tugas Akhir',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: BimbinganColors.cacaoNibs,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            mahasiswa.nama,
                            style: TextStyle(
                              fontSize: 13,
                              color: BimbinganColors.mochaMousse,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Mahasiswa Info
                _buildInfoSection(
                  icon: Icons.person_rounded,
                  title: 'Informasi Mahasiswa',
                  items: [
                    _buildInfoRow('Nama', mahasiswa.nama),
                    _buildInfoRow('NRP', mahasiswa.nrp),
                    _buildInfoRow('Email', mahasiswa.email),
                  ],
                ),
                
                SizedBox(height: 20),
                
                // Tugas Akhir Info
                _buildInfoSection(
                  icon: Icons.school_rounded,
                  title: 'Informasi Tugas Akhir',
                  items: [
                    _buildInfoRow('Judul', permintaan.judul, maxLines: 3),
                    _buildInfoRow('Bidang', permintaan.bidang),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BimbinganColors.apricotBrandy,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Tutup',
                      style: TextStyle(
                        color: BimbinganColors.buttercream,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BimbinganColors.buttercream.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BimbinganColors.wheat,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: BimbinganColors.apricotBrandy),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: BimbinganColors.cacaoNibs,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: BimbinganColors.mochaMousse,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: BimbinganColors.cacaoNibs,
              fontWeight: FontWeight.w600,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}