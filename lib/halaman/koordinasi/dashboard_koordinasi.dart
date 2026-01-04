// dashboard_koordinasi.dart - FIXED STATISTICS & DROPDOWN
import 'package:flutter/material.dart';
import '../../config/restapi.dart';
import '../../config/manajer_session.dart';
import '../../model/mahasiswa_model.dart';
import '../../model/dosen_model.dart';
import '../../model/permintaan_model.dart';
import '../koordinasi/profile_koordinator.dart';

// ==================== REUSABLE LOADING POPUP ====================
class LoadingPopup {
  static const Color apricotBrandy = Color(0xFFBB6A57);
  static const Color cacaoNibs = Color(0xFF7B5747);

  /// Menampilkan popup loading compact
  /// [context] - BuildContext
  /// [message] - Teks status (Menyimpan..., Menghapus..., Memperbarui...)
  static void show(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(apricotBrandy),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    message,
                    style: TextStyle(
                      color: cacaoNibs,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                      decorationThickness: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Menutup popup loading
  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}

class DashboardKoordinasi extends StatefulWidget {
  final DosenModel koordinator;

  const DashboardKoordinasi({Key? key, required this.koordinator})
    : super(key: key);

  @override
  _DashboardKoordinasiState createState() => _DashboardKoordinasiState();
}

class _DashboardKoordinasiState extends State<DashboardKoordinasi> {
  // Color Palette
  static const Color buttercream = Color(0xFFEDE2D0);
  static const Color wheat = Color(0xFFE9D2A9);
  static const Color apricotBrandy = Color(0xFFBB6A57);
  static const Color mochaMousse = Color(0xFFA57865);
  static const Color cacaoNibs = Color(0xFF7B5747);
  static const Color spicedApple = Color(0xFF793937);

  List<PermintaanModel> permintaanList = [];
  List<MahasiswaModel> mahasiswaList = [];
  List<DosenModel> dosenList = [];

  bool isLoading = true;
  String searchQuery = "";
  String filterStatus = "Semua";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final api = RestApi.instance;

      final results = await Future.wait([
        api.semuaPermintaan(),
        api.semuaMahasiswa(),
        api.semuaDosen(),
      ]);

      permintaanList = results[0] as List<PermintaanModel>;
      mahasiswaList = results[1] as List<MahasiswaModel>;
      dosenList = results[2] as List<DosenModel>;

      // Debug: Print data permintaan untuk melihat status
      print('DEBUG _loadData - Total permintaan: ${permintaanList.length}');
      for (var p in permintaanList) {
        print(
          'DEBUG - ID: ${p.id}, NRP: ${p.nrp}, Status: ${p.status}, Nip: ${p.nip}',
        );
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(context, 'Gagal memuat data: $e');
      }
    }
  }

  // Statistik berdasarkan data permintaan
  int get totalPermintaan => permintaanList.length;

  int get sudahDitetapkan {
    final count = permintaanList.where((p) {
      final hasPembimbing =
          p.pembimbingNip != null && p.pembimbingNip!.isNotEmpty;
      final statusTerima = p.status == 'terima';
      return hasPembimbing && statusTerima;
    }).length;
    print('DEBUG sudahDitetapkan: $count');
    return count;
  }

  int get belumDitetapkan {
    final count = permintaanList.where((p) {
      final noPembimbing = p.pembimbingNip == null || p.pembimbingNip!.isEmpty;
      final statusPending = p.status == 'pending';
      return noPembimbing || statusPending;
    }).length;
    print('DEBUG belumDitetapkan: $count');
    return count;
  }

