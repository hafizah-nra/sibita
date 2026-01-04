import 'package:flutter/material.dart';
import '../../../config/restapi.dart';
import '../../../config/manajer_session.dart';
import '../../../model/slot_model.dart';
import 'edit_slot.dart';
import 'tambah_slot.dart';

class SlotColors {
  static const Color buttercream = Color(0xFFEDE2D0);
  static const Color wheat = Color(0xFFE9D2A9);
  static const Color apricotBrandy = Color(0xFFBB6A57);
  static const Color mochaMousse = Color(0xFFA57865);
  static const Color cacaoNibs = Color(0xFF7B5747);
  static const Color spicedApple = Color(0xFF793937);
}

class DaftarSlotDosen extends StatefulWidget {
  const DaftarSlotDosen({super.key});

  @override
  _DaftarSlotDosenState createState() => _DaftarSlotDosenState();
}

class _DaftarSlotDosenState extends State<DaftarSlotDosen> {
  late Future<List<SlotModel>> _slotsFuture;
  int _selectedFilter = 0;

  // Cache untuk semua slot
  final List<SlotModel> _allSlots = [];

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  void _loadSlots() {
    final d = ManajerSession.instance.dosen;
    if (d != null) {
      _slotsFuture = RestApi.instance.semuaSlotUntukDosen(d.nip);
    }
  }

  void _refreshData() {
    setState(() => _loadSlots());
  }

  // Gunakan method dari model untuk konsistensi
  bool _isSlotExpired(SlotModel slot) => slot.isExpired;

  bool _isSlotToday(SlotModel slot) => slot.isToday;

  // Cek apakah slot akan datang (bukan hari ini, belum lewat)
  bool _isSlotUpcoming(SlotModel slot) {
    return !_isSlotToday(slot) && !_isSlotExpired(slot);
  }

  // Cek apakah slot tersedia (belum lewat + tidak penuh atau unlimited)
  bool _isSlotAvailable(SlotModel slot) => slot.isAvailable;

  // Cek apakah slot penuh tapi belum lewat (bukan unlimited)
  bool _isSlotFullNotExpired(SlotModel slot) {
    if (_isSlotExpired(slot)) return false;
    if (slot.isUnlimited) return false;
    return slot.isFull;
  }

  // Filter slot berdasarkan tab
  List<SlotModel> _getFilteredSlots(List<SlotModel> slots, int tabIndex) {
    switch (tabIndex) {
      case 0: // Tersedia (belum lewat + tidak penuh/unlimited)
        return slots.where((s) => _isSlotAvailable(s)).toList();
      case 1: // Hari Ini
        return slots.where((s) => _isSlotToday(s)).toList();
      case 2: // Sudah Lewat
        return slots.where((s) => _isSlotExpired(s)).toList();
      case 3: // Penuh (belum lewat tapi sudah penuh, bukan unlimited)
        return slots.where((s) => _isSlotFullNotExpired(s)).toList();
      default:
        return slots;
    }
  }

  // Hitung jumlah slot per kategori
  int _getSlotCount(List<SlotModel> slots, int tabIndex) {
    return _getFilteredSlots(slots, tabIndex).length;
  }

