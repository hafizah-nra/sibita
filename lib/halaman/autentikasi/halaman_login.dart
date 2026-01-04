import 'package:flutter/material.dart';
import '../../config/restapi.dart';
import '../../config/manajer_session.dart';
import '../../util/dialog_helper.dart';
import '../../model/dosen_model.dart';
import '../koordinasi/dashboard_koordinasi.dart';

class HalamanLogin extends StatefulWidget {
  const HalamanLogin({Key? key}) : super(key: key);

  @override
  _HalamanLoginState createState() => _HalamanLoginState();
}

class _HalamanLoginState extends State<HalamanLogin>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Color Palette
  static const Color buttercream = Color(0xFFEDE2D0);
  static const Color wheat = Color(0xFFE9D2A9);
  static const Color apricotBrandy = Color(0xFFBB6A57);
  static const Color mochaMousse = Color(0xFFA57865);
  static const Color cacaoNibs = Color(0xFF7B5747);
  static const Color spicedApple = Color(0xFF793937);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _pwCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    DialogHelper.showLoadingDialog(context, message: 'Masuk...');

    final api = RestApi.instance;
    final session = ManajerSession.instance;
    final username = _usernameCtrl.text.trim();
    final password = _pwCtrl.text.trim();

    try {
      // Coba login sebagai mahasiswa terlebih dahulu
      final m = await api.loginMahasiswa(username, password);
      if (m != null) {
        if (!mounted) return;
        Navigator.pop(context); // Tutup loading dialog

        // Set flag navigating untuk mencegah race condition
        session.startNavigation();

        // Set session DULU sebelum navigasi
        session.loginMahasiswa(m);

        _showSuccessSnackBar('Login berhasil! Selamat datang ${m.nama}');

        // Navigasi ke dashboard dengan clear stack
        await Future.delayed(Duration(milliseconds: 50));
        if (!mounted) {
          session.endNavigation();
          return;
        }

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/mahasiswa/dashboard',
          (route) => false,
          arguments: m,
        );

        Future.delayed(Duration(milliseconds: 100), () {
          session.endNavigation();
        });
        return;
      }

      // Jika gagal, coba login sebagai dosen
      final d = await api.loginDosen(username, password);
      if (d != null) {
        if (!mounted) return;
        Navigator.pop(context); // Tutup loading dialog

        // Cek apakah dosen memiliki 2 role (dosen & koordinator)
        if (d.isKoordinator == 'true') {
          // Tampilkan dialog pilihan role
          setState(() => _isLoading = false);
          _showRoleSelectionDialog(d);
          return;
        } else {
          // Dosen biasa langsung masuk
          // Set flag navigating untuk mencegah race condition
          session.startNavigation();

          // Set session DULU sebelum navigasi
          session.loginDosen(d);

          _showSuccessSnackBar('Login berhasil! Selamat datang ${d.nama}');

          // Navigasi ke dashboard dengan clear stack
          await Future.delayed(Duration(milliseconds: 50));
          if (!mounted) {
            session.endNavigation();
            return;
          }

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dosen/dashboard',
            (route) => false,
            arguments: d,
          );

          Future.delayed(Duration(milliseconds: 100), () {
            session.endNavigation();
          });
          return;
        }
      }

      // Jika semua gagal
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading dialog
      _showErrorSnackBar('Username atau password salah');
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading dialog
      _showErrorSnackBar(
        'Gagal terhubung ke server. Periksa koneksi internet.',
      );
      setState(() => _isLoading = false);
    }
  }

  void _showRoleSelectionDialog(DosenModel dosen) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: wheat.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 48,
                    color: apricotBrandy,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Pilih Role',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: cacaoNibs,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Anda memiliki 2 role. Pilih role untuk masuk:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: mochaMousse),
                ),
                SizedBox(height: 24),

                // Tombol Dosen
                InkWell(
                  onTap: () {
                    Navigator.of(dialogContext).pop('dosen');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: wheat.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: wheat, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: apricotBrandy.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            color: apricotBrandy,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dosen',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: cacaoNibs,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Masuk sebagai dosen pembimbing',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mochaMousse,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: mochaMousse,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Tombol Koordinator
                InkWell(
                  onTap: () {
                    Navigator.of(dialogContext).pop('koordinator');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [apricotBrandy, spicedApple],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: apricotBrandy.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Koordinator',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Masuk sebagai koordinator TA',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Proses hasil pilihan setelah dialog tertutup
    if (!mounted || result == null) return;

    // Set flag navigating untuk mencegah listener di dashboard redirect balik
    final session = ManajerSession.instance;
    session.startNavigation();

    if (result == 'dosen') {
      // Set session DULU sebelum navigasi
      session.loginDosen(dosen);

      // Tunggu frame berikutnya untuk memastikan state sudah ter-update
      await Future.delayed(Duration(milliseconds: 50));

      if (!mounted) {
        session.endNavigation();
        return;
      }

      _showSuccessSnackBar(
        'Login berhasil sebagai Dosen! Selamat datang ${dosen.nama}',
      );

      // Navigasi dengan pushNamedAndRemoveUntil untuk clear stack
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dosen/dashboard',
        (route) => false,
        arguments: dosen,
      );

      // End navigation setelah navigasi selesai
      Future.delayed(Duration(milliseconds: 100), () {
        session.endNavigation();
      });
    } else if (result == 'koordinator') {
      // Set session DULU sebelum navigasi
      session.loginKoordinator(dosen);

      // Tunggu frame berikutnya untuk memastikan state sudah ter-update
      await Future.delayed(Duration(milliseconds: 50));

      if (!mounted) {
        session.endNavigation();
        return;
      }

      _showSuccessSnackBar(
        'Login berhasil sebagai Koordinator! Selamat datang ${dosen.nama}',
      );

      // Navigasi dengan pushAndRemoveUntil untuk clear stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (ctx) => DashboardKoordinasi(koordinator: dosen),
        ),
        (route) => false,
      );

      // End navigation setelah navigasi selesai
      Future.delayed(Duration(milliseconds: 100), () {
        session.endNavigation();
      });
    }
  }

  // ✅ Helper method untuk SnackBar Success
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
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
        duration: Duration(seconds: 3),
      ),
    );
  }

  // ✅ Helper method untuk SnackBar Error
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
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
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: buttercream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20),

                    // Image Section
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: cacaoNibs.withOpacity(0.15),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/login.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.book_rounded,
                                size: 64,
                                color: apricotBrandy,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    Text(
                      'SIBITA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: spicedApple,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sistem Informasi Bimbingan Tugas Akhir',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: mochaMousse,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 40),

                    // Form Fields
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: cacaoNibs.withOpacity(0.1),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(
                            controller: _usernameCtrl,
                            label: 'Username',
                            hint: 'NRP / NIP',
                            icon: Icons.person_rounded,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Username wajib diisi';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: _pwCtrl,
                            label: 'Password',
                            hint: 'Masukkan password Anda',
                            icon: Icons.lock_rounded,
                            obscure: !_showPassword,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Password wajib diisi';
                              if (v.length < 6)
                                return 'Password minimal 6 karakter';
                              return null;
                            },
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: mochaMousse,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/lupa'),
                              child: Text(
                                'Lupa password?',
                                style: TextStyle(
                                  color: apricotBrandy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Catatan untuk user
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: wheat.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: wheat, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: apricotBrandy,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Catatan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cacaoNibs,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          _buildCatatanItem(
                            'Mahasiswa',
                            'Gunakan NRP dan password akun SIKAD',
                          ),
                          SizedBox(height: 4),
                          _buildCatatanItem(
                            'Dosen',
                            'Gunakan NIP dan password',
                          ),
                          SizedBox(height: 4),
                          _buildCatatanItem(
                            'Koordinator',
                            'Gunakan NIP dan password',
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Login Button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [apricotBrandy, spicedApple],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: apricotBrandy.withOpacity(0.4),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login_rounded, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCatatanItem(String role, String keterangan) {
    return Padding(
      padding: EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(color: mochaMousse, fontSize: 13, height: 1.4),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: mochaMousse, fontSize: 13, height: 1.4),
                children: [
                  TextSpan(
                    text: '$role: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cacaoNibs,
                    ),
                  ),
                  TextSpan(text: keterangan),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cacaoNibs,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: TextStyle(color: spicedApple),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: mochaMousse.withOpacity(0.5)),
            prefixIcon: Icon(icon, color: apricotBrandy, size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: wheat.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: wheat),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: wheat),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: apricotBrandy, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: spicedApple),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: spicedApple, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
