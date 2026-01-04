import 'package:flutter/material.dart';
import 'dart:convert';
import '../../config/manajer_session.dart';
import '../../config/restapi.dart';
import '../../model/mahasiswa_model.dart';
import '../../model/permintaan_model.dart';
import '../../model/dosen_model.dart';
import '../../model/slot_model.dart';
import 'package:intl/intl.dart';

class DashboardMahasiswa extends StatefulWidget {
  const DashboardMahasiswa({super.key});

  @override
  _DashboardMahasiswaState createState() => _DashboardMahasiswaState();
}

class _DashboardMahasiswaState extends State<DashboardMahasiswa> {
  late final session = ManajerSession.instance;
  late Future<Map<String, dynamic>> _dataFuture;
  List<DosenModel> _cachedDosen = [];
  bool _isInitialized = false;
  bool _isLoadingMahasiswa = true;
  bool _isLoggingOut =
      false; // Flag untuk mencegah double navigation saat logout

  @override
  void initState() {
    super.initState();
    // Inisialisasi dengan Future kosong dulu, data akan di-load di didChangeDependencies
    _dataFuture = Future.value({});
    // Listen perubahan session (foto profil, dll)
    session.addListener(_onSessionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _initializeData();
    }
  }

  /// Inisialisasi data: ambil dari arguments atau session, fetch ulang jika perlu
  Future<void> _initializeData() async {
    // Coba ambil data mahasiswa dari arguments (dikirim dari halaman login)
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null && args is MahasiswaModel) {
      // Data ada di arguments, gunakan langsung
      // Session sudah di-set di halaman login, jadi tidak perlu set lagi
      if (session.mahasiswa == null) {
        session.loginMahasiswa(args);
      }
    }

    // Jika session masih null, redirect ke login
    if (session.mahasiswa == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    // Data mahasiswa sudah ready, load data dashboard
    setState(() {
      _isLoadingMahasiswa = false;
    });
    _loadData();
  }

