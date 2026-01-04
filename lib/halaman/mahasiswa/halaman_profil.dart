import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../../config/manajer_session.dart';
import '../../config/restapi.dart';
import '../../model/mahasiswa_model.dart';

class HalamanProfil extends StatefulWidget {
  @override
  _HalamanProfilState createState() => _HalamanProfilState();
}

class _HalamanProfilState extends State<HalamanProfil>
    with SingleTickerProviderStateMixin {
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _ipk = TextEditingController();
  final _judulTA = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  bool _obscurePassword = true;

  // Untuk menyimpan gambar yang dipilih (kompatibel Web & Mobile)
  Uint8List? _newImageBytes; // Gambar baru yang dipilih user
  String? _savedFotoBase64; // Foto yang tersimpan di database (base64)

  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Color Palette
  final Color buttercream = Color(0xFFEDE2D0);
  final Color wheat = Color(0xFFE9D2A9);
  final Color apricotBrandy = Color(0xFFBB6A57);
  final Color mochaMousse = Color(0xFFA57865);
  final Color cacaoNibs = Color(0xFF785747);
  final Color spicedApple = Color(0xFF793937);

  @override
  void initState() {
    super.initState();
    _loadProfileData();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadProfileData() async {
    final m = ManajerSession.instance.mahasiswa;
    if (m != null) {
      setState(() {
        _nama.text = m.nama;
        _email.text = m.email;

        // Load foto profil dari database jika ada
        if (m.fotoProfil.isNotEmpty && m.fotoProfil != '-') {
          _savedFotoBase64 = m.fotoProfil;
        }

        // Ambil IPK dari data mahasiswa jika ada
        if (m.ipk.isNotEmpty && m.ipk != '-') {
          _ipk.text = m.ipk;
        }

        // Ambil judul dari data mahasiswa jika ada
        if (m.judul.isNotEmpty && m.judul != '-') {
          _judulTA.text = m.judul;
        }
      });

      // Jika judul atau IPK masih kosong, coba ambil dari permintaan TA yang diterima
      if (_judulTA.text.isEmpty || _ipk.text.isEmpty) {
        try {
          final permintaanList = await RestApi.instance
              .daftarPermintaanUntukMahasiswa(m.nrp);
          final permintaanDiterima = permintaanList
              .where((p) => p.status.toLowerCase() == 'terima')
              .toList();
          if (permintaanDiterima.isNotEmpty) {
            setState(() {
              if (_judulTA.text.isEmpty) {
                _judulTA.text = permintaanDiterima.first.judul;
              }
              if (_ipk.text.isEmpty &&
                  permintaanDiterima.first.ipk.isNotEmpty) {
                _ipk.text = permintaanDiterima.first.ipk;
              }
            });
          }
        } catch (e) {
          print('Error loading permintaan: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _pw.dispose();
    _ipk.dispose();
    _judulTA.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Validasi apakah file adalah gambar yang diizinkan
  bool _isValidImageFile(String? fileName) {
    if (fileName == null) return false;
    final ext = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        // Validasi tipe file
        if (!_isValidImageFile(pickedFile.name)) {
          _showMessage(
            'Format file tidak didukung. Gunakan JPG, JPEG, PNG, atau WEBP',
            isError: true,
          );
          return;
        }

        final bytes = await pickedFile.readAsBytes();

        // Cek ukuran file (maksimal 100KB setelah kompresi)
        if (bytes.length > 100 * 1024) {
          _showMessage('Foto terlalu besar. Maksimal 100KB.', isError: true);
          return;
        }

        setState(() {
          _newImageBytes = bytes;
        });

        _showMessage(
          'Foto berhasil dipilih (${(bytes.length / 1024).toStringAsFixed(1)} KB)',
          isError: false,
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      _showMessage('Gagal memilih foto', isError: true);
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _pw.clear();
        _newImageBytes = null; // Reset gambar baru jika batal
      }
    });
  }

  Future<void> _save() async {
    final m = ManajerSession.instance.mahasiswa;
    if (m == null) return;

    if (_nama.text.trim().isEmpty) {
      _showMessage('Nama tidak boleh kosong', isError: true);
      return;
    }

    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      _showMessage('Email tidak valid', isError: true);
      return;
    }

    if (_ipk.text.isNotEmpty) {
      final ipkValue = double.tryParse(_ipk.text);
      if (ipkValue == null || ipkValue < 0.0 || ipkValue > 4.0) {
        _showMessage('IPK harus antara 0.00 - 4.00', isError: true);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Konversi gambar baru ke Base64 jika ada
      String? fotoBase64;
      if (_newImageBytes != null) {
        fotoBase64 = base64Encode(_newImageBytes!);
      }

      final ok = await RestApi.instance.updateMahasiswaProfile(
        nrp: m.nrp,
        nama: _nama.text.trim(),
        email: _email.text.trim(),
        password: _pw.text.isEmpty ? null : _pw.text,
        ipk: _ipk.text.isNotEmpty ? double.tryParse(_ipk.text) : null,
        fotoProfil: fotoBase64,
      );

      if (ok) {
        // Update foto yang tersimpan
        if (fotoBase64 != null) {
          _savedFotoBase64 = fotoBase64;
        }

        // Update session dengan data baru
        final updatedMahasiswa = MahasiswaModel(
          id: m.id,
          nrp: m.nrp,
          nama: _nama.text.trim(),
          email: _email.text.trim(),
          password: _pw.text.isEmpty ? m.password : _pw.text,
          fotoProfil: fotoBase64 ?? m.fotoProfil,
          ipk: _ipk.text.isNotEmpty ? _ipk.text : m.ipk,
          judul: _judulTA.text.isNotEmpty ? _judulTA.text : m.judul,
          nip: m.nip,
        );
        ManajerSession.instance.setMahasiswa(updatedMahasiswa);

        setState(() => _isLoading = false);
        _showMessage('Profil berhasil diperbarui!', isError: false);
        _toggleEdit();
        _pw.clear();
      } else {
        setState(() => _isLoading = false);
        _showMessage('Gagal menyimpan profil', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Terjadi kesalahan: $e', isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? spicedApple : apricotBrandy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Widget untuk menampilkan foto profil
  Widget _buildProfilePhoto() {
    // Prioritas: gambar baru > gambar tersimpan (base64) > placeholder
    final bool hasNewImage = _newImageBytes != null;
    final bool hasSavedImage =
        _savedFotoBase64 != null && _savedFotoBase64!.isNotEmpty;

    Widget imageWidget;

    if (hasNewImage) {
      // Tampilkan gambar baru yang dipilih
      imageWidget = Image.memory(
        _newImageBytes!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) =>
            _buildEmptyPhotoPlaceholder(),
      );
    } else if (hasSavedImage) {
      // Tampilkan gambar dari database (base64)
      try {
        final bytes = base64Decode(_savedFotoBase64!);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          errorBuilder: (context, error, stackTrace) =>
              _buildEmptyPhotoPlaceholder(),
        );
      } catch (e) {
        imageWidget = _buildEmptyPhotoPlaceholder();
      }
    } else {
      imageWidget = _buildEmptyPhotoPlaceholder();
    }

    return Stack(
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: wheat,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: buttercream,
              ),
              child: ClipOval(child: imageWidget),
            ),
          ),
        ),

        // Icon kamera (hanya tampil saat editing)
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImageFromGallery,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: apricotBrandy,
                  shape: BoxShape.circle,
                  border: Border.all(color: buttercream, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Widget placeholder saat foto kosong
  Widget _buildEmptyPhotoPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: wheat.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_outline_rounded,
        size: 50,
        color: mochaMousse.withOpacity(0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = ManajerSession.instance.mahasiswa;

    return Scaffold(
      backgroundColor: buttercream,
      appBar: AppBar(
        title: Text(
          'Profil Saya',
          style: TextStyle(
            color: buttercream,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: mochaMousse,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: buttercream),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit_outlined),
              onPressed: _toggleEdit,
              tooltip: 'Edit Profil',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header dengan foto profil
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: mochaMousse,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.only(top: 20, bottom: 40),
              child: Column(
                children: [
                  // Foto profil dengan icon kamera
                  GestureDetector(
                    onTap: _isEditing ? _pickImageFromGallery : null,
                    child: _buildProfilePhoto(),
                  ),
                  SizedBox(height: 15),
                  Text(
                    m?.nama ?? 'User',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: buttercream,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    m?.nrp ?? '',
                    style: TextStyle(fontSize: 16, color: wheat),
                  ),
                ],
              ),
            ),

            // Info Cards
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  if (_isEditing) ...[
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nama,
                            label: 'Nama',
                            icon: Icons.person_outline,
                            enabled: _isEditing,
                          ),
                          SizedBox(height: 15),
                          _buildTextField(
                            controller: _email,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            enabled: _isEditing,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 15),
                          _buildTextField(
                            controller: _ipk,
                            label: 'IPK',
                            icon: Icons.school_outlined,
                            enabled: _isEditing,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          SizedBox(height: 15),
                          _buildTextField(
                            controller: _judulTA,
                            label: 'Judul Tugas Akhir',
                            icon: Icons.book_outlined,
                            enabled: _isEditing,
                            maxLines: 2,
                          ),
                          SizedBox(height: 15),
                          _buildTextField(
                            controller: _pw,
                            label: 'Password Baru',
                            icon: Icons.lock_outline,
                            enabled: _isEditing,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: mochaMousse,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 25),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _toggleEdit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: wheat,
                                    foregroundColor: cacaoNibs,
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Batal',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: apricotBrandy,
                                    foregroundColor: buttercream,
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  buttercream,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          'Simpan',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _buildInfoCard(
                      icon: Icons.person_outline,
                      label: 'Nama',
                      value: _nama.text.isEmpty ? '-' : _nama.text,
                    ),
                    SizedBox(height: 15),
                    _buildInfoCard(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _email.text.isEmpty ? '-' : _email.text,
                    ),
                    SizedBox(height: 15),
                    _buildInfoCard(
                      icon: Icons.school_outlined,
                      label: 'IPK',
                      value: _ipk.text.isEmpty
                          ? '-'
                          : double.tryParse(_ipk.text)?.toStringAsFixed(2) ??
                                _ipk.text,
                    ),
                    SizedBox(height: 15),
                    _buildInfoCard(
                      icon: Icons.book_outlined,
                      label: 'Judul Tugas Akhir',
                      value: _judulTA.text.isEmpty ? '-' : _judulTA.text,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: mochaMousse.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: cacaoNibs, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: mochaMousse, fontSize: 14),
          prefixIcon: Icon(icon, color: apricotBrandy, size: 22),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: mochaMousse.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: apricotBrandy.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: apricotBrandy, size: 22),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: mochaMousse,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: cacaoNibs,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
