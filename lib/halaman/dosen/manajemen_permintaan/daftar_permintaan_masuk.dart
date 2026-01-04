import 'package:flutter/material.dart';
import '../../../config/restapi.dart';
import '../../../config/manajer_session.dart';
import '../../../model/slot_model.dart';
import '../../../model/mahasiswa_model.dart';
import 'package:intl/intl.dart';

class PermintaanColors {
  static const Color buttercream = Color(0xFFEDE2D0);
  static const Color wheat = Color(0xFFE9D2A9);
  static const Color apricotBrandy = Color(0xFFBB6A57);
  static const Color mochaMousse = Color(0xFFA57865);
  static const Color cacaoNibs = Color(0xFF7B5747);
  static const Color spicedApple = Color(0xFF793937);
}

class DaftarPermintaanMasuk extends StatefulWidget {
  @override
  _DaftarPermintaanMasukState createState() => _DaftarPermintaanMasukState();
}

class _DaftarPermintaanMasukState extends State<DaftarPermintaanMasuk> {
  late Future<Map<String, dynamic>> _dataFuture;
  List<MahasiswaModel> _cachedMahasiswa = [];

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
    final semuaSlot = await RestApi.instance.semuaSlotUntukDosen(nip);
    final semuaMahasiswa = await RestApi.instance.semuaMahasiswa();
    _cachedMahasiswa = semuaMahasiswa;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final slotDenganPendaftar = semuaSlot.where((slot) {
      final slotDate = DateTime(slot.tanggalDateTime.year, slot.tanggalDateTime.month, slot.tanggalDateTime.day);
      return slotDate.isAfter(today.subtract(Duration(days: 1))) && slot.listPendaftar.isNotEmpty;
    }).toList()..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    final totalPendaftar = slotDenganPendaftar.fold<int>(0, (sum, slot) => sum + slot.listPendaftar.length);

    // Hitung jumlah slot yang akan datang (termasuk yang tidak ada pendaftar)
    final slotAkanDatang = semuaSlot.where((slot) {
      final slotDate = DateTime(slot.tanggalDateTime.year, slot.tanggalDateTime.month, slot.tanggalDateTime.day);
      return slotDate.isAfter(today.subtract(Duration(days: 1)));
    }).toList();

