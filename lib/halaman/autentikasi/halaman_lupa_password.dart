import 'package:flutter/material.dart';
import '../../config/restapi.dart';

class HalamanLupaPassword extends StatefulWidget {
  @override
  _HalamanLupaPasswordState createState() => _HalamanLupaPasswordState();
}

class _HalamanLupaPasswordState extends State<HalamanLupaPassword> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  String _msg = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Color Palette
  final Color buttercream = Color(0xFFEDE2D0);
  final Color wheat = Color(0xFFE9D2A9);
  final Color apricotBrandy = Color(0xFFBB6A57);
  final Color mochaMousse = Color(0xFFA57865);
  final Color cacaoNibs = Color(0xFF7B5747);
  final Color spicedApple = Color(0xFF793937);

  /// Cek apakah email terdaftar di database mahasiswa atau dosen
  Future<bool> _isEmailTerdaftar(String email) async {
    try {
      // Cek di database mahasiswa
      final semuaMahasiswa = await RestApi.instance.semuaMahasiswa();
      final mahasiswaExists = semuaMahasiswa.any(
        (mhs) => mhs.email.toLowerCase() == email.toLowerCase()
      );
      
      if (mahasiswaExists) return true;
      
      // Cek di database dosen
      final semuaDosen = await RestApi.instance.semuaDosen();
      final dosenExists = semuaDosen.any(
        (dsn) => dsn.email.toLowerCase() == email.toLowerCase()
      );
      
      return dosenExists;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  void _submit() async {
    if (_email.text.trim().isEmpty || _pw.text.isEmpty) {
      setState(() => _msg = 'Mohon isi semua field');
      return;
    }

    // Validasi format email sederhana
    if (!_email.text.trim().contains('@')) {
      setState(() => _msg = 'Format email tidak valid');
      return;
    }

    // Validasi panjang password minimal
    if (_pw.text.length < 6) {
      setState(() => _msg = 'Password minimal 6 karakter');
      return;
    }

    setState(() {
      _msg = '';
      _isLoading = true;
    });

    // Cek apakah email terdaftar di database
    final emailTerdaftar = await _isEmailTerdaftar(_email.text.trim());
    
    if (!emailTerdaftar) {
      setState(() {
        _isLoading = false;
        _msg = 'Email tidak terdaftar dalam sistem';
      });
      return;
    }

    // Jika email terdaftar, lanjut reset password
    final ok = await RestApi.instance.resetPassword(_email.text.trim(), _pw.text);
    
    setState(() => _isLoading = false);

    if (ok) {
      setState(() => _msg = 'Password berhasil direset. Silakan login.');
      Future.delayed(
        Duration(seconds: 2),
        () => Navigator.pushReplacementNamed(context, '/login'),
      );
    } else {
      setState(() => _msg = 'Gagal mereset password. Silakan coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: buttercream,
      appBar: AppBar(
        title: Text('Lupa Password', style: TextStyle(color: buttercream)),
        backgroundColor: spicedApple,
        elevation: 0,
        iconTheme: IconThemeData(color: buttercream),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              // Icon Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: wheat,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_reset,
                  size: 60,
                  color: spicedApple,
                ),
              ),
              SizedBox(height: 24),
              // Title & Subtitle
              Text(
                'Reset Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: cacaoNibs,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Masukkan email terdaftar dan password baru Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: mochaMousse,
                ),
              ),
              SizedBox(height: 32),
              // Email Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Masukkan email terdaftar',
                    prefixIcon: Icon(Icons.email, color: mochaMousse),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Password Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _pw,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    hintText: 'Masukkan password baru (min. 6 karakter)',
                    prefixIcon: Icon(Icons.lock, color: mochaMousse),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: mochaMousse,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Message
              if (_msg.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _msg.contains('berhasil') 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _msg.contains('berhasil') 
                          ? Colors.green 
                          : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _msg.contains('berhasil') 
                            ? Icons.check_circle 
                            : Icons.error,
                        color: _msg.contains('berhasil') 
                            ? Colors.green 
                            : Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _msg,
                          style: TextStyle(
                            color: _msg.contains('berhasil') 
                                ? Colors.green 
                                : Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 24),
              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: spicedApple,
                  foregroundColor: buttercream,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(buttercream),
                        ),
                      )
                    : Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              SizedBox(height: 16),
              // Back to Login
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Kembali ke Login',
                  style: TextStyle(
                    color: mochaMousse,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}