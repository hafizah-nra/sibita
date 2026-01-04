import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../config/restapi.dart';
import '../../../config/manajer_session.dart';
import '../../../model/slot_model.dart';
import '../../../model/bimbingan_model.dart';
import 'package:intl/intl.dart';

class DaftarKeSlot extends StatefulWidget {
  @override
  _DaftarKeSlotState createState() => _DaftarKeSlotState();
}

class _DaftarKeSlotState extends State<DaftarKeSlot> {
  final Color buttercream = Color(0xFFEDE2D0);
  final Color wheat = Color(0xFFE9D2A9);
  final Color apricotBrandy = Color(0xFFBB6A57);
  final Color mochaMousse = Color(0xFFA57865);
  final Color cacaoNibs = Color(0xFF7B5747);
  final Color spicedApple = Color(0xFF793937);

  final _formKey = GlobalKey<FormState>();
  final _deskripsiController = TextEditingController();

  String _msg = '';
  bool _isLoading = false;
  Future<SlotModel?>? _slotFuture;

  // Form fields
  String? _selectedBab;
  PlatformFile? _selectedFile;
  String? _fileError;

  // Daftar pilihan Bab
  final List<String> _babList = BabBimbingan.daftarBab;

  // Allowed file extensions
  final List<String> _allowedExtensions = ['pdf', 'doc', 'docx'];
  final int _maxFileSizeBytes = 100 * 1024 * 1024; // 100 MB

