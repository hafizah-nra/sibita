import 'package:flutter/material.dart';
import '../../../config/restapi.dart';
import '../../../config/manajer_session.dart';
import '../../../model/slot_model.dart';

class SlotColors {
  static const Color buttercream = Color(0xFFEDE2D0);
  static const Color wheat = Color(0xFFE9D2A9);
  static const Color apricotBrandy = Color(0xFFBB6A57);
  static const Color mochaMousse = Color(0xFFA57865);
  static const Color cacaoNibs = Color(0xFF7B5747);
  static const Color spicedApple = Color(0xFF793937);
}

class TambahSlot extends StatefulWidget {
  @override
  _TambahSlotState createState() => _TambahSlotState();
}

class _TambahSlotState extends State<TambahSlot> {
  final _formKey = GlobalKey<FormState>();
  final _lokasi = TextEditingController();
  final _kapasitas = TextEditingController(text: '1');
  final _jumlahMinggu = TextEditingController(text: '4');
  
  TipeSlot _tipeSlot = TipeSlot.fleksibel;
  DateTime? _tanggal;
  HariSlot? _hariTetap;
  TimeOfDay? _mulai;
  TimeOfDay? _selesai;
  String _msg = '';
  bool _isLoading = false;
  bool _isUnlimited = true; // Default unlimited

  @override
  void dispose() {
    _lokasi.dispose();
    _kapasitas.dispose();
    _jumlahMinggu.dispose();
    super.dispose();
  }

