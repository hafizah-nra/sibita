import 'package:flutter/material.dart';
import '../../../config/restapi.dart';
import '../../../config/manajer_session.dart';
import '../../../model/slot_model.dart';
import '../../../model/mahasiswa_model.dart';
import 'package:intl/intl.dart';

// Color Palette
class DetailSlotColors {
  static const Color buttercream = Color(0xFFEDE2D0);
  static const Color wheat = Color(0xFFE9D2A9);
  static const Color apricotBrandy = Color(0xFFBB6A57);
  static const Color mochaMousse = Color(0xFFA57865);
  static const Color cacaoNibs = Color(0xFF7B5747);
  static const Color spicedApple = Color(0xFF793937);
}

class TinjauPermintaan extends StatefulWidget {
  @override
  _TinjauPermintaanState createState() => _TinjauPermintaanState();
}

class _TinjauPermintaanState extends State<TinjauPermintaan> {
  // Cek apakah slot sudah lewat berdasarkan jam selesai
  bool _isSlotExpired(SlotModel slot) {
    final now = DateTime.now();
    final slotDate = slot.tanggalDateTime;
    final slotEndTime = DateTime(
      slotDate.year, slotDate.month, slotDate.day,
      slot.jamSelesaiDateTime.hour, slot.jamSelesaiDateTime.minute,
    );
    return now.isAfter(slotEndTime);
  }

