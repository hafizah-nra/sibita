import 'package:flutter/material.dart';
import '../../../config/restapi.dart';
import '../../../config/manajer_session.dart';

class FormPermintaanTa extends StatefulWidget {
  @override
  _FormPermintaanTaState createState() => _FormPermintaanTaState();
}

class _FormPermintaanTaState extends State<FormPermintaanTa> {
  final _formKey = GlobalKey<FormState>();
  final _judul = TextEditingController();
  final _ipk = TextEditingController();
  String? _selectedBidang;
  String? _customBidang;
  final _customBidangController = TextEditingController();
  String _msg = '';
  bool _isLoading = false;
  int _currentStep = 0;

  // Color Palette
  final Color buttercream = Color(0xFFEDE2D0);
  final Color wheat = Color(0xFFE9D2A9);
  final Color apricotBrandy = Color(0xFFBB6A57);
  final Color mochaMousse = Color(0xFFA57865);
  final Color cacaoNibs = Color(0xFF7B5747);
  final Color spicedApple = Color(0xFF793937);

  // Daftar bidang penelitian
  final List<String> _bidangList = [
    'Data Mining',
    'Arsitektur Enterprise',
    'Tata Kelola',
    'Manajemen Resiko',
    'Behavioral Design',
    'UI UX',
    'ITSM',
    'Software Engineering',
    'Pengolahan Citra Digital',
    'Sentimen Analisis',
    'Data Base',
    'Cloud',
    'Business Process',
    'AI',
    'Other',
  ];

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _msg = 'Mohon lengkapi semua field yang wajib diisi');
      return;
    }

    if (_selectedBidang == null) {
      setState(() => _msg = 'Pilih bidang penelitian');
      return;
    }

    if (_selectedBidang == 'Other' && (_customBidang == null || _customBidang!.isEmpty)) {
      setState(() => _msg = 'Mohon isi bidang penelitian lainnya');
      return;
    }

    final m = ManajerSession.instance.mahasiswa;
    if (m == null) return;

    setState(() {
      _isLoading = true;
      _msg = '';
    });

    await Future.delayed(Duration(milliseconds: 800));

    final bidangFinal = _selectedBidang == 'Other' ? _customBidang! : _selectedBidang!;
    
    final result = await RestApi.instance.createPermintaan(
      nrp: m.nrp,
      judul: _judul.text.trim(),
      bidang: bidangFinal,
      ipk: _ipk.text.trim(),
    );

    setState(() {
      _isLoading = false;
      _msg = result != null ? 'Permintaan berhasil terkirim!' : 'Gagal mengirim permintaan';
    });

    if (result != null) {
      // Tunggu sebentar untuk menampilkan pesan sukses
      await Future.delayed(Duration(seconds: 1));
      
      // Kembali ke dashboard dengan mengirim signal bahwa data berhasil ditambahkan
      Navigator.pop(context, true);
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          _buildStepCircle(0, 'Info'),
          _buildStepLine(0),
          _buildStepCircle(1, 'Review'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? apricotBrandy : wheat,
              border: Border.all(
                color: isCurrent ? spicedApple : Colors.transparent,
                width: 3,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: apricotBrandy.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: isActive
                  ? Icon(
                      step < _currentStep ? Icons.check : Icons.circle,
                      color: buttercream,
                      size: step < _currentStep ? 24 : 12,
                    )
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: mochaMousse,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? cacaoNibs : mochaMousse,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: EdgeInsets.only(bottom: 30),
        color: isActive ? apricotBrandy : wheat,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cacaoNibs.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: mochaMousse),
          prefixIcon: Icon(icon, color: apricotBrandy),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: TextStyle(color: spicedApple),
        ),
        style: TextStyle(color: cacaoNibs),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: wheat.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: wheat, width: 2),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: apricotBrandy, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Isi informasi dasar tugas akhir Anda',
                  style: TextStyle(
                    color: cacaoNibs,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        _buildTextField(
          controller: _judul,
          label: 'Judul Tugas Akhir',
          icon: Icons.title,
          maxLines: 3,
          validator: (v) => v == null || v.isEmpty ? 'Judul wajib diisi' : null,
        ),
        
        // Dropdown untuk bidang penelitian
        Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: cacaoNibs.withOpacity(0.08),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedBidang,
            decoration: InputDecoration(
              labelText: 'Bidang Penelitian',
              labelStyle: TextStyle(color: mochaMousse),
              prefixIcon: Icon(Icons.category, color: apricotBrandy),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              errorStyle: TextStyle(color: spicedApple),
            ),
            style: TextStyle(color: cacaoNibs, fontSize: 16),
            dropdownColor: Colors.white,
            items: _bidangList.map((bidang) {
              return DropdownMenuItem<String>(
                value: bidang,
                child: Text(
                  bidang,
                  style: TextStyle(color: cacaoNibs),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBidang = value;
                if (value != 'Other') {
                  _customBidang = null;
                  _customBidangController.clear();
                }
              });
            },
            validator: (v) => v == null ? 'Bidang penelitian wajib dipilih' : null,
          ),
        ),
        
        // TextField untuk custom bidang jika memilih "Other"
        if (_selectedBidang == 'Other') ...[
          Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: cacaoNibs.withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: _customBidangController,
              decoration: InputDecoration(
                labelText: 'Sebutkan bidang penelitian lainnya',
                labelStyle: TextStyle(color: mochaMousse),
                prefixIcon: Icon(Icons.edit, color: apricotBrandy),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                errorStyle: TextStyle(color: spicedApple),
              ),
              style: TextStyle(color: cacaoNibs),
              onChanged: (value) {
                setState(() => _customBidang = value);
              },
              validator: (v) => v == null || v.isEmpty ? 'Field ini wajib diisi' : null,
            ),
          ),
        ],
        
        _buildTextField(
          controller: _ipk,
          label: 'IPK',
          icon: Icons.school,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.isEmpty) return 'IPK wajib diisi';
            final ipk = double.tryParse(v);
            if (ipk == null) return 'IPK harus berupa angka';
            if (ipk < 0 || ipk > 4) return 'IPK harus antara 0-4';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep1() {
    final bidangFinal = _selectedBidang == 'Other' ? _customBidang ?? '' : _selectedBidang ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: wheat.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: wheat, width: 2),
          ),
          child: Row(
            children: [
              Icon(Icons.preview, color: apricotBrandy, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Review permintaan Anda sebelum dikirim',
                  style: TextStyle(
                    color: cacaoNibs,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        _buildReviewCard(
          icon: Icons.title,
          label: 'Judul Tugas Akhir',
          value: _judul.text,
        ),
        _buildReviewCard(
          icon: Icons.category,
          label: 'Bidang Penelitian',
          value: bidangFinal,
        ),
        _buildReviewCard(
          icon: Icons.school,
          label: 'IPK',
          value: _ipk.text,
        ),
      ],
    );
  }

  Widget _buildReviewCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cacaoNibs.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: wheat,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: apricotBrandy, size: 24),
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
                    color: mochaMousse,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: buttercream,
      appBar: AppBar(
        title: Text('Form Permintaan TA', style: TextStyle(color: buttercream)),
        backgroundColor: spicedApple,
        elevation: 0,
        iconTheme: IconThemeData(color: buttercream),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    if (_currentStep == 0) _buildStep0(),
                    if (_currentStep == 1) _buildStep1(),
                    // Tambahan space agar tidak tertutup bottom bar
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar Fixed
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: cacaoNibs.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Message
                if (_msg.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _msg.contains('berhasil')
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _msg.contains('berhasil') ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _msg.contains('berhasil') ? Icons.check_circle : Icons.error,
                          color: _msg.contains('berhasil') ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _msg,
                            style: TextStyle(
                              color: _msg.contains('berhasil')
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Navigation Buttons
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => setState(() => _currentStep--),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: apricotBrandy, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back, color: apricotBrandy, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Kembali',
                                  style: TextStyle(
                                    color: apricotBrandy,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) SizedBox(width: 12),
                    Expanded(
                      flex: _currentStep > 0 ? 1 : 1,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [apricotBrandy, spicedApple],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: apricotBrandy.withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (_currentStep < 1) {
                                    if (_currentStep == 0) {
                                      if (!_formKey.currentState!.validate()) {
                                        setState(() =>
                                            _msg = 'Lengkapi informasi dasar terlebih dahulu');
                                        return;
                                      }
                                      if (_selectedBidang == null) {
                                        setState(() => _msg = 'Pilih bidang penelitian');
                                        return;
                                      }
                                      if (_selectedBidang == 'Other' && 
                                          (_customBidang == null || _customBidang!.isEmpty)) {
                                        setState(() => _msg = 'Isi bidang penelitian lainnya');
                                        return;
                                      }
                                    }
                                    setState(() {
                                      _currentStep++;
                                      _msg = '';
                                    });
                                  } else {
                                    _submit();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(buttercream),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _currentStep < 1 ? 'Lanjut' : 'Kirim',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: buttercream,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      _currentStep < 1 ? Icons.arrow_forward : Icons.send,
                                      color: buttercream,
                                      size: 18,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _judul.dispose();
    _ipk.dispose();
    _customBidangController.dispose();
    super.dispose();
  }
}