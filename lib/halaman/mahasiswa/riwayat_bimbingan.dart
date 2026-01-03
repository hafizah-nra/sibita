import 'package:flutter/material.dart';
import '../../config/restapi.dart';
import '../../config/manajer_session.dart';
import '../../model/bimbingan_model.dart';
import '../../model/dosen_model.dart';
import 'package:intl/intl.dart';

class RiwayatBimbingan extends StatefulWidget {
  const RiwayatBimbingan({Key? key}) : super(key: key);

  @override
  _RiwayatBimbinganState createState() => _RiwayatBimbinganState();
}

class _RiwayatBimbinganState extends State<RiwayatBimbingan> {
  // Color Palette
  final Color buttercream = Color(0xFFEDE2D0);
  final Color wheat = Color(0xFFE9D2A9);
  final Color apricotBrandy = Color(0xFFBB6A57);
  final Color mochaMousse = Color(0xFFA57865);
  final Color cacaoNibs = Color(0xFF7B5747);
  final Color spicedApple = Color(0xFF793937);

  late Future<List<BimbinganModel>> _bimbinganFuture;
  List<DosenModel> _cachedDosen = [];
  String _selectedFilter = 'Semua';

  final List<String> _filterOptions = [
    'Semua',
    'Diajukan',
    'Di-ACC',
    'Ditolak',
    'Selesai',
    'Lewat',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final nrp = ManajerSession.instance.mahasiswa?.nrp ?? '';
    _bimbinganFuture = _fetchBimbingan(nrp);
  }

  Future<List<BimbinganModel>> _fetchBimbingan(String nrp) async {
    // Load dosen untuk mapping nama
    _cachedDosen = await RestApi.instance.semuaDosen();

    // Load bimbingan mahasiswa
    List<BimbinganModel> bimbingan = await RestApi.instance
        .getBimbinganMahasiswa(nrp);

    // Cek dan update status bimbingan yang lewat
    final hasUpdates = await _updateExpiredBimbingan(bimbingan);

    // Jika ada yang diupdate, reload data dari backend
    if (hasUpdates) {
      bimbingan = await RestApi.instance.getBimbinganMahasiswa(nrp);
    }

    // Sort by tanggal descending (terbaru di atas)
    bimbingan.sort((a, b) => b.tanggalDateTime.compareTo(a.tanggalDateTime));

    return bimbingan;
  }

  /// Cek bimbingan yang pending dan waktu sudah lewat, update ke status 'lewat'
  /// Returns true jika ada bimbingan yang diupdate
  Future<bool> _updateExpiredBimbingan(
    List<BimbinganModel> bimbinganList,
  ) async {
    final now = DateTime.now();
    bool hasUpdates = false;

    print('DEBUG: ====== CHECKING EXPIRED BIMBINGAN ======');
    print('DEBUG: Current time: $now');
    print('DEBUG: Total bimbingan: ${bimbinganList.length}');

    for (var bimbingan in bimbinganList) {
      print('DEBUG: -----------------------------------');
      print('DEBUG: Bimbingan ID: ${bimbingan.id}');
      print('DEBUG: Status: "${bimbingan.status}"');
      print('DEBUG: Tanggal raw: "${bimbingan.tanggal}"');
      print('DEBUG: Jam Selesai raw: "${bimbingan.jamSelesai}"');
      print('DEBUG: Jam Selesai DateTime: ${bimbingan.jamSelesaiDateTime}');
      print('DEBUG: Is after? ${now.isAfter(bimbingan.jamSelesaiDateTime)}');

      // Cek jika status masih pending dan waktu selesai sudah lewat
      if (bimbingan.status.toLowerCase() == 'pending') {
        final jamSelesai = bimbingan.jamSelesaiDateTime;

        if (now.isAfter(jamSelesai)) {
          print('DEBUG: >>> KONDISI TERPENUHI - Updating status to lewat...');
          // Update status ke 'lewat' di backend
          try {
            final success = await RestApi.instance.updateStatusBimbingan(
              bimbingan.id,
              'lewat',
              catatan:
                  'Bimbingan lewat karena tidak di-ACC sebelum waktu berakhir',
            );

            print('DEBUG: Update result: $success');
            // Anggap berhasil jika tidak error
            hasUpdates = true;
            print('DEBUG: Bimbingan ${bimbingan.id} marked for reload');
          } catch (e) {
            print('DEBUG: Update error: $e');
          }
        } else {
          print('DEBUG: Waktu belum lewat');
        }
      } else {
        print('DEBUG: Status bukan pending, skip');
      }
    }

    print('DEBUG: ====== END CHECK - hasUpdates: $hasUpdates ======');
    return hasUpdates;
  }

  void _refreshData() {
    setState(() => _loadData());
  }

