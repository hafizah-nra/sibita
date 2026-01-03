import 'package:flutter/material.dart';
import '../../../config/restapi.dart';
import '../../../config/manajer_session.dart';

// Color Palette
class SlotColors {
  static const Color buttercream = Color(0xFFEDE2D0);
  static const Color wheat = Color(0xFFE9D2A9);
  static const Color apricotBrandy = Color(0xFFBB6A57);
  static const Color mochaMousse = Color(0xFFA57865);
  static const Color cacaoNibs = Color(0xFF7B5747);
  static const Color spicedApple = Color(0xFF793937);
}

class EditSlot extends StatefulWidget {
  const EditSlot({Key? key}) : super(key: key);

  @override
  _EditSlotState createState() => _EditSlotState();
}

class _EditSlotState extends State<EditSlot> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _lokasiController;
  late TextEditingController _kapasitasController;
  
  DateTime? _selectedDate;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUnlimited = false;
  String? _slotId;

  @override
  void initState() {
    super.initState();
    _lokasiController = TextEditingController();
    _kapasitasController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ambil slotId dari route arguments
    if (_slotId == null) {
      _slotId = ModalRoute.of(context)?.settings.arguments as String?;
      if (_slotId != null) {
        _loadSlotData();
      }
    }
  }

  Future<void> _loadSlotData() async {
    if (_slotId == null) return;
    
    try {
      final slot = await RestApi.instance.cariSlotById(_slotId!);
      if (slot != null && mounted) {
        setState(() {
          _lokasiController.text = slot.lokasi;
          _isUnlimited = slot.isUnlimited;
          _kapasitasController.text = slot.isUnlimited ? '1' : slot.kapasitas;
          _selectedDate = slot.tanggalDateTime;
          _jamMulai = TimeOfDay(hour: slot.jamMulaiDateTime.hour, minute: slot.jamMulaiDateTime.minute);
          _jamSelesai = TimeOfDay(hour: slot.jamSelesaiDateTime.hour, minute: slot.jamSelesaiDateTime.minute);
          _isLoading = false;
        });
      } else {
        // Jika slot tidak ditemukan
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorSnackbar('Slot tidak ditemukan');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar('Gagal memuat data slot');
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _lokasiController.dispose();
    _kapasitasController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: SlotColors.spicedApple,
              onPrimary: SlotColors.buttercream,
              surface: SlotColors.buttercream,
              onSurface: SlotColors.cacaoNibs,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pilihWaktu(bool isMulai) async {
    final initialTime = isMulai 
        ? (_jamMulai ?? TimeOfDay.now())
        : (_jamSelesai ?? TimeOfDay.now());
    
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: SlotColors.spicedApple,
              onPrimary: SlotColors.buttercream,
              surface: SlotColors.buttercream,
              onSurface: SlotColors.cacaoNibs,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _jamMulai = picked;
        } else {
          _jamSelesai = picked;
        }
      });
    }
  }

  Future<void> _simpanPerubahan() async {
    if (_slotId == null) return;
    
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        _showErrorSnackbar('Pilih tanggal terlebih dahulu');
        return;
      }
      if (_jamMulai == null) {
        _showErrorSnackbar('Pilih jam mulai terlebih dahulu');
        return;
      }
      if (_jamSelesai == null) {
        _showErrorSnackbar('Pilih jam selesai terlebih dahulu');
        return;
      }

      final jamMulaiDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _jamMulai!.hour,
        _jamMulai!.minute,
      );

      final jamSelesaiDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _jamSelesai!.hour,
        _jamSelesai!.minute,
      );

      if (jamSelesaiDateTime.isBefore(jamMulaiDateTime) || 
          jamSelesaiDateTime.isAtSameMomentAs(jamMulaiDateTime)) {
        _showErrorSnackbar('Jam selesai harus setelah jam mulai');
        return;
      }

      final d = ManajerSession.instance.dosen;
      if (d == null) {
        _showErrorSnackbar('Tidak ada dosen aktif');
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final sukses = await RestApi.instance.editSlot(
          id: _slotId!,
          tanggal: _selectedDate!,
          jamMulai: jamMulaiDateTime,
          jamSelesai: jamSelesaiDateTime,
          lokasi: _lokasiController.text,
          kapasitas: _isUnlimited ? -1 : int.parse(_kapasitasController.text),
        );

        if (mounted) {
          setState(() {
            _isSaving = false;
          });

          if (sukses) {
            _showSuccessDialog();
          } else {
            _showErrorSnackbar('Gagal mengubah slot. Slot mungkin sudah ada pendaftar.');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          _showErrorSnackbar('Terjadi kesalahan: $e');
        }
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: SlotColors.spicedApple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: SlotColors.buttercream,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 64,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Berhasil!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: SlotColors.cacaoNibs,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Slot konsultasi berhasil diperbarui',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: SlotColors.cacaoNibs.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Back to list with result
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SlotColors.spicedApple,
                  foregroundColor: SlotColors.buttercream,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Kembali',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: SlotColors.buttercream,
        appBar: AppBar(
          title: Text(
            'Edit Slot',
            style: TextStyle(
              color: SlotColors.buttercream,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: SlotColors.spicedApple,
          elevation: 0,
          iconTheme: IconThemeData(color: SlotColors.buttercream),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: SlotColors.spicedApple,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: SlotColors.buttercream,
      appBar: AppBar(
        title: Text(
          'Edit Slot',
          style: TextStyle(
            color: SlotColors.buttercream,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: SlotColors.spicedApple,
        elevation: 0,
        iconTheme: IconThemeData(color: SlotColors.buttercream),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    SlotColors.spicedApple,
                    SlotColors.apricotBrandy,
                    SlotColors.mochaMousse,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: SlotColors.spicedApple.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.edit_calendar_rounded,
                      color: SlotColors.buttercream,
                      size: 48,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Perbarui Slot',
                    style: TextStyle(
                      color: SlotColors.buttercream,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Edit detail slot konsultasi Anda',
                    style: TextStyle(
                      color: SlotColors.buttercream.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Form Section
            Padding(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tanggal
                    _buildSectionTitle('Tanggal Konsultasi'),
                    SizedBox(height: 12),
                    InkWell(
                      onTap: _pilihTanggal,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: SlotColors.wheat,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: SlotColors.apricotBrandy.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                color: SlotColors.apricotBrandy,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pilih Tanggal',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: SlotColors.cacaoNibs.withOpacity(0.6),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _selectedDate != null
                                        ? _formatDate(_selectedDate!)
                                        : 'Belum dipilih',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: SlotColors.cacaoNibs,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: SlotColors.wheat,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Waktu
                    _buildSectionTitle('Waktu Konsultasi'),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pilihWaktu(true),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: SlotColors.wheat,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        color: SlotColors.mochaMousse,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Jam Mulai',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: SlotColors.cacaoNibs.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _jamMulai != null
                                        ? _formatTime(_jamMulai!)
                                        : '--:--',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: SlotColors.cacaoNibs,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pilihWaktu(false),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: SlotColors.wheat,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        color: SlotColors.mochaMousse,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Jam Selesai',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: SlotColors.cacaoNibs.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _jamSelesai != null
                                        ? _formatTime(_jamSelesai!)
                                        : '--:--',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: SlotColors.cacaoNibs,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Lokasi
                    _buildSectionTitle('Lokasi'),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _lokasiController,
                      style: TextStyle(
                        color: SlotColors.cacaoNibs,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Contoh: Ruang Dosen 301',
                        hintStyle: TextStyle(
                          color: SlotColors.cacaoNibs.withOpacity(0.4),
                        ),
                        prefixIcon: Container(
                          margin: EdgeInsets.all(12),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SlotColors.apricotBrandy.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: SlotColors.apricotBrandy,
                            size: 20,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: SlotColors.wheat,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: SlotColors.wheat,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: SlotColors.spicedApple,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: SlotColors.spicedApple,
                            width: 2,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: SlotColors.spicedApple,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lokasi tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 24),

                    // Kapasitas dengan Toggle Unlimited
                    _buildSectionTitle('Kapasitas'),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: SlotColors.wheat, width: 2),
                      ),
                      child: Column(
                        children: [
                          // Toggle Unlimited
                          Row(
                            children: [
                              Icon(
                                Icons.all_inclusive,
                                color: _isUnlimited ? SlotColors.apricotBrandy : SlotColors.mochaMousse,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tanpa Batas (Unlimited)',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: SlotColors.cacaoNibs,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _isUnlimited,
                                onChanged: (value) {
                                  setState(() => _isUnlimited = value);
                                },
                                activeColor: SlotColors.apricotBrandy,
                                activeTrackColor: SlotColors.apricotBrandy.withOpacity(0.3),
                              ),
                            ],
                          ),
                          // Input Kapasitas (hanya tampil jika tidak unlimited)
                          if (!_isUnlimited) ...[
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _kapasitasController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: SlotColors.cacaoNibs,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Jumlah maksimal mahasiswa',
                                hintStyle: TextStyle(
                                  color: SlotColors.cacaoNibs.withOpacity(0.4),
                                ),
                                prefixIcon: Icon(
                                  Icons.people_rounded,
                                  color: SlotColors.mochaMousse,
                                ),
                                filled: true,
                                fillColor: SlotColors.buttercream.withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: SlotColors.wheat, width: 2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: SlotColors.mochaMousse, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: SlotColors.spicedApple, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (_isUnlimited) return null;
                                if (value == null || value.isEmpty) {
                                  return 'Kapasitas tidak boleh kosong';
                                }
                                final kapasitas = int.tryParse(value);
                                if (kapasitas == null || kapasitas < 1) {
                                  return 'Kapasitas minimal 1';
                                }
                                return null;
                              },
                            ),
                          ],
                          // Info text
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: SlotColors.wheat.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: SlotColors.cacaoNibs,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isUnlimited
                                        ? 'Semua mahasiswa dapat mendaftar tanpa batasan'
                                        : 'Maksimal ${_kapasitasController.text.isEmpty ? "1" : _kapasitasController.text} mahasiswa',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: SlotColors.cacaoNibs.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),

                    // Simpan Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _simpanPerubahan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SlotColors.spicedApple,
                          foregroundColor: SlotColors.buttercream,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: SlotColors.spicedApple.withOpacity(0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isSaving)
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: SlotColors.buttercream,
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Icon(Icons.save_rounded, size: 24),
                            SizedBox(width: 12),
                            Text(
                              _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: SlotColors.spicedApple,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: SlotColors.cacaoNibs,
          ),
        ),
      ],
    );
  }
}