  @override
  void dispose() {
    session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    // Jika sedang proses logout dari halaman ini, abaikan
    if (_isLoggingOut) return;

    // Jika sedang proses navigasi (login dari halaman lain), abaikan
    if (session.isNavigating) return;

    // Jika session di-logout dari tempat lain, redirect ke login
    if (session.mahasiswa == null && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    // Refresh UI ketika data session berubah (misal: foto profil diupdate)
    if (mounted) {
      setState(() {});
    }
  }

  void _loadData() {
    // Pastikan session mahasiswa tidak null
    if (session.mahasiswa == null) return;

    final nrp = session.mahasiswa!.nrp;
    _dataFuture = _fetchDashboardData(nrp);
  }

  Future<Map<String, dynamic>> _fetchDashboardData(String nrp) async {
    final permintaan = await RestApi.instance.daftarPermintaanUntukMahasiswa(
      nrp,
    );
    final semuaSlot = await RestApi.instance.semuaSlot();
    final semuaDosen = await RestApi.instance.semuaDosen();
    final daftarBimbingan = await RestApi.instance.getBimbinganMahasiswa(nrp);
    _cachedDosen = semuaDosen;

    final slotBimbingan =
        semuaSlot.where((slot) => slot.listPendaftar.contains(nrp)).toList()
          ..sort((a, b) => b.tanggalDateTime.compareTo(a.tanggalDateTime));

    // Waktu sekarang
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // === Hitung minggu berjalan (Senin - Minggu) ===
    // Cari hari Senin dari minggu ini
    final int weekday = now.weekday; // 1 = Senin, 7 = Minggu
    final DateTime senin = today.subtract(Duration(days: weekday - 1));
    final DateTime minggu = senin.add(Duration(days: 6));

    // Hitung bimbingan yang sudah selesai berdasarkan catatan dosen
    // Bimbingan dianggap selesai jika dosen sudah mengisi catatan (catatanBimbingan tidak kosong)
    final bimbinganSelesai = daftarBimbingan.where((bimbingan) {
      return bimbingan.catatanBimbingan.isNotEmpty;
    }).toList();

    // Cek apakah mahasiswa sudah mengajukan Judul TA
    final bool sudahMengajukan = permintaan.isNotEmpty;

    // === Cari dosen pembimbing ===
    PermintaanModel? pembimbing;
    try {
      pembimbing = permintaan.firstWhere(
        (p) => p.pembimbingNip != null && p.pembimbingNip!.isNotEmpty,
      );
    } catch (e) {
      pembimbing = null;
    }

    String statusPembimbing = 'Belum mengajukan';
    String namaPembimbing = '';
    String? nipPembimbing;

    if (sudahMengajukan) {
      if (pembimbing != null &&
          pembimbing.pembimbingNip != null &&
          pembimbing.pembimbingNip!.isNotEmpty) {
        nipPembimbing = pembimbing.pembimbingNip;
        try {
          final d = semuaDosen.firstWhere(
            (x) => x.nip == pembimbing!.pembimbingNip,
          );
          statusPembimbing = 'Pembimbing: ${d.nama}';
          namaPembimbing = d.nama;
        } catch (e) {
          statusPembimbing = 'Menunggu respon dosen';
        }
      } else {
        statusPembimbing = 'Menunggu respon dosen';
      }
    }

    // === Logika notifikasi "Segera daftar bimbingan" ===
    // Notifikasi muncul jika:
    // 1. Mahasiswa belum mendaftar ke slot apapun di minggu berjalan (Senin-Minggu)
    // 2. DAN Dosen pembimbing memiliki slot aktif di minggu berjalan
    
    bool tampilkanNotifikasi = false;

    if (nipPembimbing != null && nipPembimbing.isNotEmpty) {
      // Helper: Cek apakah tanggal berada di minggu berjalan
      bool isInCurrentWeek(DateTime tanggal) {
        final tanggalOnly = DateTime(tanggal.year, tanggal.month, tanggal.day);
        return !tanggalOnly.isBefore(senin) && !tanggalOnly.isAfter(minggu);
      }

      // Helper: Cek apakah slot masih aktif (belum lewat)
      bool isSlotAktif(slot) {
        final tanggalSlot = DateTime(
          slot.tanggalDateTime.year,
          slot.tanggalDateTime.month,
          slot.tanggalDateTime.day,
        );
        final isToday = tanggalSlot.isAtSameMomentAs(today);

        if (isToday) {
          // Jika hari ini, cek apakah jam selesai belum lewat
          return now.isBefore(slot.jamSelesaiDateTime);
        }
        // Slot di masa depan
        return tanggalSlot.isAfter(today);
      }

      // 1. Cek apakah mahasiswa sudah mendaftar ke slot di minggu berjalan
      final slotMingguIniYangDidaftari = slotBimbingan.where((slot) {
        return isInCurrentWeek(slot.tanggalDateTime);
      }).toList();

      final bool sudahDaftarMingguIni = slotMingguIniYangDidaftari.isNotEmpty;

      // 2. Cek apakah dosen pembimbing punya slot aktif di minggu berjalan
      final slotDosenMingguIni = semuaSlot.where((slot) {
        return slot.nip == nipPembimbing &&
            isInCurrentWeek(slot.tanggalDateTime) &&
            isSlotAktif(slot);
      }).toList();

      final bool dosenPunyaSlotAktif = slotDosenMingguIni.isNotEmpty;

      // Notifikasi muncul jika belum daftar DAN dosen punya slot aktif
      tampilkanNotifikasi = !sudahDaftarMingguIni && dosenPunyaSlotAktif;
    }
    // Jika belum punya pembimbing (nipPembimbing null), notifikasi tidak muncul

    return {
      'slotBimbingan': slotBimbingan,
      'totalBimbinganSelesai': bimbinganSelesai.length,
      'tampilkanNotifikasi': tampilkanNotifikasi,
      'statusPembimbing': statusPembimbing,
      'namaPembimbing': namaPembimbing,
      'sudahMengajukan': sudahMengajukan,
      'daftarBimbingan': daftarBimbingan,
    };
  }

  void _refreshData() {
    setState(() => _loadData());
  }

  /// Widget untuk menampilkan foto profil di header
  Widget _buildProfileAvatar() {
    final fotoProfil = session.mahasiswa?.fotoProfil ?? '';

    // Cek apakah ada foto profil yang tersimpan (base64)
    if (fotoProfil.isNotEmpty && fotoProfil != '-') {
      try {
        final bytes = base64Decode(fotoProfil);
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: 56,
              height: 56,
              errorBuilder: (context, error, stackTrace) =>
                  _buildDefaultAvatar(),
            ),
          ),
        );
      } catch (e) {
        // Jika gagal decode base64, tampilkan default
        return _buildDefaultAvatar();
      }
    }

    // Default placeholder jika tidak ada foto
    return _buildDefaultAvatar();
  }

  /// Widget default avatar (Icons.person)
  Widget _buildDefaultAvatar() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.person, color: Colors.white, size: 32),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading jika data mahasiswa belum ready
    if (_isLoadingMahasiswa || session.mahasiswa == null) {
      return Scaffold(
        backgroundColor: Color(0xFFEDE2D0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFBB6A57)),
              SizedBox(height: 16),
              Text(
                'Memuat data mahasiswa...',
                style: TextStyle(color: Color(0xFFA57865)),
              ),
            ],
          ),
        ),
      );
    }

    final nrp = session.mahasiswa!.nrp;
    final nama = session.mahasiswa!.nama;

    return Scaffold(
      backgroundColor: Color(0xFFEDE2D0),
      appBar: AppBar(
        title: Text('Dashboard'),
        elevation: 0,
        backgroundColor: Color(0xFFBB6A57),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.pushNamed(context, '/mahasiswa/profil');
              } else if (value == 'logout') {
                // Set flag untuk mencegah listener redirect
                _isLoggingOut = true;
                session.startNavigation();

                // Logout dulu, baru navigasi
                session.logout();

                // Navigasi ke login dengan clear stack
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );

                // End navigation setelah navigasi selesai
                Future.delayed(Duration(milliseconds: 100), () {
                  session.endNavigation();
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Color(0xFF793937)),
                    SizedBox(width: 8),
                    Text('Profil'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFF793937)),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFBB6A57)),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data...',
                    style: TextStyle(color: Color(0xFFA57865)),
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
                  Icon(Icons.error_outline, size: 64, color: Color(0xFF793937)),
                  SizedBox(height: 16),
                  Text(
                    'Gagal memuat data',
                    style: TextStyle(
                      color: Color(0xFF793937),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Periksa koneksi internet Anda',
                    style: TextStyle(color: Color(0xFFA57865)),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFBB6A57),
                    ),
                    child: Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final List<SlotModel> slotBimbingan = data['slotBimbingan'];
          final int totalBimbinganSelesai = data['totalBimbinganSelesai'];
          final bool tampilkanNotifikasi = data['tampilkanNotifikasi'] ?? false;
          final String statusPembimbing = data['statusPembimbing'];
          final String namaPembimbing = data['namaPembimbing'];
          final bool sudahMengajukan = data['sudahMengajukan'];

          return _buildContent(
            nama,
            nrp,
            slotBimbingan,
            totalBimbinganSelesai,
            tampilkanNotifikasi,
            statusPembimbing,
            namaPembimbing,
            sudahMengajukan,
          );
        },
      ),
    );
  }

  Widget _buildContent(
    String nama,
    String nrp,
    List<SlotModel> slotBimbingan,
    int totalBimbinganSelesai,
    bool tampilkanNotifikasi,
    String statusPembimbing,
    String namaPembimbing,
    bool sudahMengajukan,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFBB6A57), Color(0xFFA57865)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                _buildProfileAvatar(),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang!',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        nama,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'NRP: $nrp',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          if (tampilkanNotifikasi) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () =>
                    Navigator.pushNamed(context, '/mahasiswa/slot/list'),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Segera daftar bimbingan! 🎓',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],

          // Status Pembimbing
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Pembimbing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF793937),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: namaPembimbing.isNotEmpty
                        ? Colors.green.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: namaPembimbing.isNotEmpty
                          ? Colors.green
                          : Color(0xFFE9D2A9),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: namaPembimbing.isNotEmpty
                              ? Colors.green
                              : Color(0xFFE9D2A9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          namaPembimbing.isNotEmpty
                              ? Icons.check_circle
                              : Icons.schedule,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statusPembimbing,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B5747),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Statistik
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFBB6A57), Color(0xFFA57865)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_note, color: Colors.white, size: 32),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Bimbingan Selesai',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '$totalBimbinganSelesai sesi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Action Buttons - Dinamis berdasarkan status pengajuan
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildActionButtons(sudahMengajukan),
          ),

          SizedBox(height: 24),

          // Menu Riwayat Bimbingan
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menu Lainnya',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF793937),
                  ),
                ),
                SizedBox(height: 12),
                _buildMenuCard(
                  icon: Icons.history,
                  title: 'Riwayat Bimbingan',
                  subtitle: 'Lihat semua pengajuan bimbingan Anda',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/mahasiswa/bimbingan/riwayat',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Widget untuk menampilkan tombol aksi berdasarkan status pengajuan
  Widget _buildActionButtons(bool sudahMengajukan) {
    // Jika belum mengajukan, tampilkan tombol Ajukan dan Slot
    if (!sudahMengajukan) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/mahasiswa/permintaan/form',
                );
                if (result == true) _refreshData();
              },
              icon: Icon(Icons.add_circle),
              label: Text('Ajukan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFBB6A57),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/mahasiswa/slot/list'),
              icon: Icon(Icons.calendar_today),
              label: Text('Slot'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFFBB6A57),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Color(0xFFBB6A57), width: 2),
              ),
            ),
          ),
        ],
      );
    }

    // Jika sudah mengajukan, hanya tampilkan tombol Slot (full width)
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/mahasiswa/slot/list'),
        icon: Icon(Icons.calendar_today),
        label: Text('Lihat Slot Bimbingan'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFBB6A57),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildKartuBimbingan(SlotModel slot) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tanggalSlot = slot.tanggalDateTime;
    final tanggalSlotOnly = DateTime(
      tanggalSlot.year,
      tanggalSlot.month,
      tanggalSlot.day,
    );

    // Bandingkan hanya tanggal (tanpa waktu)
    final isPast = tanggalSlotOnly.isBefore(today);
    final isToday = tanggalSlotOnly.isAtSameMomentAs(today);

    // Cek apakah jam selesai sudah lewat (untuk hari ini)
    final isTodayFinished =
        isToday &&
        (now.isAfter(slot.jamSelesaiDateTime) ||
            now.isAtSameMomentAs(slot.jamSelesaiDateTime));

    DosenModel? dosen;
    try {
      dosen = _cachedDosen.firstWhere((d) => d.nip == slot.nip);
    } catch (e) {}

    Color statusColor;
    String statusText;

    if (isPast || isTodayFinished) {
      statusColor = Colors.grey;
      statusText = 'Selesai';
    } else if (isToday) {
      statusColor = Colors.orange;
      statusText = 'Hari Ini';
    } else {
      statusColor = Colors.blue;
      statusText = 'Akan Datang';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, color: statusColor, size: 12),
                SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dosen != null)
                  Text(
                    dosen.nama,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF793937),
                    ),
                  ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFFA57865),
                    ),
                    SizedBox(width: 8),
                    Text(DateFormat('dd MMM yyyy').format(tanggalSlot)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Color(0xFFA57865)),
                    SizedBox(width: 8),
                    Text(
                      '${DateFormat('HH:mm').format(slot.jamMulaiDateTime)} - ${DateFormat('HH:mm').format(slot.jamSelesaiDateTime)}',
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Color(0xFFA57865)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(slot.lokasi, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF7B5747).withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFE9D2A9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Color(0xFFBB6A57), size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF793937),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Color(0xFFA57865)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Color(0xFFA57865), size: 16),
          ],
        ),
      ),
    );
  }
}