  String _formatDate(DateTime date, {bool isExpired = false}) {
    if (isExpired) return 'Sudah Lewat';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final slotDate = DateTime(date.year, date.month, date.day);

    if (slotDate == today) {
      return 'Hari Ini';
    } else if (slotDate == tomorrow) {
      return 'Besok';
    } else {
      return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date);
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showMahasiswaDetail(MahasiswaModel mahasiswa) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DetailSlotColors.wheat,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),

            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: DetailSlotColors.apricotBrandy.withOpacity(0.2),
              child: Text(
                mahasiswa.nama.isNotEmpty
                    ? mahasiswa.nama[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: DetailSlotColors.apricotBrandy,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Nama
            Text(
              mahasiswa.nama,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DetailSlotColors.cacaoNibs,
              ),
            ),
            SizedBox(height: 4),
            Text(
              mahasiswa.nrp,
              style: TextStyle(
                fontSize: 14,
                color: DetailSlotColors.mochaMousse,
              ),
            ),
            SizedBox(height: 24),

            // Detail Info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DetailSlotColors.buttercream.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildBottomSheetItem(
                    Icons.email_rounded,
                    'Email',
                    mahasiswa.email,
                  ),
                  Divider(height: 24, color: DetailSlotColors.wheat),
                  _buildBottomSheetItem(
                    Icons.school_rounded,
                    'IPK',
                    mahasiswa.ipk,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DetailSlotColors.apricotBrandy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Tutup',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DetailSlotColors.apricotBrandy.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: DetailSlotColors.apricotBrandy),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: DetailSlotColors.mochaMousse,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: DetailSlotColors.cacaoNibs,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final slotId = ModalRoute.of(context)!.settings.arguments as String;
    final dosen = ManajerSession.instance.dosen;

    if (dosen == null) {
      return Scaffold(
        backgroundColor: DetailSlotColors.buttercream,
        appBar: AppBar(
          title: Text('Detail Slot'),
          backgroundColor: DetailSlotColors.spicedApple,
        ),
        body: Center(child: Text('Tidak ada dosen aktif')),
      );
    }

    // Gunakan FutureBuilder untuk menangani async
    return FutureBuilder<SlotModel?>(
      future: RestApi.instance.cariSlotById(slotId),
      builder: (context, slotSnapshot) {
        if (slotSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: DetailSlotColors.buttercream,
            appBar: AppBar(
              title: Text(
                'Detail Slot Bimbingan',
                style: TextStyle(color: DetailSlotColors.buttercream),
              ),
              backgroundColor: DetailSlotColors.spicedApple,
              iconTheme: IconThemeData(color: DetailSlotColors.buttercream),
            ),
            body: Center(
              child: CircularProgressIndicator(
                color: DetailSlotColors.apricotBrandy,
              ),
            ),
          );
        }

        final slot = slotSnapshot.data;

        if (slot == null) {
          return Scaffold(
            backgroundColor: DetailSlotColors.buttercream,
            appBar: AppBar(
              title: Text(
                'Detail Slot',
                style: TextStyle(color: DetailSlotColors.buttercream),
              ),
              backgroundColor: DetailSlotColors.spicedApple,
              iconTheme: IconThemeData(color: DetailSlotColors.buttercream),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 80,
                    color: DetailSlotColors.wheat,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Slot tidak ditemukan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DetailSlotColors.cacaoNibs,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // FutureBuilder kedua untuk mengambil data mahasiswa
        return FutureBuilder<List<MahasiswaModel>>(
          future: RestApi.instance.semuaMahasiswa(),
          builder: (context, mahasiswaSnapshot) {
            if (mahasiswaSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: DetailSlotColors.buttercream,
                appBar: AppBar(
                  title: Text(
                    'Detail Slot Bimbingan',
                    style: TextStyle(color: DetailSlotColors.buttercream),
                  ),
                  backgroundColor: DetailSlotColors.spicedApple,
                  iconTheme: IconThemeData(color: DetailSlotColors.buttercream),
                ),
                body: Center(
                  child: CircularProgressIndicator(
                    color: DetailSlotColors.apricotBrandy,
                  ),
                ),
              );
            }

            final semuaMahasiswa = mahasiswaSnapshot.data ?? [];
            final pendaftarList = slot.listPendaftar
                .map((nrp) {
                  try {
                    return semuaMahasiswa.firstWhere((m) => m.nrp == nrp);
                  } catch (e) {
                    return null;
                  }
                })
                .whereType<MahasiswaModel>()
                .toList();

            final isExpired = _isSlotExpired(slot);
            final isUnlimited = slot.isUnlimited;
            final capacityPercentage = (!isUnlimited && slot.kapasitasInt > 0)
                ? (slot.listPendaftar.length / slot.kapasitasInt * 100).round()
                : 0;

            return Scaffold(
              backgroundColor: DetailSlotColors.buttercream,
              appBar: AppBar(
                title: Text(
                  'Detail Slot Bimbingan',
                  style: TextStyle(
                    color: DetailSlotColors.buttercream,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: DetailSlotColors.spicedApple,
                elevation: 0,
                iconTheme: IconThemeData(color: DetailSlotColors.buttercream),
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Gradient
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DetailSlotColors.spicedApple,
                            DetailSlotColors.apricotBrandy,
                            DetailSlotColors.mochaMousse,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.event_available_rounded,
                              size: 48,
                              color: DetailSlotColors.buttercream,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            _formatDate(slot.tanggalDateTime, isExpired: isExpired),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isExpired ? Colors.white70 : DetailSlotColors.buttercream,
                            ),
                          ),
                          if (isExpired) ...[
                            SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy', 'id_ID').format(slot.tanggalDateTime),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_formatTime(slot.jamMulaiDateTime)} - ${_formatTime(slot.jamSelesaiDateTime)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: DetailSlotColors.buttercream,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Detail Slot Card
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: DetailSlotColors.cacaoNibs.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Informasi Slot',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: DetailSlotColors.cacaoNibs,
                                  ),
                                ),
                                SizedBox(height: 16),
                                _buildInfoRow(
                                  Icons.location_on_rounded,
                                  'Lokasi',
                                  slot.lokasi,
                                ),
                                Divider(height: 24, color: DetailSlotColors.wheat),
                                _buildInfoRow(
                                  Icons.people_rounded,
                                  'Kapasitas',
                                  isUnlimited 
                                      ? '${slot.listPendaftar.length} terdaftar (Tak Terbatas)' 
                                      : '${slot.listPendaftar.length}/${slot.kapasitas} terdaftar',
                                ),
                                SizedBox(height: 12),
                                // Progress Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: isUnlimited 
                                        ? 1.0 
                                        : (slot.kapasitasInt > 0
                                            ? slot.listPendaftar.length / slot.kapasitasInt
                                            : 0),
                                    backgroundColor: DetailSlotColors.wheat,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isExpired
                                          ? Colors.grey
                                          : isUnlimited
                                              ? Colors.green.withOpacity(0.5)
                                              : slot.isFull
                                                  ? DetailSlotColors.spicedApple
                                                  : capacityPercentage >= 80
                                                      ? DetailSlotColors.apricotBrandy
                                                      : Colors.green,
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isExpired
                                            ? Colors.grey
                                            : isUnlimited
                                                ? Colors.green
                                                : slot.isFull
                                                    ? DetailSlotColors.spicedApple
                                                    : capacityPercentage >= 80
                                                        ? DetailSlotColors.apricotBrandy
                                                        : Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isUnlimited && !isExpired) ...[
                                            Icon(Icons.all_inclusive, size: 12, color: Colors.white),
                                            SizedBox(width: 4),
                                          ],
                                          Text(
                                            isExpired
                                                ? 'Lewat'
                                                : isUnlimited
                                                    ? 'Tak Terbatas'
                                                    : slot.isFull
                                                        ? 'Penuh'
                                                        : capacityPercentage >= 80
                                                            ? 'Hampir Penuh'
                                                            : 'Tersedia',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (slot.tipeSlot == TipeSlot.tetap) ...[
                                  Divider(height: 24, color: DetailSlotColors.wheat),
                                  _buildInfoRow(
                                    Icons.repeat_rounded,
                                    'Tipe Slot',
                                    'Slot Rutin',
                                  ),
                                ],
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                          // Daftar Mahasiswa Terdaftar
                          Text(
                            'Mahasiswa Terdaftar (${pendaftarList.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: DetailSlotColors.cacaoNibs,
                            ),
                          ),
                          SizedBox(height: 16),

                          if (pendaftarList.isEmpty)
                            Container(
                              padding: EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.person_off_rounded,
                                      size: 48,
                                      color: DetailSlotColors.wheat,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Belum ada mahasiswa terdaftar',
                                      style: TextStyle(
                                        color: DetailSlotColors.mochaMousse,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...pendaftarList.asMap().entries.map((entry) {
                              final index = entry.key;
                              final mahasiswa = entry.value;
                              return _buildMahasiswaCard(mahasiswa, index + 1);
                            }).toList(),

                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DetailSlotColors.wheat.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: DetailSlotColors.apricotBrandy),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: DetailSlotColors.mochaMousse,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: DetailSlotColors.cacaoNibs,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMahasiswaCard(MahasiswaModel mahasiswa, int number) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DetailSlotColors.cacaoNibs.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showMahasiswaDetail(mahasiswa),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Number Badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: DetailSlotColors.apricotBrandy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: DetailSlotColors.apricotBrandy.withOpacity(
                    0.15,
                  ),
                  child: Text(
                    mahasiswa.nama.isNotEmpty
                        ? mahasiswa.nama[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: DetailSlotColors.apricotBrandy,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: DetailSlotColors.cacaoNibs,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        mahasiswa.nrp,
                        style: TextStyle(
                          fontSize: 13,
                          color: DetailSlotColors.mochaMousse,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DetailSlotColors.buttercream,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: DetailSlotColors.apricotBrandy,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
