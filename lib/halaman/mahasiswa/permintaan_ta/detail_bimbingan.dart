import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/restapi.dart';
import '../../../model/slot_model.dart';
import '../../../model/dosen_model.dart';

// Color Palette
class DetailColors {
  static const Color buttercream = Color(0xFFEDE2D0);
  static const Color wheat = Color(0xFFE9D2A9);
  static const Color apricotBrandy = Color(0xFFBB6A57);
  static const Color mochaMousse = Color(0xFFA57865);
  static const Color cacaoNibs = Color(0xFF7B5747);
  static const Color spicedApple = Color(0xFF793937);
}

class DetailBimbingan extends StatefulWidget {
  @override
  State<DetailBimbingan> createState() => _DetailBimbinganState();
}

class _DetailBimbinganState extends State<DetailBimbingan> {
  SlotModel? slot;
  DosenModel? dosen;
  bool isLoading = true;
  String? errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    final slotId = ModalRoute.of(context)!.settings.arguments as String;
    
    try {
      final loadedSlot = await RestApi.instance.cariSlotById(slotId);
      if (loadedSlot != null) {
        final dosenList = await RestApi.instance.semuaDosen();
        final loadedDosen = dosenList.cast<DosenModel?>().firstWhere(
          (d) => d?.nip == loadedSlot.nip,
          orElse: () => null,
        );
        setState(() {
          slot = loadedSlot;
          dosen = loadedDosen;
          isLoading = false;
        });
      } else {
        setState(() {
          slot = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Color _getStatusColor(DateTime tanggal) {
    final now = DateTime.now();
    final isPast = tanggal.isBefore(now);
    final isToday = tanggal.year == now.year &&
        tanggal.month == now.month &&
        tanggal.day == now.day;

    if (isPast) {
      return Colors.grey;
    } else if (isToday) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  IconData _getStatusIcon(DateTime tanggal) {
    final now = DateTime.now();
    final isPast = tanggal.isBefore(now);
    final isToday = tanggal.year == now.year &&
        tanggal.month == now.month &&
        tanggal.day == now.day;

    if (isPast) {
      return Icons.check_circle_rounded;
    } else if (isToday) {
      return Icons.today_rounded;
    } else {
      return Icons.schedule_rounded;
    }
  }

  String _getStatusText(DateTime tanggal) {
    final now = DateTime.now();
    final isPast = tanggal.isBefore(now);
    final isToday = tanggal.year == now.year &&
        tanggal.month == now.month &&
        tanggal.day == now.day;

    if (isPast) {
      return 'Selesai';
    } else if (isToday) {
      return 'Hari Ini';
    } else {
      return 'Akan Datang';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: DetailColors.buttercream,
        appBar: AppBar(
          title: Text('Detail Bimbingan'),
          backgroundColor: DetailColors.spicedApple,
          foregroundColor: DetailColors.buttercream,
          elevation: 0,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (slot == null) {
      return Scaffold(
        backgroundColor: DetailColors.buttercream,
        appBar: AppBar(
          title: Text('Detail Bimbingan'),
          backgroundColor: DetailColors.spicedApple,
          foregroundColor: DetailColors.buttercream,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: DetailColors.apricotBrandy,
              ),
              SizedBox(height: 16),
              Text(
                'Bimbingan Tidak Ditemukan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: DetailColors.cacaoNibs,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final statusColor = _getStatusColor(slot!.tanggalDateTime);
    final statusIcon = _getStatusIcon(slot!.tanggalDateTime);
    final statusText = _getStatusText(slot!.tanggalDateTime);

    return Scaffold(
      backgroundColor: DetailColors.buttercream,
      appBar: AppBar(
        title: Text(
          'Detail Bimbingan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: DetailColors.spicedApple,
        foregroundColor: DetailColors.buttercream,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            // Status Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DetailColors.spicedApple,
                    DetailColors.apricotBrandy,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: DetailColors.spicedApple.withOpacity(0.3),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Status: $statusText',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (slot!.tipeSlot == TipeSlot.tetap) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.repeat_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Slot Rutin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dosen Pembimbing Card
                  if (dosen != null)
                    _buildInfoCard(
                      icon: Icons.person_rounded,
                      iconColor: DetailColors.apricotBrandy,
                      title: 'Dosen Pembimbing',
                      content: dosen!.nama,
                      subtitle: 'NIP: ${dosen!.nip}',
                      highlighted: true,
                    ),
                  if (dosen != null) SizedBox(height: 14),

                  // Tanggal Card
                  _buildInfoCard(
                    icon: Icons.calendar_today_rounded,
                    iconColor: DetailColors.mochaMousse,
                    title: 'Tanggal Bimbingan',
                    content: DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                        .format(slot!.tanggalDateTime),
                  ),
                  SizedBox(height: 14),

                  // Info Grid - Waktu dan Lokasi
                  Row(
                    children: [
                      Expanded(
                        child: _buildSmallInfoCard(
                          icon: Icons.access_time_rounded,
                          iconColor: DetailColors.cacaoNibs,
                          label: 'Waktu',
                          value:
                              '${DateFormat('HH:mm').format(slot!.jamMulaiDateTime)} - ${DateFormat('HH:mm').format(slot!.jamSelesaiDateTime)}',
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: _buildSmallInfoCard(
                          icon: Icons.people_rounded,
                          iconColor: DetailColors.wheat,
                          label: 'Peserta',
                          value: '${slot!.listPendaftar.length}/${slot!.kapasitas}',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),

                  // Lokasi Card
                  _buildInfoCard(
                    icon: Icons.location_on_rounded,
                    iconColor: Color(0xFF4CAF50),
                    title: 'Lokasi',
                    content: slot!.lokasi,
                  ),
                  SizedBox(height: 14),

                  // Durasi Card
                  _buildDurasiCard(slot!),

                  // Additional Info
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DetailColors.wheat.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: DetailColors.wheat,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: DetailColors.cacaoNibs,
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            slot!.tanggalDateTime.isAfter(DateTime.now())
                                ? 'Pastikan datang tepat waktu untuk sesi bimbingan'
                                : 'Sesi bimbingan ini telah selesai',
                            style: TextStyle(
                              fontSize: 13,
                              color: DetailColors.cacaoNibs,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    String? subtitle,
    bool highlighted = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted
            ? iconColor.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highlighted
            ? Border.all(color: iconColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: (highlighted ? iconColor : DetailColors.cacaoNibs)
                .withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DetailColors.cacaoNibs.withOpacity(0.7),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DetailColors.cacaoNibs,
              height: 1.4,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: DetailColors.cacaoNibs.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DetailColors.cacaoNibs.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DetailColors.cacaoNibs.withOpacity(0.7),
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DetailColors.cacaoNibs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurasiCard(SlotModel slot) {
    final durasi = slot.jamSelesaiDateTime.difference(slot.jamMulaiDateTime);
    final jam = durasi.inHours;
    final menit = durasi.inMinutes % 60;
    
    String durasiText = '';
    if (jam > 0) {
      durasiText = '$jam jam';
      if (menit > 0) {
        durasiText += ' $menit menit';
      }
    } else {
      durasiText = '$menit menit';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DetailColors.apricotBrandy.withOpacity(0.1),
            DetailColors.mochaMousse.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DetailColors.apricotBrandy.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DetailColors.apricotBrandy.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.timer_rounded,
              color: DetailColors.apricotBrandy,
              size: 22,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Durasi Bimbingan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DetailColors.cacaoNibs.withOpacity(0.7),
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  durasiText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DetailColors.cacaoNibs,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}