  void _pickTanggal() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
    if (d != null) setState(() => _tanggal = d);
  }

  void _pickMulai() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _mulai ?? TimeOfDay.now(),
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
    if (t != null) setState(() => _mulai = t);
  }

  void _pickSelesai() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selesai ?? TimeOfDay.now(),
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
    if (t != null) setState(() => _selesai = t);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final d = ManajerSession.instance.dosen;
    if (d == null) {
      setState(() => _msg = 'Session tidak valid');
      return;
    }

    if (_mulai == null || _selesai == null) {
      setState(() => _msg = 'Lengkapi jam mulai dan selesai');
      return;
    }

    // Validasi berdasarkan tipe slot
    if (_tipeSlot == TipeSlot.fleksibel) {
      if (_tanggal == null) {
        setState(() => _msg = 'Pilih tanggal untuk slot fleksibel');
        return;
      }
    } else {
      if (_hariTetap == null) {
        setState(() => _msg = 'Pilih hari untuk slot tetap');
        return;
      }
    }

    // Validasi waktu
    final testDate = DateTime.now();
    final jamMulaiTest = DateTime(
      testDate.year,
      testDate.month,
      testDate.day,
      _mulai!.hour,
      _mulai!.minute,
    );
    final jamSelesaiTest = DateTime(
      testDate.year,
      testDate.month,
      testDate.day,
      _selesai!.hour,
      _selesai!.minute,
    );

    if (jamSelesaiTest.isBefore(jamMulaiTest) || jamSelesaiTest.isAtSameMomentAs(jamMulaiTest)) {
      setState(() => _msg = 'Jam selesai harus lebih dari jam mulai');
      return;
    }

    setState(() {
      _isLoading = true;
      _msg = '';
    });

    try {
      if (_tipeSlot == TipeSlot.fleksibel) {
        // Buat slot fleksibel (single)
        final jamMulai = DateTime(
          _tanggal!.year,
          _tanggal!.month,
          _tanggal!.day,
          _mulai!.hour,
          _mulai!.minute,
        );
        final jamSelesai = DateTime(
          _tanggal!.year,
          _tanggal!.month,
          _tanggal!.day,
          _selesai!.hour,
          _selesai!.minute,
        );

        final result = await RestApi.instance.createSlot(
          nip: d.nip,
          tanggal: _tanggal!,
          lokasi: _lokasi.text.trim(),
          kapasitas: _isUnlimited ? -1 : (int.tryParse(_kapasitas.text) ?? 1),
          jamMulai: jamMulai,
          jamSelesai: jamSelesai,
        );

        if (mounted) {
          setState(() {
            _msg = result != null ? 'Slot fleksibel berhasil dibuat!' : 'Gagal membuat slot';
            _isLoading = false;
          });
        }
      } else {
        // Buat slot tetap (recurring)
        final jumlahMinggu = int.tryParse(_jumlahMinggu.text) ?? 4;
        
        // Buat DateTime untuk jam mulai dan selesai
        final now = DateTime.now();
        final jamMulai = DateTime(now.year, now.month, now.day, _mulai!.hour, _mulai!.minute);
        final jamSelesai = DateTime(now.year, now.month, now.day, _selesai!.hour, _selesai!.minute);
        
        final slots = await RestApi.instance.createSlotTetap(
          nip: d.nip,
          hari: _hariTetap!,
          lokasi: _lokasi.text.trim(),
          kapasitas: _isUnlimited ? -1 : (int.tryParse(_kapasitas.text) ?? 1),
          jamMulai: jamMulai,
          jamSelesai: jamSelesai,
          jumlahMinggu: jumlahMinggu,
        );

        if (mounted) {
          setState(() {
            _msg = slots.isNotEmpty 
                ? 'Slot tetap berhasil dibuat! (${slots.length} slot untuk $jumlahMinggu minggu)'
                : 'Gagal membuat slot tetap';
            _isLoading = false;
          });
        }
      }

      await Future.delayed(Duration(seconds: 2));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _msg = 'Gagal membuat slot: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final hari = HariSlot.fromString(_getDayName(date.weekday)).nama;
    return '$hari, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'senin';
      case DateTime.tuesday: return 'selasa';
      case DateTime.wednesday: return 'rabu';
      case DateTime.thursday: return 'kamis';
      case DateTime.friday: return 'jumat';
      case DateTime.saturday: return 'sabtu';
      case DateTime.sunday: return 'minggu';
      default: return 'senin';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: SlotColors.cacaoNibs,
        letterSpacing: 0.3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SlotColors.buttercream,
      appBar: AppBar(
        title: Text(
          'Tambah Slot',
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      color: SlotColors.buttercream,
                      size: 48,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Buat Slot Baru',
                    style: TextStyle(
                      color: SlotColors.buttercream,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pilih tipe slot dan isi form di bawah',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SlotColors.buttercream.withOpacity(0.85),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Form Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tipe Slot Toggle
                    _buildSectionTitle('Tipe Slot'),
                    SizedBox(height: 12),
                    Container(
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
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _tipeSlot = TipeSlot.fleksibel),
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _tipeSlot == TipeSlot.fleksibel
                                      ? SlotColors.apricotBrandy
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event,
                                      color: _tipeSlot == TipeSlot.fleksibel
                                          ? SlotColors.buttercream
                                          : SlotColors.cacaoNibs,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Fleksibel',
                                      style: TextStyle(
                                        color: _tipeSlot == TipeSlot.fleksibel
                                            ? SlotColors.buttercream
                                            : SlotColors.cacaoNibs,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _tipeSlot = TipeSlot.tetap),
                              borderRadius: BorderRadius.horizontal(right: Radius.circular(14)),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _tipeSlot == TipeSlot.tetap
                                      ? SlotColors.mochaMousse
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.horizontal(right: Radius.circular(14)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.repeat,
                                      color: _tipeSlot == TipeSlot.tetap
                                          ? SlotColors.buttercream
                                          : SlotColors.cacaoNibs,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tetap',
                                      style: TextStyle(
                                        color: _tipeSlot == TipeSlot.tetap
                                            ? SlotColors.buttercream
                                            : SlotColors.cacaoNibs,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SlotColors.wheat.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: SlotColors.cacaoNibs,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _tipeSlot == TipeSlot.fleksibel
                                  ? 'Slot untuk tanggal tertentu (input manual setiap kali)'
                                  : 'Slot berulang setiap minggu pada hari yang sama',
                              style: TextStyle(
                                fontSize: 11,
                                color: SlotColors.cacaoNibs.withOpacity(0.8),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Lokasi Field
                    _buildSectionTitle('Lokasi Konsultasi'),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _lokasi,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Ruang Dosen 301',
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: SlotColors.apricotBrandy,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: SlotColors.wheat, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: SlotColors.apricotBrandy, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: SlotColors.spicedApple, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Lokasi harus diisi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Kapasitas Field dengan Toggle Unlimited
                    _buildSectionTitle('Kapasitas Mahasiswa'),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: SlotColors.wheat, width: 2),
                        borderRadius: BorderRadius.circular(16),
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
                              controller: _kapasitas,
                              decoration: InputDecoration(
                                hintText: 'Jumlah mahasiswa maksimal',
                                prefixIcon: Icon(
                                  Icons.people_outline,
                                  color: SlotColors.mochaMousse,
                                ),
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
                                filled: true,
                                fillColor: SlotColors.buttercream.withOpacity(0.5),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (_isUnlimited) return null; // Skip validation if unlimited
                                if (value == null || value.isEmpty) {
                                  return 'Kapasitas harus diisi';
                                }
                                final n = int.tryParse(value);
                                if (n == null || n < 1) {
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
                                        ? 'Semua mahasiswa dapat mendaftar tanpa batasan jumlah'
                                        : 'Maksimal ${_kapasitas.text.isEmpty ? "1" : _kapasitas.text} mahasiswa dapat mendaftar',
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
                    SizedBox(height: 24),

                    // Conditional: Tanggal (Fleksibel) atau Hari (Tetap)
                    if (_tipeSlot == TipeSlot.fleksibel) ...[
                      _buildSectionTitle('Pilih Tanggal'),
                      SizedBox(height: 12),
                      InkWell(
                        onTap: _pickTanggal,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: SlotColors.wheat, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: SlotColors.wheat,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.calendar_today,
                                  color: SlotColors.cacaoNibs,
                                  size: 22,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tanggal & Hari',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: SlotColors.cacaoNibs.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _tanggal == null
                                          ? 'Pilih Tanggal'
                                          : _formatDate(_tanggal!),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _tanggal == null
                                            ? SlotColors.cacaoNibs.withOpacity(0.5)
                                            : SlotColors.cacaoNibs,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: SlotColors.apricotBrandy,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      _buildSectionTitle('Pilih Hari (Recurring)'),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: SlotColors.wheat, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<HariSlot>(
                            value: _hariTetap,
                            isExpanded: true,
                            hint: Text(
                              'Pilih Hari',
                              style: TextStyle(color: SlotColors.cacaoNibs.withOpacity(0.5)),
                            ),
                            icon: Icon(Icons.arrow_drop_down, color: SlotColors.apricotBrandy),
                            items: HariSlot.values.map((hari) {
                              return DropdownMenuItem(
                                value: hari,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month,
                                      size: 20,
                                      color: SlotColors.mochaMousse,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      hari.nama,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: SlotColors.cacaoNibs,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _hariTetap = value);
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildSectionTitle('Durasi Slot Tetap'),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _jumlahMinggu,
                        decoration: InputDecoration(
                          hintText: 'Jumlah minggu ke depan',
                          prefixIcon: Icon(
                            Icons.date_range,
                            color: SlotColors.mochaMousse,
                          ),
                          suffixText: 'minggu',
                          suffixStyle: TextStyle(
                            color: SlotColors.cacaoNibs.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: SlotColors.wheat, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: SlotColors.mochaMousse, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: SlotColors.spicedApple, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Durasi harus diisi';
                          }
                          final n = int.tryParse(value);
                          if (n == null || n < 1) {
                            return 'Minimal 1 minggu';
                          }
                          if (n > 52) {
                            return 'Maksimal 52 minggu';
                          }
                          return null;
                        },
                      ),
                    ],
                    SizedBox(height: 24),

                    // Waktu Section
                    _buildSectionTitle('Pilih Waktu'),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickMulai,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: SlotColors.wheat, width: 2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: SlotColors.apricotBrandy.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.access_time,
                                      size: 20,
                                      color: SlotColors.apricotBrandy,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Mulai',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: SlotColors.cacaoNibs.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _mulai == null ? '--:--' : _mulai!.format(context),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _mulai == null
                                          ? SlotColors.cacaoNibs.withOpacity(0.3)
                                          : SlotColors.cacaoNibs,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickSelesai,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: SlotColors.wheat, width: 2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: SlotColors.mochaMousse.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.access_time,
                                      size: 20,
                                      color: SlotColors.mochaMousse,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Selesai',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: SlotColors.cacaoNibs.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _selesai == null ? '--:--' : _selesai!.format(context),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _selesai == null
                                          ? SlotColors.cacaoNibs.withOpacity(0.3)
                                          : SlotColors.cacaoNibs,
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

                    // Message
                    if (_msg.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _msg.contains('Gagal') || _msg.contains('harus')
                              ? SlotColors.spicedApple.withOpacity(0.15)
                              : SlotColors.apricotBrandy.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _msg.contains('Gagal') || _msg.contains('harus')
                                ? SlotColors.spicedApple
                                : SlotColors.apricotBrandy,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _msg.contains('Gagal') || _msg.contains('harus')
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline,
                              color: _msg.contains('Gagal') || _msg.contains('harus')
                                  ? SlotColors.spicedApple
                                  : SlotColors.apricotBrandy,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _msg,
                                style: TextStyle(
                                  color: SlotColors.cacaoNibs,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SlotColors.spicedApple,
                        foregroundColor: SlotColors.buttercream,
                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: SlotColors.spicedApple.withOpacity(0.4),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  SlotColors.buttercream,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_outlined, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Simpan Slot',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}