import 'package:flutter/material.dart';
import 'package:sibita/halaman/dosen/profil_dosen.dart';
import '../../config/manajer_session.dart';
import '../../config/restapi.dart';
import '../../model/dosen_model.dart';
import '../../model/mahasiswa_model.dart';
import '../../model/bimbingan_model.dart';

class DashboardColors {
  static const Color buttercream = Color(0xFFEDE2D0);
  static const Color wheat = Color(0xFFE9D2A9);
  static const Color apricotBrandy = Color(0xFFBB6A57);
  static const Color mochaMousse = Color(0xFFA57865);
  static const Color cacaoNibs = Color(0xFF7B5747);
  static const Color spicedApple = Color(0xFF793937);
}

class DashboardDosen extends StatefulWidget {
  const DashboardDosen({super.key});

  @override
  _DashboardDosenState createState() => _DashboardDosenState();
}

class _DashboardDosenState extends State<DashboardDosen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Future<Map<String, dynamic>> _dataFuture;
  bool _isInitialized = false;
  bool _isLoadingDosen = true;
  bool _isLoggingOut =
      false; 
  final session = ManajerSession.instance;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    // Inisialisasi dengan Future kosong dulu, data akan di-load di didChangeDependencies
    _dataFuture = Future.value({});
    // Listen perubahan session
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
    // Coba ambil data dosen dari arguments (dikirim dari halaman login)
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null && args is DosenModel) {
      // Data ada di arguments, gunakan langsung
      // Session sudah di-set di halaman login, jadi tidak perlu set lagi
      if (session.dosen == null) {
        session.loginDosen(args);
      }
    }

    // Jika session masih null, redirect ke login
    if (session.dosen == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    // Data dosen sudah ready, load data dashboard
    setState(() {
      _isLoadingDosen = false;
    });
    _loadData();
  }

  void _onSessionChanged() {
    // Jika sedang proses logout dari halaman ini, abaikan
    if (_isLoggingOut) return;

    // Jika sedang proses navigasi (login dari halaman lain), abaikan
    if (session.isNavigating) return;

    // Jika session di-logout dari tempat lain, redirect ke login
    if (session.dosen == null && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    // Refresh UI ketika data session berubah
    if (mounted) {
      setState(() {});
    }
  }

  void _loadData() {
    // Pastikan session dosen tidak null
    if (session.dosen == null) return;

    final nip = session.dosen!.nip;
    _dataFuture = _fetchDashboardData(nip);
  }

  Future<Map<String, dynamic>> _fetchDashboardData(String nip) async {
    final semuaSlot = await RestApi.instance.semuaSlotUntukDosen(nip);
    final mahasiswaBimbingan = await RestApi.instance.getMahasiswaBimbingan(
      nip,
    );
    final bimbinganDosen = await RestApi.instance.getBimbinganDosen(nip);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter: slot yang AKTIF (hari ini atau akan datang)
    final slotAktif = semuaSlot.where((slot) {
      final slotDate = DateTime(
        slot.tanggalDateTime.year,
        slot.tanggalDateTime.month,
        slot.tanggalDateTime.day,
      );
      // Slot aktif = tanggal slot >= hari ini
      return !slotDate.isBefore(today);
    }).toList();

    // Filter: slot aktif yang memiliki pendaftar
    final slotDenganPendaftar = slotAktif.where((slot) {
      return slot.listPendaftar.isNotEmpty;
    }).toList();

    // Hitung total mahasiswa yang mendaftar di slot aktif
    final totalPendaftar = slotDenganPendaftar.fold<int>(
      0,
      (sum, slot) => sum + slot.listPendaftar.length,
    );

    // Hitung jumlah bimbingan yang perlu ditindak (status: pending)
    final bimbinganPerluDitindak = bimbinganDosen
        .where((b) => b.status.toLowerCase() == 'pending')
        .length;

    // Tentukan apakah perlu tampilkan notifikasi buat slot
    // Tampilkan jika: tidak ada slot sama sekali ATAU tidak ada slot aktif (semua sudah lewat)
    final bool belumAdaSlot = semuaSlot.isEmpty;
    final bool tidakAdaSlotAktif = slotAktif.isEmpty;
    final bool perluBuatSlot = belumAdaSlot || tidakAdaSlotAktif;

    // Pesan notifikasi berbeda berdasarkan kondisi
    String pesanNotifikasi = '';
    if (belumAdaSlot) {
      pesanNotifikasi = 'Anda belum membuat jadwal slot bimbingan';
    } else if (tidakAdaSlotAktif) {
      pesanNotifikasi =
          'Semua slot sudah lewat, buat slot baru untuk bimbingan';
    }

    return {
      'semuaSlot': semuaSlot,
      'slotAktif': slotAktif,
      'mahasiswaBimbingan': mahasiswaBimbingan,
      'totalPendaftar': totalPendaftar,
      'jumlahSlotAktif': slotAktif.length,
      'perluBuatSlot': perluBuatSlot,
      'pesanNotifikasi': pesanNotifikasi,
      'bimbinganPerluDitindak': bimbinganPerluDitindak,
    };
  }

  @override
  void dispose() {
    session.removeListener(_onSessionChanged);
    _animationController.dispose();
    super.dispose();
  }

  // Method untuk refresh data
  void _refreshData() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading jika data dosen belum ready
    if (_isLoadingDosen || session.dosen == null) {
      return Scaffold(
        backgroundColor: DashboardColors.buttercream,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: DashboardColors.apricotBrandy),
              SizedBox(height: 16),
              Text(
                'Memuat data dosen...',
                style: TextStyle(
                  color: DashboardColors.mochaMousse,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final d = session.dosen!;

    return Scaffold(
      backgroundColor: DashboardColors.buttercream,
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: DashboardColors.buttercream,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: DashboardColors.spicedApple,
        elevation: 0,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: DashboardColors.buttercream),
            color: DashboardColors.buttercream,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilDosenPage(dosen: d)),
                );
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
                    Icon(
                      Icons.person,
                      color: DashboardColors.apricotBrandy,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Profil',
                      style: TextStyle(
                        color: DashboardColors.cacaoNibs,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: DashboardColors.spicedApple,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: DashboardColors.cacaoNibs,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: DashboardColors.apricotBrandy,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data...',
                    style: TextStyle(
                      color: DashboardColors.mochaMousse,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: DashboardColors.spicedApple,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Gagal memuat data',
                    style: TextStyle(
                      color: DashboardColors.spicedApple,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Periksa koneksi internet Anda',
                    style: TextStyle(
                      color: DashboardColors.mochaMousse,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DashboardColors.apricotBrandy,
                    ),
                    child: Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          // Success state - handle null data safely
          final data = snapshot.data ?? {};

          // Jika data kosong, tampilkan loading (data belum di-fetch)
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: DashboardColors.apricotBrandy,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data...',
                    style: TextStyle(
                      color: DashboardColors.mochaMousse,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          // Safe cast dengan default values
          final List<MahasiswaModel> mahasiswaBimbingan =
              (data['mahasiswaBimbingan'] as List<MahasiswaModel>?) ?? [];
          final int totalPendaftar = (data['totalPendaftar'] as int?) ?? 0;
          final bool perluBuatSlot = (data['perluBuatSlot'] as bool?) ?? false;
          final String pesanNotifikasi =
              (data['pesanNotifikasi'] as String?) ?? '';
          final int jumlahMahasiswa = mahasiswaBimbingan.length;
          final int bimbinganPerluDitindak =
              (data['bimbinganPerluDitindak'] as int?) ?? 0;

          return _buildDashboardContent(
            d: d,
            jumlahMahasiswa: jumlahMahasiswa,
            totalPendaftar: totalPendaftar,
            perluBuatSlot: perluBuatSlot,
            pesanNotifikasi: pesanNotifikasi,
            bimbinganPerluDitindak: bimbinganPerluDitindak,
          );
        },
      ),
    );
  }

  Widget _buildDashboardContent({
    required dynamic d,
    required int jumlahMahasiswa,
    required int totalPendaftar,
    required bool perluBuatSlot,
    required String pesanNotifikasi,
    required int bimbinganPerluDitindak,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section with Gradient
            Container(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DashboardColors.spicedApple,
                    DashboardColors.apricotBrandy,
                    DashboardColors.mochaMousse,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: DashboardColors.spicedApple.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat datang!',
                    style: TextStyle(
                      color: DashboardColors.buttercream.withOpacity(0.85),
                      fontSize: 15,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    d.nama,
                    style: TextStyle(
                      color: DashboardColors.buttercream,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: DashboardColors.buttercream.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'NIP: ${d.nip}',
                      style: TextStyle(
                        color: DashboardColors.buttercream,
                        fontSize: 13,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Statistics Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.people_rounded,
                          title: 'Mahasiswa',
                          value: jumlahMahasiswa.toString(),
                          subtitle: 'Bimbingan',
                          color: DashboardColors.apricotBrandy,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.check_circle_rounded,
                          title: 'Pendaftar',
                          value: totalPendaftar.toString(),
                          subtitle: 'Slot Bimbingan',
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Reminder untuk membuat slot (jika belum ada slot)
                  if (perluBuatSlot) ...[
                    _buildReminderCard(pesanNotifikasi),
                    SizedBox(height: 16),
                  ],

                  // Notification Card (jika ada slot dengan pendaftar)
                  if (totalPendaftar > 0) ...[
                    _buildNotificationCard(totalPendaftar),
                    SizedBox(height: 24),
                  ],

                  // Menu Section Title
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: DashboardColors.spicedApple,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Menu Utama',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: DashboardColors.cacaoNibs,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Modern Card Grid Menu
                  _buildModernMenuCard(
                    icon: Icons.event_available_rounded,
                    title: 'Daftar Pengajuan Slot Bimbingan',
                    subtitle: 'Lihat mahasiswa yang mendaftar di slot Anda',
                    gradient: [
                      DashboardColors.apricotBrandy,
                      DashboardColors.apricotBrandy.withOpacity(0.8),
                    ],
                    delay: 0,
                    badge: totalPendaftar > 0 ? totalPendaftar : null,
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/dosen/permintaan/list',
                      );
                      if (result == true) {
                        _refreshData();
                      }
                    },
                  ),
                  SizedBox(height: 12),

                  _buildModernMenuCard(
                    icon: Icons.calendar_today_rounded,
                    title: 'Jadwal Slot Bimbingan',
                    subtitle: 'Atur jadwal ketersediaan Anda',
                    gradient: [
                      DashboardColors.mochaMousse,
                      DashboardColors.mochaMousse.withOpacity(0.8),
                    ],
                    delay: 100,
                    badge: perluBuatSlot ? 1 : null,
                    showWarningBadge: perluBuatSlot,
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/dosen/slot/list',
                      );
                      if (result == true) {
                        _refreshData();
                      }
                    },
                  ),
                  SizedBox(height: 12),

                  _buildModernMenuCard(
                    icon: Icons.people_outline_rounded,
                    title: 'Mahasiswa Bimbingan',
                    subtitle:
                        'Lihat daftar $jumlahMahasiswa mahasiswa bimbingan',
                    gradient: [
                      DashboardColors.cacaoNibs,
                      DashboardColors.cacaoNibs.withOpacity(0.8),
                    ],
                    delay: 200,
                    badge: jumlahMahasiswa > 0 ? jumlahMahasiswa : null,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/dosen/mahasiswa_bimbingan',
                    ),
                  ),
                  SizedBox(height: 12),

                  _buildModernMenuCard(
                    icon: Icons.history_rounded,
                    title: 'Riwayat Bimbingan',
                    subtitle: bimbinganPerluDitindak > 0
                        ? '$bimbinganPerluDitindak pengajuan perlu ditindak'
                        : 'Kelola bimbingan mahasiswa',
                    gradient: [
                      DashboardColors.spicedApple,
                      DashboardColors.spicedApple.withOpacity(0.8),
                    ],
                    delay: 300,
                    badge: bimbinganPerluDitindak > 0
                        ? bimbinganPerluDitindak
                        : null,
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/dosen/bimbingan/riwayat',
                      );
                      if (result == true) {
                        _refreshData();
                      }
                    },
                  ),

                  SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(String pesanNotifikasi) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange.shade400, Colors.orange.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                '/dosen/slot/list',
              );
              if (result == true) {
                _refreshData();
              }
            },
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
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Slot Bimbingan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          pesanNotifikasi,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(int totalPendaftar) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: DashboardColors.wheat,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                '/dosen/slot/list',
              );
              if (result == true) {
                _refreshData();
              }
            },
            splashColor: DashboardColors.apricotBrandy.withOpacity(0.1),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DashboardColors.apricotBrandy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: DashboardColors.buttercream,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Slot dengan Pendaftar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: DashboardColors.spicedApple,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Ada $totalPendaftar mahasiswa yang mendaftar di slot Anda',
                          style: TextStyle(
                            fontSize: 12,
                            color: DashboardColors.cacaoNibs.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: DashboardColors.apricotBrandy,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * animValue),
          child: Opacity(opacity: animValue, child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: DashboardColors.cacaoNibs,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: DashboardColors.mochaMousse,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: DashboardColors.mochaMousse.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
    required int delay,
    int? badge,
    bool showWarningBadge = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(opacity: animValue, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            splashColor: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          icon,
                          color: DashboardColors.buttercream,
                          size: 30,
                        ),
                      ),
                      if (badge != null)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: showWarningBadge
                                  ? Colors.orange.shade400
                                  : DashboardColors.wheat,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: DashboardColors.buttercream,
                                width: 2,
                              ),
                            ),
                            child: showWarningBadge
                                ? Icon(
                                    Icons.notification_important_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : Text(
                                    badge.toString(),
                                    style: TextStyle(
                                      color: DashboardColors.spicedApple,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: DashboardColors.buttercream,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: DashboardColors.buttercream.withOpacity(0.8),
                            fontSize: 12,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: DashboardColors.buttercream.withOpacity(0.8),
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