    return {
      'slotDenganPendaftar': slotDenganPendaftar, 
      'totalPendaftar': totalPendaftar,
      'totalSlot': semuaSlot.length,
      'slotAkanDatang': slotAkanDatang.length,
    };
  }

  void _refreshData() => setState(() => _loadData());

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final slotDate = DateTime(date.year, date.month, date.day);
    if (slotDate == today) return 'Hari Ini';
    if (slotDate == tomorrow) return 'Besok';
    return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showMahasiswaDetail(MahasiswaModel mahasiswa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Detail Mahasiswa', style: TextStyle(color: PermintaanColors.cacaoNibs, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: ${mahasiswa.nama}'),
            Text('NRP: ${mahasiswa.nrp}'),
            Text('Email: ${mahasiswa.email}'),
            Text('IPK: ${mahasiswa.ipk}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Tutup', style: TextStyle(color: PermintaanColors.apricotBrandy)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = ManajerSession.instance.dosen;
    if (d == null) {
      return Scaffold(backgroundColor: PermintaanColors.buttercream, body: Center(child: Text('Tidak ada dosen aktif', style: TextStyle(color: PermintaanColors.spicedApple))));
    }

    return Scaffold(
      backgroundColor: PermintaanColors.buttercream,
      appBar: AppBar(
        title: Text('Pengajuan Slot Bimbingan', style: TextStyle(color: PermintaanColors.buttercream, fontWeight: FontWeight.bold)),
        backgroundColor: PermintaanColors.spicedApple,
        elevation: 0,
        iconTheme: IconThemeData(color: PermintaanColors.buttercream),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _refreshData)],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: PermintaanColors.apricotBrandy), SizedBox(height: 16), Text('Memuat data...', style: TextStyle(color: PermintaanColors.mochaMousse))]));
          }

          if (snapshot.hasError) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.error_outline, size: 64, color: PermintaanColors.spicedApple),
              SizedBox(height: 16),
              Text('Gagal memuat data', style: TextStyle(color: PermintaanColors.spicedApple, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ElevatedButton(onPressed: _refreshData, style: ElevatedButton.styleFrom(backgroundColor: PermintaanColors.apricotBrandy), child: Text('Coba Lagi')),
            ]));
          }

          final data = snapshot.data!;
          final List<SlotModel> slotDenganPendaftar = data['slotDenganPendaftar'];
          final int totalPendaftar = data['totalPendaftar'];
          final int totalSlot = data['totalSlot'];
          final int slotAkanDatang = data['slotAkanDatang'];
          final bool belumAdaSlot = totalSlot == 0;
          final bool tidakAdaSlotAktif = slotAkanDatang == 0 && totalSlot > 0;

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [PermintaanColors.spicedApple, PermintaanColors.apricotBrandy, PermintaanColors.mochaMousse]),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
                ),
                child: Column(children: [
                  Icon(Icons.event_available_rounded, color: PermintaanColors.buttercream, size: 48),
                  SizedBox(height: 16),
                  Text('${slotDenganPendaftar.length} Slot', style: TextStyle(color: PermintaanColors.buttercream, fontSize: 28, fontWeight: FontWeight.bold)),
                  Text('$totalPendaftar mahasiswa terdaftar', style: TextStyle(color: PermintaanColors.buttercream.withOpacity(0.85))),
                ]),
              ),

              // Notifikasi Card jika belum ada slot
              if (belumAdaSlot)
                _buildReminderCard(
                  icon: Icons.warning_amber_rounded,
                  title: 'Belum Ada Slot Bimbingan',
                  subtitle: 'Anda belum membuat jadwal slot bimbingan. Buat slot agar mahasiswa dapat mendaftar.',
                  buttonText: 'Buat Slot Sekarang',
                  color: Colors.orange,
                  onTap: () async {
                    final result = await Navigator.pushNamed(context, '/dosen/slot/list');
                    if (result == true) _refreshData();
                  },
                ),

              // Notifikasi Card jika slot sudah expired semua
              if (tidakAdaSlotAktif)
                _buildReminderCard(
                  icon: Icons.schedule_rounded,
                  title: 'Slot Bimbingan Sudah Berakhir',
                  subtitle: 'Semua slot bimbingan Anda sudah lewat. Buat slot baru untuk jadwal yang akan datang.',
                  buttonText: 'Kelola Slot',
                  color: Colors.red.shade600,
                  onTap: () async {
                    final result = await Navigator.pushNamed(context, '/dosen/slot/list');
                    if (result == true) _refreshData();
                  },
                ),

              // List
              Expanded(
                child: slotDenganPendaftar.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.event_busy_rounded, size: 80, color: PermintaanColors.wheat),
                        SizedBox(height: 20),
                        Text('Belum ada pendaftar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: PermintaanColors.cacaoNibs)),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            belumAdaSlot 
                              ? 'Buat slot bimbingan terlebih dahulu agar mahasiswa dapat mendaftar'
                              : 'Mahasiswa belum ada yang mendaftar di slot bimbingan Anda',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: PermintaanColors.mochaMousse),
                          ),
                        ),
                      ]))
                    : ListView.builder(
                        padding: EdgeInsets.all(20),
                        itemCount: slotDenganPendaftar.length,
                        itemBuilder: (context, index) => _buildSlotCard(slotDenganPendaftar[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReminderCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: Colors.white.withOpacity(0.2),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          buttonText,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotCard(SlotModel slot) {
    final pendaftarList = slot.listPendaftar.map((nrp) {
      try { return _cachedMahasiswa.firstWhere((m) => m.nrp == nrp); } catch (e) { return null; }
    }).whereType<MahasiswaModel>().toList();

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: PermintaanColors.cacaoNibs.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [PermintaanColors.wheat, PermintaanColors.buttercream]), borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
            child: Row(children: [
              Icon(Icons.calendar_today_rounded, color: PermintaanColors.apricotBrandy, size: 24),
              SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_formatDate(slot.tanggalDateTime), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: PermintaanColors.cacaoNibs)),
                Text('${_formatTime(slot.jamMulaiDateTime)} - ${_formatTime(slot.jamSelesaiDateTime)}', style: TextStyle(fontSize: 13, color: PermintaanColors.mochaMousse)),
                Text(slot.lokasi, style: TextStyle(fontSize: 13, color: PermintaanColors.mochaMousse)),
              ])),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: PermintaanColors.apricotBrandy, borderRadius: BorderRadius.circular(20)),
                child: Text('${pendaftarList.length} Mhs', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mahasiswa Terdaftar:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PermintaanColors.cacaoNibs)),
              SizedBox(height: 12),
              ...pendaftarList.map((m) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _showMahasiswaDetail(m),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(color: PermintaanColors.buttercream.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      CircleAvatar(radius: 18, backgroundColor: PermintaanColors.apricotBrandy.withOpacity(0.2), child: Text(m.nama.isNotEmpty ? m.nama[0].toUpperCase() : '?', style: TextStyle(color: PermintaanColors.apricotBrandy, fontWeight: FontWeight.bold))),
                      SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m.nama, style: TextStyle(fontWeight: FontWeight.w600, color: PermintaanColors.cacaoNibs)), Text(m.nrp, style: TextStyle(fontSize: 12, color: PermintaanColors.mochaMousse))])),
                      Icon(Icons.chevron_right_rounded, color: PermintaanColors.mochaMousse, size: 20),
                    ]),
                  ),
                ),
              )).toList(),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/dosen/permintaan/tinjau', arguments: slot.id),
                  style: ElevatedButton.styleFrom(backgroundColor: PermintaanColors.spicedApple, padding: EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Lihat Detail Slot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
