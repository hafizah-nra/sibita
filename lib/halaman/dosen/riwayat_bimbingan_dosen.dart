import 'package:flutter/material.dart';
import '../../config/restapi.dart';
import '../../config/manajer_session.dart';
import '../../model/bimbingan_model.dart';
import '../../model/mahasiswa_model.dart';
import 'package:intl/intl.dart';

class RiwayatBimbinganDosen extends StatefulWidget {
  const RiwayatBimbinganDosen({Key? key}) : super(key: key);

  @override
  _RiwayatBimbinganDosenState createState() => _RiwayatBimbinganDosenState();
}

class _RiwayatBimbinganDosenState extends State<RiwayatBimbinganDosen>
    with SingleTickerProviderStateMixin {
  // Color Palette
  final Color buttercream = Color(0xFFEDE2D0);
  final Color wheat = Color(0xFFE9D2A9);
  final Color apricotBrandy = Color(0xFFBB6A57);
  final Color mochaMousse = Color(0xFFA57865);
  final Color cacaoNibs = Color(0xFF7B5747);
  final Color spicedApple = Color(0xFF793937);

  late TabController _tabController;
  late Future<List<BimbinganModel>> _bimbinganFuture;
  List<MahasiswaModel> _cachedMahasiswa = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final nip = ManajerSession.instance.dosen?.nip ?? '';
    _bimbinganFuture = _fetchBimbingan(nip);
  }

  Future<List<BimbinganModel>> _fetchBimbingan(String nip) async {
    // Load semua mahasiswa untuk mapping nama
    _cachedMahasiswa = await RestApi.instance.semuaMahasiswa();

    // Load bimbingan dosen
    final bimbingan = await RestApi.instance.getBimbinganDosen(nip);

    // Sort by tanggal descending (terbaru di atas)
    bimbingan.sort((a, b) => b.tanggalDateTime.compareTo(a.tanggalDateTime));

    return bimbingan;
  }

  void _refreshData() {
    print('DEBUG _refreshData - Refreshing data...');
    setState(() => _loadData());
  }

  String _getStatusLabel(String status) {
    // Gunakan enum untuk mendapatkan label dosen
    final statusEnum = BimbinganStatus.fromString(status);
    return statusEnum.labelDosen;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'disetujui':
        return Colors.blue;
      case 'ditolak':
        return Colors.red;
      case 'selesai':
        return Colors.green;
      case 'dibatalkan':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'disetujui':
        return Icons.check_circle;
      case 'ditolak':
        return Icons.cancel;
      case 'selesai':
        return Icons.task_alt;
      case 'dibatalkan':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  MahasiswaModel? _getMahasiswa(String nrp) {
    try {
      return _cachedMahasiswa.firstWhere((m) => m.nrp == nrp);
    } catch (e) {
      return null;
    }
  }

  // Filter: Perlu Ditindak (pending)
  List<BimbinganModel> _filterPerluDitindak(List<BimbinganModel> list) {
    return list.where((b) => b.status.toLowerCase() == 'pending').toList();
  }

  // Filter: Proses (disetujui)
  List<BimbinganModel> _filterProses(List<BimbinganModel> list) {
    return list.where((b) => b.status.toLowerCase() == 'disetujui').toList();
  }

  // Filter: Selesai (hanya selesai)
  List<BimbinganModel> _filterSelesai(List<BimbinganModel> list) {
    return list.where((b) => b.status.toLowerCase() == 'selesai').toList();
  }

  // Filter: Ditolak
  List<BimbinganModel> _filterDitolak(List<BimbinganModel> list) {
    return list.where((b) => b.status.toLowerCase() == 'ditolak').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: buttercream,
      appBar: AppBar(
        title: Text(
          'Riwayat Bimbingan',
          style: TextStyle(color: buttercream, fontWeight: FontWeight.bold),
        ),
        backgroundColor: spicedApple,
        foregroundColor: buttercream,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            color: spicedApple,
            child: TabBar(
              controller: _tabController,
              indicatorColor: wheat,
              indicatorWeight: 3,
              labelColor: buttercream,
              unselectedLabelColor: buttercream.withOpacity(0.6),
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Perlu Ditindak'),
                Tab(text: 'Proses'),
                Tab(text: 'Selesai'),
                Tab(text: 'Ditolak'),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<BimbinganModel>>(
        future: _bimbinganFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: apricotBrandy),
                  SizedBox(height: 16),
                  Text(
                    'Memuat riwayat bimbingan...',
                    style: TextStyle(color: mochaMousse),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: spicedApple),
                  SizedBox(height: 16),
                  Text(
                    'Gagal memuat data',
                    style: TextStyle(
                      color: spicedApple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refreshData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: apricotBrandy,
                    ),
                    child: Text(
                      'Coba Lagi',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          final allBimbingan = snapshot.data ?? [];
          final perluDitindak = _filterPerluDitindak(allBimbingan);
          final proses = _filterProses(allBimbingan);
          final selesai = _filterSelesai(allBimbingan);
          final ditolak = _filterDitolak(allBimbingan);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(
                perluDitindak,
                'Perlu Ditindak',
                Icons.pending_actions,
              ),
              _buildTabContent(proses, 'Proses', Icons.sync),
              _buildTabContent(selesai, 'Selesai', Icons.check_circle_outline),
              _buildTabContent(ditolak, 'Ditolak', Icons.cancel_outlined),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabContent(
    List<BimbinganModel> list,
    String tabName,
    IconData emptyIcon,
  ) {
    if (list.isEmpty) {
      return _buildEmptyState(tabName, emptyIcon);
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      color: apricotBrandy,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: _buildBimbinganCard(list[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String tabName, IconData icon) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: wheat.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: mochaMousse),
            ),
            SizedBox(height: 24),
            Text(
              'Tidak Ada Bimbingan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cacaoNibs,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Belum ada bimbingan di tab "$tabName"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: mochaMousse),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBimbinganCard(BimbinganModel bimbingan) {
    final statusColor = _getStatusColor(bimbingan.status);
    final statusLabel = _getStatusLabel(bimbingan.status);
    final statusIcon = _getStatusIcon(bimbingan.status);
    final mahasiswa = _getMahasiswa(bimbingan.nrp);
    final namaMahasiswa = mahasiswa?.nama ?? 'Mahasiswa tidak ditemukan';
    final nrpMahasiswa = bimbingan.nrp;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cacaoNibs.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showActionBottomSheet(bimbingan),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan Status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'EEEE, dd MMMM yyyy',
                              'id_ID',
                            ).format(bimbingan.tanggalDateTime),
                            style: TextStyle(color: mochaMousse, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Badge Bab
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: apricotBrandy,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        bimbingan.bab,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Mahasiswa
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: wheat,
                          child: Icon(Icons.person, color: cacaoNibs, size: 20),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaMahasiswa,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cacaoNibs,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'NRP: $nrpMahasiswa',
                                style: TextStyle(
                                  color: mochaMousse,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Waktu
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: mochaMousse),
                        SizedBox(width: 8),
                        Text(
                          '${DateFormat('HH:mm').format(bimbingan.jamMulaiDateTime)} - ${DateFormat('HH:mm').format(bimbingan.jamSelesaiDateTime)}',
                          style: TextStyle(fontSize: 13, color: cacaoNibs),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),
                    Divider(color: wheat, thickness: 1),
                    SizedBox(height: 12),

                    // Deskripsi Bimbingan
                    Text(
                      'Deskripsi Bimbingan',
                      style: TextStyle(
                        fontSize: 12,
                        color: mochaMousse,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: buttercream.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bimbingan.deskripsiBimbingan.isNotEmpty
                            ? bimbingan.deskripsiBimbingan
                            : '-',
                        style: TextStyle(color: cacaoNibs, fontSize: 14),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Catatan/Alasan (jika ada)
                    if (bimbingan.catatanBimbingan.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        bimbingan.status.toLowerCase() == 'ditolak'
                            ? 'Alasan Penolakan'
                            : 'Catatan Bimbingan',
                        style: TextStyle(
                          fontSize: 12,
                          color: mochaMousse,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bimbingan.status.toLowerCase() == 'ditolak'
                              ? Colors.red.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: bimbingan.status.toLowerCase() == 'ditolak'
                                ? Colors.red.withOpacity(0.3)
                                : Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              bimbingan.status.toLowerCase() == 'ditolak'
                                  ? Icons.warning
                                  : Icons.comment,
                              color: bimbingan.status.toLowerCase() == 'ditolak'
                                  ? Colors.red
                                  : Colors.blue,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bimbingan.catatanBimbingan,
                                style: TextStyle(
                                  color: cacaoNibs,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // File (jika ada)
                    if (bimbingan.hasFile) ...[
                      SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('File: ${bimbingan.file}'),
                              backgroundColor: apricotBrandy,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getFileIcon(bimbingan.file),
                                color: Colors.green.shade700,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'File Lampiran',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      bimbingan.file,
                                      style: TextStyle(
                                        color: cacaoNibs,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.open_in_new,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Tap hint untuk pending
                    if (bimbingan.status.toLowerCase() == 'pending') ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tap untuk ACC / Tolak bimbingan ini',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Tap hint untuk disetujui (proses)
                    if (bimbingan.status.toLowerCase() == 'disetujui') ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.touch_app, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Tap untuk menyelesaikan & isi catatan',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionBottomSheet(BimbinganModel bimbingan) {
    final status = bimbingan.status.toLowerCase();

    if (status == 'pending') {
      _showPendingActionSheet(bimbingan);
    } else if (status == 'disetujui') {
      _showProsesActionSheet(bimbingan);
    } else {
      // Untuk status selesai/ditolak, tampilkan detail saja
      _showDetailSheet(bimbingan);
    }
  }

  void _showPendingActionSheet(BimbinganModel bimbingan) {
    final mahasiswa = _getMahasiswa(bimbingan.nrp);
    final namaMahasiswa = mahasiswa?.nama ?? 'Mahasiswa';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),

            // Title
            Text(
              'Tindakan Bimbingan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cacaoNibs,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Pengajuan bimbingan dari $namaMahasiswa',
              style: TextStyle(color: mochaMousse, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),

            // ACC Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showConfirmDialog(
                    title: 'ACC Bimbingan?',
                    message:
                        'Yakin ingin menyetujui pengajuan bimbingan dari $namaMahasiswa?',
                    confirmText: 'ACC',
                    confirmColor: Colors.green,
                    onConfirm: () => _accBimbingan(bimbingan),
                  );
                },
                icon: Icon(Icons.check_circle),
                label: Text(
                  'ACC Bimbingan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),

            // Tolak Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showTolakDialog(bimbingan);
                },
                icon: Icon(Icons.cancel),
                label: Text(
                  'Tolak Bimbingan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: spicedApple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: mochaMousse)),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _showProsesActionSheet(BimbinganModel bimbingan) {
    final mahasiswa = _getMahasiswa(bimbingan.nrp);
    final namaMahasiswa = mahasiswa?.nama ?? 'Mahasiswa';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),

            // Title
            Text(
              'Selesaikan Bimbingan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cacaoNibs,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Bimbingan dengan $namaMahasiswa',
              style: TextStyle(color: mochaMousse, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),

            // Selesaikan Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showSelesaiDialog(bimbingan);
                },
                icon: Icon(Icons.task_alt),
                label: Text(
                  'Selesaikan & Isi Catatan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: mochaMousse)),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BimbinganModel bimbingan) {
    final statusLabel = _getStatusLabel(bimbingan.status);
    final statusColor = _getStatusColor(bimbingan.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),

            // Status badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),

            Text(
              'Bimbingan ini sudah $statusLabel',
              style: TextStyle(color: mochaMousse, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),

            // Close Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup', style: TextStyle(color: mochaMousse)),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: cacaoNibs),
        ),
        content: Text(message, style: TextStyle(color: mochaMousse)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: mochaMousse)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmText, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTolakDialog(BimbinganModel bimbingan) {
    final TextEditingController alasanController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tolak Bimbingan',
          style: TextStyle(fontWeight: FontWeight.bold, color: spicedApple),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Berikan alasan penolakan:',
                style: TextStyle(color: mochaMousse),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: alasanController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Contoh: Jadwal bentrok dengan rapat...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: apricotBrandy, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alasan penolakan wajib diisi';
                  }
                  if (value.trim().length < 5) {
                    return 'Alasan minimal 5 karakter';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: mochaMousse)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _tolakBimbingan(bimbingan, alasanController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: spicedApple),
            child: Text('Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSelesaiDialog(BimbinganModel bimbingan) {
    final TextEditingController catatanController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Selesaikan Bimbingan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Isi catatan bimbingan untuk mahasiswa:',
                style: TextStyle(color: mochaMousse),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: catatanController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Contoh: Perbaiki bagian metodologi...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Catatan bimbingan wajib diisi';
                  }
                  if (value.trim().length < 5) {
                    return 'Catatan minimal 5 karakter';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: mochaMousse)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _selesaikanBimbingan(bimbingan, catatanController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Selesaikan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _accBimbingan(BimbinganModel bimbingan) async {
    // Validasi: Hanya bisa ACC dari status pending
    if (bimbingan.status.toLowerCase() != 'pending') {
      _showErrorSnackBar(
        'Bimbingan ini tidak dapat di-ACC karena sudah diproses',
      );
      return;
    }

    _showLoadingDialog('Memproses...');

    try {
      print(
        'DEBUG _accBimbingan - ID: ${bimbingan.id}, Current Status: ${bimbingan.status}',
      );

      final success = await RestApi.instance.updateStatusBimbingan(
        bimbingan.id,
        'disetujui',
      );

      print('DEBUG _accBimbingan - Update result: $success');

      Navigator.pop(context); // Close loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bimbingan berhasil di-ACC'),
            backgroundColor: Colors.green,
          ),
        );

        // Tunggu sebentar agar database sync, lalu refresh
        await Future.delayed(Duration(milliseconds: 500));
        print('DEBUG _accBimbingan - Calling _refreshData()');
        _refreshData();
      } else {
        _showErrorSnackBar('Gagal meng-ACC bimbingan');
      }
    } catch (e) {
      print('DEBUG _accBimbingan - Error: $e');
      Navigator.pop(context); // Close loading
      _showErrorSnackBar('Terjadi kesalahan: $e');
    }
  }

  Future<void> _tolakBimbingan(BimbinganModel bimbingan, String alasan) async {
    // Validasi: Hanya bisa Tolak dari status pending
    if (bimbingan.status.toLowerCase() != 'pending') {
      _showErrorSnackBar(
        'Bimbingan ini tidak dapat ditolak karena sudah diproses',
      );
      return;
    }

    _showLoadingDialog('Memproses...');

    try {
      final success = await RestApi.instance.updateStatusBimbingan(
        bimbingan.id,
        'ditolak',
        catatan: alasan,
      );

      Navigator.pop(context); // Close loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bimbingan berhasil ditolak'),
            backgroundColor: spicedApple,
          ),
        );
        _refreshData();
      } else {
        _showErrorSnackBar('Gagal menolak bimbingan');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      _showErrorSnackBar('Terjadi kesalahan: $e');
    }
  }

  Future<void> _selesaikanBimbingan(
    BimbinganModel bimbingan,
    String catatan,
  ) async {
    // Validasi: Hanya bisa Selesaikan dari status disetujui (Proses)
    if (bimbingan.status.toLowerCase() != 'disetujui') {
      _showErrorSnackBar(
        'Bimbingan ini tidak dapat diselesaikan karena belum dalam status Proses',
      );
      return;
    }

    _showLoadingDialog('Memproses...');

    try {
      final success = await RestApi.instance.updateStatusBimbingan(
        bimbingan.id,
        'selesai',
        catatan: catatan,
      );

      Navigator.pop(context); // Close loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bimbingan berhasil diselesaikan'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshData();
      } else {
        _showErrorSnackBar('Gagal menyelesaikan bimbingan');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      _showErrorSnackBar('Terjadi kesalahan: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            CircularProgressIndicator(color: apricotBrandy),
            SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: spicedApple),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}
