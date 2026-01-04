import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../../model/dosen_model.dart';
import '../../config/restapi.dart';
import '../../config/manajer_session.dart';

class ProfilDosenPage extends StatefulWidget {
  final DosenModel dosen;

  ProfilDosenPage({required this.dosen});

  @override
  _ProfilDosenPageState createState() => _ProfilDosenPageState();
}

class _ProfilDosenPageState extends State<ProfilDosenPage> {
  // Color Palette
  final Color buttercream = Color(0xFFEDE2D0);
  final Color wheat = Color(0xFFE9D2A9);
  final Color apricotBrandy = Color(0xFFBB6A57);
  final Color mochaMousse = Color(0xFFA57865);
  final Color cacaoNibs = Color(0xFF785747);
  final Color spicedApple = Color(0xFF793937);

  late TextEditingController _namaController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  bool _isEditing = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  Uint8List? _newImageBytes;
  String? _savedFotoBase64;
  final ImagePicker _picker = ImagePicker();

  late DosenModel _currentDosen;

  @override
  void initState() {
    super.initState();
    _currentDosen = widget.dosen;
    _namaController = TextEditingController(text: _currentDosen.nama);
    _emailController = TextEditingController(text: _currentDosen.email);
    _passwordController = TextEditingController();

    // Load foto profil dari database
    if (_currentDosen.fotoProfil.isNotEmpty &&
        _currentDosen.fotoProfil != '-') {
      _savedFotoBase64 = _currentDosen.fotoProfil;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validasi apakah file adalah gambar yang diizinkan
  bool _isValidImageFile(String? fileName) {
    if (fileName == null) return false;
    final ext = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 200, // Lebih kecil untuk mengurangi ukuran Base64
        maxHeight: 200,
        imageQuality: 50, // Kompresi lebih agresif
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
      if (!_isEditing) {
        _namaController.text = _currentDosen.nama;
        _emailController.text = _currentDosen.email;
        _passwordController.clear();
        _newImageBytes = null;
      }
    });
  }

  Future<void> _saveProfile() async {
    if (_namaController.text.trim().isEmpty) {
      _showMessage('Nama tidak boleh kosong', isError: true);
      return;
    }

    if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      _showMessage('Email tidak valid', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Konversi gambar baru ke Base64 jika ada
      String? fotoBase64;
      if (_newImageBytes != null) {
        fotoBase64 = base64Encode(_newImageBytes!);
      }

      final ok = await RestApi.instance.updateDosenProfile(
        nip: _currentDosen.nip,
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.isEmpty
            ? null
            : _passwordController.text,
        fotoProfil: fotoBase64,
      );

      if (ok) {
        // Update foto yang tersimpan
        if (fotoBase64 != null) {
          _savedFotoBase64 = fotoBase64;
        }

        // Update data lokal
        setState(() {
          _currentDosen = DosenModel(
            id: _currentDosen.id,
            nip: _currentDosen.nip,
            nama: _namaController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.isEmpty
                ? _currentDosen.password
                : _passwordController.text,
            fotoProfil: fotoBase64 ?? _currentDosen.fotoProfil,
            isKoordinator: _currentDosen.isKoordinator,
          );
        });

        // Update session
        if (ManajerSession.instance.dosen?.nip == _currentDosen.nip) {
          ManajerSession.instance.setDosen(_currentDosen);
        }

        setState(() => _isLoading = false);
        _showMessage('Profil berhasil diperbarui!', isError: false);
        _toggleEdit();
        _passwordController.clear();
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

  Widget _buildProfilePhoto() {
    final bool hasNewImage = _newImageBytes != null;
    final bool hasSavedImage =
        _savedFotoBase64 != null && _savedFotoBase64!.isNotEmpty;

    Widget imageWidget;

    if (hasNewImage) {
      imageWidget = Image.memory(
        _newImageBytes!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) =>
            _buildEmptyPhotoPlaceholder(),
      );
    } else if (hasSavedImage) {
      try {
        // Handle Base64 dengan atau tanpa prefix data URI
        String base64String = _savedFotoBase64!;
        if (base64String.contains(',')) {
          // Format: data:image/jpeg;base64,/9j/4AAQ...
          base64String = base64String.split(',').last;
        }

        final bytes = base64Decode(base64String);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          errorBuilder: (context, error, stackTrace) =>
              _buildEmptyPhotoPlaceholder(),
        );
      } catch (e) {
        print('Error decoding Base64 foto profil: $e');
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
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
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
        size: 60,
        color: mochaMousse.withOpacity(0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: buttercream,
      appBar: AppBar(
        title: Text(
          'Profil Dosen',
          style: TextStyle(color: buttercream, fontWeight: FontWeight.bold),
        ),
        backgroundColor: cacaoNibs,
        elevation: 0,
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
                color: cacaoNibs,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.only(top: 20, bottom: 30),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: _buildProfilePhoto(),
                  ),
                  SizedBox(height: 15),
                  Text(
                    _currentDosen.nama,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: buttercream,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'NIP: ${_currentDosen.nip}',
                    style: TextStyle(fontSize: 14, color: wheat),
                  ),
                ],
              ),
            ),

            // Form Edit atau Info Cards
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _isEditing ? _buildEditForm() : _buildInfoCards(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _namaController,
          label: 'Nama Lengkap',
          icon: Icons.person_outline,
        ),
        SizedBox(height: 15),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 15),
        _buildTextField(
          controller: _passwordController,
          label: 'Password Baru (kosongkan jika tidak diubah)',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: mochaMousse,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
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
                          valueColor: AlwaysStoppedAnimation<Color>(
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
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
        obscureText: obscureText,
        keyboardType: keyboardType,
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

  Widget _buildInfoCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Dosen',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cacaoNibs,
          ),
        ),
        SizedBox(height: 15),
        _buildInfoCard(
          icon: Icons.person_outline,
          label: 'Nama Lengkap',
          value: _currentDosen.nama,
        ),
        SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.badge_outlined,
          label: 'NIP',
          value: _currentDosen.nip,
        ),
        SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.email_outlined,
          label: 'Email',
          value: _currentDosen.email,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: wheat, width: 1),
        boxShadow: [
          BoxShadow(
            color: mochaMousse.withOpacity(0.08),
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
              color: wheat.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: apricotBrandy, size: 24),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