  String _getStatusLabel(String status) {
    // Gunakan enum untuk mendapatkan label mahasiswa
    final statusEnum = BimbinganStatus.fromString(status);
    return statusEnum.labelMahasiswa;
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
      case 'lewat':
        return Colors.grey.shade700;
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
      case 'lewat':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  /// Warna untuk filter chip berdasarkan filter name
  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Semua':
        return wheat;
      case 'Diajukan':
        return Colors.orange;
      case 'Di-ACC':
        return Colors.blue;
      case 'Ditolak':
        return Colors.red;
      case 'Selesai':
        return Colors.green;
      case 'Lewat':
        return Colors.grey.shade600;
      default:
        return wheat;
    }
  }

  /// Icon untuk filter chip
  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Semua':
        return Icons.all_inclusive;
      case 'Diajukan':
        return Icons.hourglass_empty;
      case 'Di-ACC':
        return Icons.check_circle;
      case 'Ditolak':
        return Icons.cancel;
      case 'Selesai':
        return Icons.task_alt;
      case 'Lewat':
        return Icons.schedule;
      default:
        return Icons.filter_list;
    }
  }

  List<BimbinganModel> _filterBimbingan(List<BimbinganModel> list) {
    if (_selectedFilter == 'Semua') return list;

    return list.where((b) {
      final label = _getStatusLabel(b.status);
      return label == _selectedFilter;
    }).toList();
  }

  String _getDosenName(String nip) {
    try {
      final dosen = _cachedDosen.firstWhere((d) => d.nip == nip);
      return dosen.nama;
    } catch (e) {
      return 'Dosen tidak ditemukan';
    }
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
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: spicedApple,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Status',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      final filterColor = _getFilterColor(filter);
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: isSelected
                              ? null
                              : Icon(
                                  _getFilterIcon(filter),
                                  size: 16,
                                  color: filterColor,
                                ),
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedFilter = filter);
                          },
                          backgroundColor: filterColor.withOpacity(0.15),
                          selectedColor: filterColor.withOpacity(0.9),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : filterColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color: filterColor.withOpacity(0.5),
                            width: 1.5,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: FutureBuilder<List<BimbinganModel>>(
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
                final filteredBimbingan = _filterBimbingan(allBimbingan);

                if (allBimbingan.isEmpty) {
                  return _buildEmptyState();
                }

                if (filteredBimbingan.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 64,
                          color: mochaMousse,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada bimbingan dengan status "$_selectedFilter"',
                          style: TextStyle(
                            color: cacaoNibs,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedFilter = 'Semua'),
                          child: Text(
                            'Tampilkan Semua',
                            style: TextStyle(color: apricotBrandy),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _refreshData(),
                  color: apricotBrandy,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredBimbingan.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: _buildBimbinganCard(filteredBimbingan[index]),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
              child: Icon(Icons.history, size: 64, color: mochaMousse),
            ),
            SizedBox(height: 24),
            Text(
              'Belum Ada Riwayat Bimbingan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cacaoNibs,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Ajukan bimbingan melalui slot yang tersedia untuk memulai',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: mochaMousse),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/mahasiswa/slot/list'),
              icon: Icon(Icons.calendar_today),
              label: Text('Lihat Slot Tersedia'),
              style: ElevatedButton.styleFrom(
                backgroundColor: apricotBrandy,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
    final dosenName = _getDosenName(bimbingan.nip);

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
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                // Info Dosen dan Waktu
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(Icons.person, 'Dosen', dosenName),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.access_time,
                        'Waktu',
                        '${DateFormat('HH:mm').format(bimbingan.jamMulaiDateTime)} - ${DateFormat('HH:mm').format(bimbingan.jamSelesaiDateTime)}',
                      ),
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
                  ),
                ),

                // Catatan/Alasan Penolakan (jika ada)
                if (bimbingan.catatanBimbingan.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    bimbingan.status.toLowerCase() == 'ditolak'
                        ? 'Alasan Penolakan'
                        : 'Catatan dari Dosen',
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
                            style: TextStyle(color: cacaoNibs, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Tombol Ajukan Ulang (untuk status ditolak atau lewat)
                if (bimbingan.status.toLowerCase() == 'ditolak' ||
                    bimbingan.status.toLowerCase() == 'lewat') ...[
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/mahasiswa/slot/list');
                      },
                      icon: Icon(Icons.refresh),
                      label: Text(
                        'Ajukan Ulang ke Slot Lain',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: apricotBrandy,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                // File (jika ada)
                if (bimbingan.hasFile) ...[
                  SizedBox(height: 16),
                  Text(
                    'File Lampiran',
                    style: TextStyle(
                      fontSize: 12,
                      color: mochaMousse,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      // TODO: Implementasi download/preview file
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
                                  bimbingan.file,
                                  style: TextStyle(
                                    color: cacaoNibs,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Tap untuk melihat',
                                  style: TextStyle(
                                    color: mochaMousse,
                                    fontSize: 11,
                                  ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: mochaMousse),
        SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 12, color: mochaMousse)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: cacaoNibs,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