  String _getSlotStatus(SlotModel slot) {
    if (_isSlotExpired(slot)) return 'Sudah Lewat';
    if (slot.isFull) return 'Penuh';
    if (slot.isUnlimited) return 'Tak Terbatas';
    return 'Tersedia';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Sudah Lewat':
        return Colors.grey;
      case 'Penuh':
        return SlotColors.spicedApple;
      case 'Tak Terbatas':
        return Colors.green;
      default:
        return SlotColors.cacaoNibs;
    }
  }

  Widget _buildFilterChip(String label, int index, int count) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? SlotColors.apricotBrandy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? SlotColors.apricotBrandy
                : SlotColors.mochaMousse.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SlotColors.apricotBrandy.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : SlotColors.cacaoNibs,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : SlotColors.mochaMousse.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : SlotColors.cacaoNibs,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _hapusSlot(String id, int jumlahPendaftar) async {
    final hasPendaftar = jumlahPendaftar > 0;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: SlotColors.buttercream,
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: SlotColors.spicedApple),
            SizedBox(width: 12),
            Text(
              'Hapus Slot?',
              style: TextStyle(
                color: SlotColors.cacaoNibs,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus slot ini?',
              style: TextStyle(color: SlotColors.cacaoNibs.withOpacity(0.8)),
            ),
            if (hasPendaftar) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SlotColors.spicedApple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: SlotColors.spicedApple.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_rounded,
                      color: SlotColors.spicedApple,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Perhatian: $jumlahPendaftar mahasiswa sudah terdaftar di slot ini. Menghapus slot akan membatalkan pendaftaran mereka.',
                        style: TextStyle(
                          color: SlotColors.spicedApple,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: SlotColors.cacaoNibs)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SlotColors.spicedApple,
            ),
            child: Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Tampilkan loading indicator yang lebih kecil
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 120,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: SlotColors.apricotBrandy,
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Menghapus...',
                  style: TextStyle(color: SlotColors.cacaoNibs, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );

      try {
        // Panggil API hapus dan tunggu hasilnya
        final success = await RestApi.instance.hapusSlot(id);

        // Tutup loading dialog
        if (mounted) Navigator.pop(context);

        if (success) {
          // Refresh data dari server
          _refreshData();

          // Tampilkan notifikasi sukses
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Slot berhasil dihapus'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Tampilkan notifikasi gagal
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Gagal menghapus slot'),
                  ],
                ),
                backgroundColor: SlotColors.spicedApple,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        // Tutup loading dialog jika masih terbuka
        if (mounted) Navigator.pop(context);

        // Tampilkan notifikasi error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Terjadi kesalahan: $e')),
                ],
              ),
              backgroundColor: SlotColors.spicedApple,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _editSlot(String id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSlot(),
        settings: RouteSettings(arguments: id),
      ),
    );
    if (result == true) _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final d = ManajerSession.instance.dosen;
    if (d == null) {
      return Scaffold(
        backgroundColor: SlotColors.buttercream,
        body: Center(
          child: Text(
            'Tidak ada dosen aktif',
            style: TextStyle(color: SlotColors.spicedApple),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: SlotColors.buttercream,
      appBar: AppBar(
        title: Text(
          'Daftar Slot Saya',
          style: TextStyle(
            color: SlotColors.buttercream,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: SlotColors.spicedApple,
        elevation: 0,
        iconTheme: IconThemeData(color: SlotColors.buttercream),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: FutureBuilder<List<SlotModel>>(
        future: _slotsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: SlotColors.apricotBrandy),
                  SizedBox(height: 16),
                  Text(
                    'Memuat slot...',
                    style: TextStyle(color: SlotColors.mochaMousse),
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
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: SlotColors.spicedApple,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Gagal memuat data',
                    style: TextStyle(
                      color: SlotColors.spicedApple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SlotColors.apricotBrandy,
                    ),
                    child: Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final semua = snapshot.data ?? [];
          final jumlahTersedia = semua.where((s) => _isSlotAvailable(s)).length;

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SlotColors.spicedApple,
                      SlotColors.apricotBrandy,
                      SlotColors.mochaMousse,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_note_rounded,
                      color: SlotColors.buttercream,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '$jumlahTersedia Slot Tersedia',
                      style: TextStyle(
                        color: SlotColors.buttercream,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Kelola jadwal konsultasi Anda',
                      style: TextStyle(
                        color: SlotColors.buttercream.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Container(
                margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tersedia', 0, _getSlotCount(semua, 0)),
                      SizedBox(width: 8),
                      _buildFilterChip('Hari Ini', 1, _getSlotCount(semua, 1)),
                      SizedBox(width: 8),
                      _buildFilterChip('Lewat', 2, _getSlotCount(semua, 2)),
                      SizedBox(width: 8),
                      _buildFilterChip('Penuh', 3, _getSlotCount(semua, 3)),
                    ],
                  ),
                ),
              ),

              // List (filtered)
              Expanded(
                child: Builder(
                  builder: (context) {
                    final filteredSlots = _getFilteredSlots(
                      semua,
                      _selectedFilter,
                    );

                    if (filteredSlots.isEmpty) {
                      String emptyMessage;
                      IconData emptyIcon;
                      switch (_selectedFilter) {
                        case 0:
                          emptyMessage = 'Tidak ada slot tersedia';
                          emptyIcon = Icons.event_available;
                          break;
                        case 1:
                          emptyMessage = 'Tidak ada slot untuk hari ini';
                          emptyIcon = Icons.today;
                          break;
                        case 2:
                          emptyMessage = 'Tidak ada slot yang sudah lewat';
                          emptyIcon = Icons.history;
                          break;
                        case 3:
                          emptyMessage = 'Tidak ada slot yang penuh';
                          emptyIcon = Icons.block;
                          break;
                        default:
                          emptyMessage = 'Belum ada slot';
                          emptyIcon = Icons.event_busy_rounded;
                      }

                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(emptyIcon, size: 80, color: SlotColors.wheat),
                            SizedBox(height: 20),
                            Text(
                              emptyMessage,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: SlotColors.cacaoNibs,
                              ),
                            ),
                            if (_selectedFilter == 0)
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Tambahkan slot konsultasi baru',
                                  style: TextStyle(
                                    color: SlotColors.cacaoNibs.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(20),
                      itemCount: filteredSlots.length,
                      itemBuilder: (context, index) {
                        final s = filteredSlots[index];
                        final hasPendaftar = s.pendaftar.isNotEmpty;
                        final status = _getSlotStatus(s);
                        final statusColor = _getStatusColor(status);

                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: SlotColors.cacaoNibs.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            SlotColors.apricotBrandy,
                                            SlotColors.mochaMousse,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: SlotColors.buttercream,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            _formatDate(s.tanggalDateTime),
                                            style: TextStyle(
                                              color: SlotColors.buttercream,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Spacer(),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      color: SlotColors.cacaoNibs,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      '${_formatTime(s.jamMulaiDateTime)} - ${_formatTime(s.jamSelesaiDateTime)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: SlotColors.cacaoNibs,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      color: SlotColors.cacaoNibs,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        s.lokasi,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: SlotColors.cacaoNibs,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: SlotColors.mochaMousse
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.people_rounded,
                                            size: 18,
                                            color: SlotColors.mochaMousse,
                                          ),
                                          SizedBox(width: 6),
                                          if (s.isUnlimited)
                                            Icon(
                                              Icons.all_inclusive,
                                              size: 14,
                                              color: SlotColors.cacaoNibs,
                                            ),
                                          if (s.isUnlimited) SizedBox(width: 4),
                                          Text(
                                            s.isUnlimited
                                                ? 'Tak Terbatas'
                                                : s.kapasitasDisplay,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: SlotColors.cacaoNibs,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Spacer(),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_rounded,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _editSlot(s.id),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: SlotColors.spicedApple,
                                      ),
                                      onPressed: () => _hapusSlot(
                                        s.id,
                                        s.listPendaftar.length,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TambahSlot()),
          );
          if (result == true) _refreshData();
        },
        backgroundColor: SlotColors.spicedApple,
        icon: Icon(Icons.add_rounded, color: SlotColors.buttercream),
        label: Text(
          'Tambah Slot',
          style: TextStyle(
            color: SlotColors.buttercream,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