  @override
  void dispose() {
    _deskripsiController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_slotFuture == null) {
      final slotId = ModalRoute.of(context)!.settings.arguments as String;
      _slotFuture = RestApi.instance.cariSlotById(slotId);
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate file size
        if (file.size > _maxFileSizeBytes) {
          setState(() {
            _fileError = 'Ukuran file maksimal 100 MB';
            _selectedFile = null;
          });
          return;
        }

        setState(() {
          _selectedFile = file;
          _fileError = null;
        });
      }
    } catch (e) {
      setState(() {
        _fileError = 'Gagal memilih file: $e';
      });
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _fileError = null;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _confirm(SlotModel slot) async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBab == null) {
      setState(() => _msg = 'Pilih bab yang akan dibimbing');
      return;
    }

    // Validasi kapasitas slot (kecuali unlimited)
    if (!slot.isUnlimited && slot.isFull) {
      setState(() => _msg = 'Slot sudah penuh. Silakan pilih slot lain.');
      return;
    }

    setState(() {
      _isLoading = true;
      _msg = '';
    });
    
    final mahasiswa = ManajerSession.instance.mahasiswa;
    
    if (mahasiswa == null || mahasiswa.nrp.isEmpty) {
      setState(() {
        _isLoading = false;
        _msg = 'Session tidak valid';
      });
      return;
    }
    
    try {
      // TODO: Upload file ke server jika ada file yang dipilih
      // Untuk sementara, kita simpan nama file saja
      String? fileUrl;
      if (_selectedFile != null) {
        // Di sini nanti bisa ditambahkan logic upload file ke cloud storage
        // Untuk sekarang simpan nama file saja
        fileUrl = _selectedFile!.name;
      }

      // Daftarkan mahasiswa ke slot dengan detail bimbingan
      final success = await RestApi.instance.daftarBimbingan(
        slotId: slot.id,
        nrp: mahasiswa.nrp,
        nip: slot.nip,
        bab: _selectedBab!,
        deskripsiBimbingan: _deskripsiController.text.trim(),
        fileUrl: fileUrl,
      );
      
      if (!success) {
        setState(() {
          _isLoading = false;
          _msg = 'Gagal mendaftar ke slot. Slot mungkin sudah penuh atau Anda sudah terdaftar.';
        });
        return;
      }
      
      setState(() {
        _isLoading = false;
        _msg = 'Berhasil mendaftar ke slot bimbingan!';
      });
      
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _msg = 'Gagal: $e';
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final slotDate = DateTime(date.year, date.month, date.day);
    if (slotDate == today) return 'Hari Ini';
    if (slotDate == tomorrow) return 'Besok';
    return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: buttercream,
      appBar: AppBar(
        title: Text('Pengajuan Bimbingan', style: TextStyle(color: buttercream)),
        backgroundColor: spicedApple,
        elevation: 0,
        iconTheme: IconThemeData(color: buttercream),
      ),
      body: FutureBuilder<SlotModel?>(
        future: _slotFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: apricotBrandy),
                  SizedBox(height: 16),
                  Text('Memuat data slot...', style: TextStyle(color: mochaMousse)),
                ],
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: spicedApple),
                  SizedBox(height: 24),
                  Text('Slot Tidak Ditemukan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cacaoNibs)),
                  SizedBox(height: 8),
                  Text('Slot yang Anda cari tidak tersedia', style: TextStyle(color: mochaMousse)),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back),
                    label: Text('Kembali'),
                    style: ElevatedButton.styleFrom(backgroundColor: apricotBrandy, foregroundColor: buttercream),
                  ),
                ],
              ),
            );
          }

          final s = snapshot.data!;

          return SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [spicedApple, apricotBrandy])),
                    child: Column(
                      children: [
                        Icon(Icons.edit_calendar, size: 48, color: buttercream),
                        SizedBox(height: 16),
                        Text('Form Pengajuan Bimbingan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: buttercream)),
                        SizedBox(height: 8),
                        Text('Lengkapi data untuk mendaftar ke slot ini', style: TextStyle(fontSize: 14, color: buttercream.withOpacity(0.9))),
                      ],
                    ),
                  ),

                  // Info Slot Card
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: cacaoNibs.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Slot Info Header
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [wheat, buttercream]),
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: apricotBrandy, size: 24),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Info Slot', style: TextStyle(fontSize: 12, color: mochaMousse)),
                                      Text(_formatDate(s.tanggalDateTime), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cacaoNibs)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: s.isFull ? spicedApple : (s.isUnlimited ? Colors.green : apricotBrandy),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (s.isUnlimited) Icon(Icons.all_inclusive, size: 14, color: Colors.white),
                                      if (s.isUnlimited) SizedBox(width: 4),
                                      Text(
                                        s.isUnlimited ? 'Tak Terbatas' : '${s.listPendaftar.length}/${s.kapasitas}',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Slot Details
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildDetailRow(Icons.access_time, 'Waktu', '${_formatTime(s.jamMulaiDateTime)} - ${_formatTime(s.jamSelesaiDateTime)}'),
                                SizedBox(height: 12),
                                _buildDetailRow(Icons.location_on, 'Lokasi', s.lokasi),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Form Bimbingan
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: cacaoNibs.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Title
                            Row(
                              children: [
                                Icon(Icons.assignment, color: apricotBrandy, size: 24),
                                SizedBox(width: 12),
                                Text('Detail Bimbingan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cacaoNibs)),
                              ],
                            ),
                            SizedBox(height: 20),

                            // Dropdown Bab
                            Text('Pilih Bab *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cacaoNibs)),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: buttercream.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: wheat, width: 1.5),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedBab,
                                decoration: InputDecoration(
                                  hintText: 'Pilih bab yang akan dibimbing',
                                  hintStyle: TextStyle(color: mochaMousse),
                                  prefixIcon: Icon(Icons.book, color: apricotBrandy),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                style: TextStyle(color: cacaoNibs, fontSize: 16),
                                dropdownColor: Colors.white,
                                items: _babList.map((bab) {
                                  return DropdownMenuItem<String>(
                                    value: bab,
                                    child: Text(bab, style: TextStyle(color: cacaoNibs)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedBab = value);
                                },
                                validator: (v) => v == null ? 'Pilih bab yang akan dibimbing' : null,
                              ),
                            ),
                            SizedBox(height: 20),

                            // Textarea Deskripsi
                            Text('Deskripsi Bimbingan *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cacaoNibs)),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: buttercream.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: wheat, width: 1.5),
                              ),
                              child: TextFormField(
                                controller: _deskripsiController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Jelaskan bagian/topik apa yang akan dibimbing...',
                                  hintStyle: TextStyle(color: mochaMousse),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(16),
                                ),
                                style: TextStyle(color: cacaoNibs, fontSize: 16),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Deskripsi bimbingan wajib diisi';
                                  }
                                  if (v.trim().length < 10) {
                                    return 'Deskripsi minimal 10 karakter';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 20),

                            // Upload File (Opsional)
                            Row(
                              children: [
                                Text('Upload File', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cacaoNibs)),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: wheat,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Opsional', style: TextStyle(fontSize: 11, color: cacaoNibs)),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            
                            // File Picker Area
                            if (_selectedFile == null) ...[
                              InkWell(
                                onTap: _pickFile,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: buttercream.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _fileError != null ? spicedApple : wheat,
                                      width: 1.5,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.cloud_upload_outlined, size: 48, color: mochaMousse),
                                      SizedBox(height: 12),
                                      Text('Tap untuk upload file', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cacaoNibs)),
                                      SizedBox(height: 4),
                                      Text('PDF, DOC, DOCX (Max 100 MB)', style: TextStyle(fontSize: 12, color: mochaMousse)),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Selected File Display
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withOpacity(0.3), width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _selectedFile!.extension == 'pdf' ? Icons.picture_as_pdf : Icons.description,
                                        color: Colors.green.shade700,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedFile!.name,
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cacaoNibs),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            _formatFileSize(_selectedFile!.size),
                                            style: TextStyle(fontSize: 12, color: mochaMousse),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _removeFile,
                                      icon: Icon(Icons.close, color: spicedApple),
                                      tooltip: 'Hapus file',
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // File Error Message
                            if (_fileError != null) ...[
                              SizedBox(height: 8),
                              Text(_fileError!, style: TextStyle(fontSize: 12, color: spicedApple)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Message
                  if (_msg.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _msg.contains('Berhasil') ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _msg.contains('Berhasil') ? Colors.green : Colors.red, width: 2),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _msg.contains('Berhasil') ? Icons.check_circle : Icons.error,
                              color: _msg.contains('Berhasil') ? Colors.green : Colors.red,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _msg,
                                style: TextStyle(
                                  color: _msg.contains('Berhasil') ? Colors.green.shade700 : Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Buttons
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: mochaMousse, width: 2),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Batal', style: TextStyle(color: mochaMousse, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading || _msg.contains('Berhasil') || s.isFull ? null : () => _confirm(s),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: apricotBrandy,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                            child: _isLoading
                                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    s.isFull ? 'Slot Penuh' : 'Ajukan Bimbingan',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: wheat, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: apricotBrandy, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: mochaMousse)),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cacaoNibs)),
            ],
          ),
        ),
      ],
    );
  }
}