  List<PermintaanModel> get filteredPermintaan {
    return permintaanList.where((p) {
      MahasiswaModel? mahasiswa;
      try {
        mahasiswa = mahasiswaList.firstWhere((m) => m.nrp == p.nrp);
      } catch (e) {
        return false;
      }

      final matchSearch =
          mahasiswa.nama.toLowerCase().contains(searchQuery.toLowerCase()) ||
          mahasiswa.nrp.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.judul.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.bidang.toLowerCase().contains(searchQuery.toLowerCase());

      if (filterStatus == "Sudah Ditetapkan") {
        final hasPembimbing =
            p.pembimbingNip != null && p.pembimbingNip!.isNotEmpty;
        final statusTerima = p.status == 'terima';
        return matchSearch && hasPembimbing && statusTerima;
      } else if (filterStatus == "Belum Ditetapkan") {
        final noPembimbing =
            p.pembimbingNip == null || p.pembimbingNip!.isEmpty;
        final statusPending = p.status == 'pending';
        return matchSearch && (noPembimbing || statusPending);
      }
      return matchSearch;
    }).toList();
  }

  void _showPilihDosenDialog(PermintaanModel permintaan) {
    String? selectedNip =
        (permintaan.pembimbingNip != null &&
            permintaan.pembimbingNip!.isNotEmpty)
        ? permintaan.pembimbingNip
        : null;

    MahasiswaModel? mahasiswa;
    try {
      mahasiswa = mahasiswaList.firstWhere((m) => m.nrp == permintaan.nrp);
    } catch (e) {
      SnackBarHelper.showError(context, 'Data mahasiswa tidak ditemukan');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(24),
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: wheat.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.person_add_rounded,
                              color: apricotBrandy,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tetapkan Pembimbing',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: cacaoNibs,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Pilih dosen pembimbing',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: mochaMousse,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Info Mahasiswa
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: buttercream.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mahasiswa',
                              style: TextStyle(
                                fontSize: 12,
                                color: mochaMousse,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: apricotBrandy.withOpacity(
                                    0.2,
                                  ),
                                  child: Text(
                                    mahasiswa!.nama.isNotEmpty
                                        ? mahasiswa.nama[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: apricotBrandy,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mahasiswa.nama,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: cacaoNibs,
                                        ),
                                      ),
                                      Text(
                                        mahasiswa.nrp,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: mochaMousse,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Info TA
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: wheat.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: wheat),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detail Permintaan TA',
                              style: TextStyle(
                                fontSize: 12,
                                color: mochaMousse,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.title,
                              'Judul',
                              permintaan.judul,
                            ),
                            SizedBox(height: 8),
                            _buildDetailRow(
                              Icons.category,
                              'Bidang',
                              permintaan.bidang,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Dropdown Dosen
                      Text(
                        'Pilih Dosen Pembimbing',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cacaoNibs,
                        ),
                      ),
                      SizedBox(height: 8),

                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: wheat.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: wheat),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedNip,
                            isExpanded: true,
                            hint: Text(
                              'Pilih dosen...',
                              style: TextStyle(
                                color: mochaMousse.withOpacity(0.7),
                              ),
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down_rounded,
                              color: apricotBrandy,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            dropdownColor: Colors.white,
                            itemHeight: 60,
                            menuMaxHeight: 300,
                            items: dosenList.map((dosen) {
                              return DropdownMenuItem<String>(
                                value: dosen.nip,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: apricotBrandy.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 18,
                                        color: apricotBrandy,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            dosen.nama,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: cacaoNibs,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          Text(
                                            'NIP: ${dosen.nip}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: mochaMousse,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              setDialogState(() {
                                selectedNip = value;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: mochaMousse,
                                side: BorderSide(color: wheat, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Batal',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: selectedNip == null
                                  ? null
                                  : () async {
                                      Navigator.pop(dialogContext);
                                      await _tetapkanPembimbing(
                                        permintaan,
                                        selectedNip!,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: apricotBrandy,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                disabledBackgroundColor: mochaMousse
                                    .withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tetapkan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: apricotBrandy),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: mochaMousse,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: cacaoNibs,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _tetapkanPembimbing(
    PermintaanModel permintaan,
    String nipDosen,
  ) async {
    // Show loading
    LoadingPopup.show(context, 'Menyimpan...');

    try {
      final api = RestApi.instance;

      print(
        'DEBUG _tetapkanPembimbing - Permintaan ID: ${permintaan.id}, NRP: ${permintaan.nrp}, Dosen NIP: $nipDosen',
      );

      // Update status permintaan di database menggunakan NRP (karena ID mungkin kosong)
      final success = await api.updateStatusPermintaanByNrp(
        permintaan.nrp,
        PermintaanStatus.terima,
        pembimbingNip: nipDosen,
      );

      // Tutup loading dialog
      if (mounted) LoadingPopup.hide(context);

      if (success) {
        SnackBarHelper.showSuccess(
          context,
          'Dosen pembimbing berhasil ditetapkan!',
        );

        // Reload data untuk update statistik
        await _loadData();
      } else {
        SnackBarHelper.showError(context, 'Gagal menetapkan dosen pembimbing');
      }
    } catch (e) {
      if (mounted) LoadingPopup.hide(context);
      SnackBarHelper.showError(context, 'Terjadi kesalahan: $e');
    }
  }

  Future<void> _hapusPembimbing(PermintaanModel permintaan) async {
    MahasiswaModel? mahasiswa;
    try {
      mahasiswa = mahasiswaList.firstWhere((m) => m.nrp == permintaan.nrp);
    } catch (e) {
      SnackBarHelper.showError(context, 'Data mahasiswa tidak ditemukan');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: spicedApple),
            SizedBox(width: 12),
            Text('Konfirmasi'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus penetapan dosen pembimbing untuk ${mahasiswa!.nama}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: mochaMousse)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: spicedApple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    LoadingPopup.show(context, 'Menghapus...');

    try {
      final api = RestApi.instance;

      print('DEBUG _hapusPembimbing - NRP: ${permintaan.nrp}');

      // Update status permintaan ke pending dan hapus pembimbingNip menggunakan NRP
      final success = await api.hapusPembimbingDanResetStatus(permintaan.nrp);

      if (mounted) LoadingPopup.hide(context);

      if (success) {
        SnackBarHelper.showSuccess(context, 'Pembimbing berhasil dihapus');
        await _loadData();
      } else {
        SnackBarHelper.showError(context, 'Gagal menghapus pembimbing');
      }
    } catch (e) {
      if (mounted) LoadingPopup.hide(context);
      SnackBarHelper.showError(context, 'Terjadi kesalahan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: buttercream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.logout_rounded, color: cacaoNibs),
          onPressed: () => _showLogoutDialog(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permintaan Tugas Akhir',
              style: TextStyle(
                color: cacaoNibs,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Kelola permintaan dan pembimbing',
              style: TextStyle(color: mochaMousse, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: apricotBrandy),
            onPressed: _loadData,
          ),
          IconButton(
            icon: Icon(Icons.person_rounded, color: apricotBrandy),
            tooltip: 'Profil Koordinator',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfilKoordinatorPage(koordinator: widget.koordinator),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(apricotBrandy),
              ),
            )
          : Column(
              children: [
                // Search & Filter
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (value) =>
                            setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Cari mahasiswa, judul, atau bidang...',
                          hintStyle: TextStyle(
                            color: mochaMousse.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: apricotBrandy,
                          ),
                          filled: true,
                          fillColor: wheat.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 20,
                            color: mochaMousse,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('Semua'),
                                  SizedBox(width: 8),
                                  _buildFilterChip('Sudah Ditetapkan'),
                                  SizedBox(width: 8),
                                  _buildFilterChip('Belum Ditetapkan'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Statistics
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Permintaan',
                          totalPermintaan.toString(),
                          Icons.description_rounded,
                          apricotBrandy,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Sudah Ditetapkan',
                          sudahDitetapkan.toString(),
                          Icons.check_circle_rounded,
                          Colors.green.shade700,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Belum Ditetapkan',
                          belumDitetapkan.toString(),
                          Icons.pending_rounded,
                          Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: filteredPermintaan.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredPermintaan.length,
                          itemBuilder: (context, index) {
                            final permintaan = filteredPermintaan[index];
                            MahasiswaModel? mahasiswa;
                            try {
                              mahasiswa = mahasiswaList.firstWhere(
                                (m) => m.nrp == permintaan.nrp,
                              );
                            } catch (e) {
                              return SizedBox.shrink();
                            }

                            DosenModel? dosen;
                            if (permintaan.pembimbingNip != null &&
                                permintaan.pembimbingNip!.isNotEmpty) {
                              try {
                                dosen = dosenList.firstWhere(
                                  (d) => d.nip == permintaan.pembimbingNip,
                                );
                              } catch (e) {
                                dosen = null;
                              }
                            }

                            return _buildPermintaanCard(
                              permintaan,
                              mahasiswa,
                              dosen,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: apricotBrandy),
            SizedBox(width: 12),
            Text('Keluar'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal', style: TextStyle(color: mochaMousse)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Tutup dialog dulu

              // Set flag navigating dan logout
              final session = ManajerSession.instance;
              session.startNavigation();
              session.logout();

              // Navigasi ke login dan hapus semua route sebelumnya
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );

              // End navigation setelah navigasi selesai
              Future.delayed(Duration(milliseconds: 100), () {
                session.endNavigation();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: apricotBrandy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: mochaMousse.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'Tidak ada permintaan TA',
            style: TextStyle(color: mochaMousse, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = filterStatus == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => filterStatus = label),
      backgroundColor: wheat.withOpacity(0.3),
      selectedColor: apricotBrandy,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : cacaoNibs,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? apricotBrandy : wheat, width: 1),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cacaoNibs.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: cacaoNibs,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: mochaMousse),
          ),
        ],
      ),
    );
  }

  Widget _buildPermintaanCard(
    PermintaanModel permintaan,
    MahasiswaModel mahasiswa,
    DosenModel? dosen,
  ) {
    // Cek apakah sudah punya pembimbing (status terima dan ada dosen)
    final hasPembimbing = dosen != null && permintaan.status == 'terima';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cacaoNibs.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showPilihDosenDialog(permintaan),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: apricotBrandy.withOpacity(0.2),
                    child: Text(
                      mahasiswa.nama.isNotEmpty
                          ? mahasiswa.nama[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: apricotBrandy,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mahasiswa.nama,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cacaoNibs,
                          ),
                        ),
                        Text(
                          mahasiswa.nrp,
                          style: TextStyle(fontSize: 13, color: mochaMousse),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: mochaMousse),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'tetapkan' || value == 'ubah') {
                        _showPilihDosenDialog(permintaan);
                      } else if (value == 'hapus') {
                        _hapusPembimbing(permintaan);
                      }
                    },
                    itemBuilder: (context) => [
                      if (!hasPembimbing)
                        PopupMenuItem(
                          value: 'tetapkan',
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                color: apricotBrandy,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text('Tetapkan Pembimbing'),
                            ],
                          ),
                        ),
                      if (hasPembimbing) ...[
                        PopupMenuItem(
                          value: 'ubah',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text('Ubah Pembimbing'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'hapus',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: spicedApple,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text('Hapus Pembimbing'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(color: wheat.withOpacity(0.5)),
              SizedBox(height: 12),

              // Judul TA
              Row(
                children: [
                  Icon(Icons.title, size: 16, color: apricotBrandy),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Judul TA',
                          style: TextStyle(
                            fontSize: 11,
                            color: mochaMousse,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          permintaan.judul,
                          style: TextStyle(
                            fontSize: 13,
                            color: cacaoNibs,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Bidang & IPK
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.category, size: 16, color: apricotBrandy),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bidang',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: mochaMousse,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                permintaan.bidang,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cacaoNibs,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Status Pembimbing
              if (hasPembimbing)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 20,
                          color: Colors.green.shade700,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dosen Pembimbing',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              dosen.nama,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'NIP: ${dosen.nip}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green.shade700,
                        size: 24,
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending_rounded,
                        size: 20,
                        color: Colors.orange.shade700,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Belum ditetapkan dosen pembimbing',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SnackBarHelper {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}
