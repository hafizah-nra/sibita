import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../../model/dosen_model.dart';
import '../../config/restapi.dart';
import '../../config/manajer_session.dart';

class ProfilKoordinatorPage extends StatefulWidget {
  final DosenModel koordinator;

  ProfilKoordinatorPage({required this.koordinator});

  @override
  _ProfilKoordinatorPageState createState() => _ProfilKoordinatorPageState();
}

class _ProfilKoordinatorPageState extends State<ProfilKoordinatorPage> {
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
  bool _isLoadingProfile = true; // Loading saat fetch data dari API
  bool _obscurePassword = true;
  Uint8List? _newImageBytes;
  String? _savedFotoBase64;
  final ImagePicker _picker = ImagePicker();

  late DosenModel _currentKoordinator;

  @override
  void initState() {
    super.initState();
    _currentKoordinator = widget.koordinator;
    _namaController = TextEditingController(text: _currentKoordinator.nama);
    _emailController = TextEditingController(text: _currentKoordinator.email);
    _passwordController = TextEditingController();

    // Load data terbaru dari API
    _loadProfileData();
  }

  /// Fetch data profil terbaru dari API
  Future<void> _loadProfileData() async {
    setState(() => _isLoadingProfile = true);

    try {
      // Ambil data terbaru dari API berdasarkan NIP
      final freshData = await RestApi.instance.cariDosenByNip(
        _currentKoordinator.nip,
      );

      if (freshData != null && mounted) {
        setState(() {
          _currentKoordinator = freshData;
          _namaController.text = freshData.nama;
          _emailController.text = freshData.email;

          // Load foto profil dari data terbaru
          if (freshData.fotoProfil.isNotEmpty && freshData.fotoProfil != '-') {
            _savedFotoBase64 = freshData.fotoProfil;
          } else {
            _savedFotoBase64 = null;
          }

          // Update session dengan data terbaru
          if (ManajerSession.instance.dosen?.nip == freshData.nip) {
            ManajerSession.instance.setDosen(freshData);
          }
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
      // Jika gagal fetch dari API, gunakan data dari widget sebagai fallback
      if (mounted) {
        if (_currentKoordinator.fotoProfil.isNotEmpty &&
            _currentKoordinator.fotoProfil != '-') {
          _savedFotoBase64 = _currentKoordinator.fotoProfil;
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
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
      if (!_isEditing) {
        _namaController.text = _currentKoordinator.nama;
        _emailController.text = _currentKoordinator.email;
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
        nip: _currentKoordinator.nip,
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.isEmpty
            ? null
            : _passwordController.text,
        fotoProfil: fotoBase64,
      );

      if (ok) {
        // Fetch data terbaru dari API untuk memastikan konsistensi
        final freshData = await RestApi.instance.cariDosenByNip(
          _currentKoordinator.nip,
        );

        if (freshData != null && mounted) {
          setState(() {
            _currentKoordinator = freshData;
            _namaController.text = freshData.nama;
            _emailController.text = freshData.email;

            // Update foto dari data terbaru
            if (freshData.fotoProfil.isNotEmpty &&
                freshData.fotoProfil != '-') {
              _savedFotoBase64 = freshData.fotoProfil;
            } else {
              _savedFotoBase64 = null;
            }

            _newImageBytes = null; // Reset image bytes setelah save
          });

          // Update session dengan data terbaru dari API
          if (ManajerSession.instance.dosen?.nip == freshData.nip) {
            ManajerSession.instance.setDosen(freshData);
          }
        } else {
          // Fallback: update dengan data lokal jika fetch gagal
          if (fotoBase64 != null) {
            _savedFotoBase64 = fotoBase64;
          }
          setState(() {
            _currentKoordinator = DosenModel(
              id: _currentKoordinator.id,
              nip: _currentKoordinator.nip,
              nama: _namaController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text.isEmpty
                  ? _currentKoordinator.password
                  : _passwordController.text,
              fotoProfil: fotoBase64 ?? _currentKoordinator.fotoProfil,
              isKoordinator: _currentKoordinator.isKoordinator,
            );
            _newImageBytes = null;
          });

          if (ManajerSession.instance.dosen?.nip == _currentKoordinator.nip) {
            ManajerSession.instance.setDosen(_currentKoordinator);
          }
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
          'Profil Koordinator',
          style: TextStyle(color: buttercream, fontWeight: FontWeight.bold),
        ),
        backgroundColor: cacaoNibs,
        elevation: 0,
        iconTheme: IconThemeData(color: buttercream),
        actions: [
          // Tombol refresh untuk load ulang data
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: _isLoadingProfile ? null : _loadProfileData,
            tooltip: 'Refresh Data',
          ),
          if (!_isEditing && !_isLoadingProfile)
            IconButton(
              icon: Icon(Icons.edit_outlined),
              onPressed: _toggleEdit,
              tooltip: 'Edit Profil',
            ),
        ],
      ),
      body: _isLoadingProfile
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(apricotBrandy),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data profil...',
                    style: TextStyle(color: mochaMousse),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
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
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: apricotBrandy,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                color: buttercream,
                                size: 16,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'KOORDINATOR',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: buttercream,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          _currentKoordinator.nama,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: buttercream,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'NIP: ${_currentKoordinator.nip}',
                          style: TextStyle(fontSize: 14, color: wheat),
                        ),
                      ],
                    ),
                  ),
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
          'Informasi Koordinator',
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
          value: _currentKoordinator.nama,
        ),
        SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.badge_outlined,
          label: 'NIP',
          value: _currentKoordinator.nip,
        ),
        SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.email_outlined,
          label: 'Email',
          value: _currentKoordinator.email,
        ),
        SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.verified_user_outlined,
          label: 'Status',
          value: _currentKoordinator.isKoordinator == 'true'
              ? 'Koordinator Aktif'
              : 'Dosen',
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
