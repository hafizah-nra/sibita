import 'package:flutter/material.dart';
import '../../../config/restapi.dart';
import '../../../config/manajer_session.dart';
import '../../../model/slot_model.dart';
import 'package:intl/intl.dart';

class DaftarSlotTersedia extends StatefulWidget {
  @override
  _DaftarSlotTersediaState createState() => _DaftarSlotTersediaState();
}

class _DaftarSlotTersediaState extends State<DaftarSlotTersedia> {
  final Color buttercream = Color(0xFFEDE2D0);
  final Color wheat = Color(0xFFE9D2A9);
  final Color apricotBrandy = Color(0xFFBB6A57);
  final Color mochaMousse = Color(0xFFA57865);
  final Color cacaoNibs = Color(0xFF7B5747);
  final Color spicedApple = Color(0xFF793937);

  String _selectedFilter = 'Semua';
  final List<String> _filterOptions = ['Semua', 'Hari Ini', 'Minggu Ini', 'Tersedia'];
  late Future<List<SlotModel>> _slotsFuture;
  String? _nipPembimbing;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  void _loadSlots() {
    // Ambil NIP pembimbing dari mahasiswa yang login
    final mahasiswa = ManajerSession.instance.mahasiswa;
    _nipPembimbing = mahasiswa?.nip;
    
    // Jika mahasiswa sudah punya pembimbing, tampilkan slot pembimbing saja
    // Jika belum punya pembimbing, tidak tampilkan slot (harus punya pembimbing dulu)
    if (_nipPembimbing != null && _nipPembimbing!.isNotEmpty && _nipPembimbing != '-') {
      _slotsFuture = RestApi.instance.semuaSlotUntukDosen(_nipPembimbing!);
    } else {
      // Mahasiswa belum punya pembimbing, kembalikan list kosong
      _slotsFuture = Future.value([]);
    }
  }

  void _refreshData() {
    setState(() => _loadSlots());
  }

  // Gunakan method dari model untuk konsistensi
  bool _isSlotExpired(SlotModel slot) => slot.isExpired;

  bool _canRegister(SlotModel slot) => slot.isAvailable;

  List<SlotModel> _getFilteredSlots(List<SlotModel> slots) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Hari Ini':
        return slots.where((s) {
          final slotDate = s.tanggalDateTime;
          return slotDate.year == now.year && slotDate.month == now.month && slotDate.day == now.day;
        }).toList();
      case 'Minggu Ini':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(Duration(days: 6));
        return slots.where((s) {
          final slotDate = s.tanggalDateTime;
          return slotDate.isAfter(weekStart.subtract(Duration(days: 1))) && slotDate.isBefore(weekEnd.add(Duration(days: 1)));
        }).toList();
      case 'Tersedia':
        return slots.where((s) => _canRegister(s)).toList();
      default:
        return slots;
    }
  }

  String _formatDate(DateTime date, {bool isExpired = false}) {
    if (isExpired) return 'Sudah Lewat';
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
        title: Text('Slot Bimbingan', style: TextStyle(color: buttercream)),
        backgroundColor: spicedApple,
        elevation: 0,
        iconTheme: IconThemeData(color: buttercream),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: buttercream), onPressed: _refreshData, tooltip: 'Refresh'),
        ],
      ),
      body: FutureBuilder<List<SlotModel>>(
        future: _slotsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: apricotBrandy),
                  SizedBox(height: 16),
                  Text('Memuat slot...', style: TextStyle(color: mochaMousse)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: spicedApple),
                  SizedBox(height: 16),
                  Text('Gagal memuat data', style: TextStyle(color: spicedApple, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Periksa koneksi internet Anda', style: TextStyle(color: mochaMousse)),
                  SizedBox(height: 16),
                  ElevatedButton(onPressed: _refreshData, style: ElevatedButton.styleFrom(backgroundColor: apricotBrandy), child: Text('Coba Lagi')),
                ],
              ),
            );
          }

          final allSlots = snapshot.data ?? [];
          final filteredSlots = _getFilteredSlots(allSlots);

          return Column(
            children: [
              // Header Stats
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [spicedApple, apricotBrandy])),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(Icons.event_available, 'Total', allSlots.length.toString()),
                    _buildStatCard(Icons.check_circle_outline, 'Tersedia', allSlots.where((s) => _canRegister(s)).length.toString()),
                    _buildStatCard(Icons.block, 'Penuh', allSlots.where((s) => !_canRegister(s)).length.toString()),
                  ],
                ),
              ),
              
              // Filter Chips
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter, style: TextStyle(color: isSelected ? buttercream : cacaoNibs, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                          backgroundColor: wheat,
                          selectedColor: apricotBrandy,
                          checkmarkColor: buttercream,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Slot List
              Expanded(
                child: filteredSlots.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: filteredSlots.length,
                        itemBuilder: (context, index) => _buildSlotCard(context, filteredSlots[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(color: buttercream.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: buttercream, size: 28),
        ),
        SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: buttercream)),
        Text(label, style: TextStyle(fontSize: 12, color: buttercream.withOpacity(0.9))),
      ],
    );
  }

  Widget _buildSlotCard(BuildContext context, SlotModel slot) {
    final isExpired = _isSlotExpired(slot);
    final canRegister = _canRegister(slot);
    final isUnlimited = slot.isUnlimited;
    final capacityPercentage = (!isUnlimited && slot.kapasitasInt > 0) 
        ? (slot.listPendaftar.length / slot.kapasitasInt * 100).round() 
        : 0;
    final isAlmostFull = !isUnlimited && capacityPercentage >= 80 && !slot.isFull;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: cacaoNibs.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [wheat, buttercream]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: isExpired ? Colors.grey : apricotBrandy, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.calendar_today, color: buttercream, size: 20)),
                SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate(slot.tanggalDateTime, isExpired: isExpired), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isExpired ? Colors.grey : cacaoNibs)),
                    if (isExpired) Text(DateFormat('dd MMM yyyy', 'id_ID').format(slot.tanggalDateTime), style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )),
                if (isExpired)
                  Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(20)), child: Text('Lewat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))
                else if (slot.isFull)
                  Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: spicedApple, borderRadius: BorderRadius.circular(20)), child: Text('Penuh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))
                else if (isAlmostFull)
                  Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: apricotBrandy, borderRadius: BorderRadius.circular(20)), child: Text('Hampir Penuh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))
                else if (isUnlimited)
                  Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.all_inclusive, color: Colors.white, size: 14), SizedBox(width: 4), Text('Tersedia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]))
                else
                  Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)), child: Text('Tersedia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(children: [Icon(Icons.access_time, color: apricotBrandy, size: 20), SizedBox(width: 8), Text('${_formatTime(slot.jamMulaiDateTime)} - ${_formatTime(slot.jamSelesaiDateTime)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cacaoNibs))]),
                SizedBox(height: 12),
                Row(children: [Icon(Icons.location_on, color: apricotBrandy, size: 20), SizedBox(width: 8), Expanded(child: Text(slot.lokasi, style: TextStyle(fontSize: 14, color: mochaMousse)))]),
                SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Kapasitas', style: TextStyle(fontSize: 12, color: mochaMousse)), 
                  Row(
                    children: [
                      if (isUnlimited) Icon(Icons.all_inclusive, size: 14, color: cacaoNibs),
                      SizedBox(width: 4),
                      Text(isUnlimited ? 'Tak Terbatas' : slot.kapasitasDisplay, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cacaoNibs)),
                    ],
                  ),
                ]),
                SizedBox(height: 8),
                if (isUnlimited)
                  // Untuk unlimited, tampilkan bar hijau penuh
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: 1.0, backgroundColor: wheat, valueColor: AlwaysStoppedAnimation<Color>(Colors.green.withOpacity(0.5)), minHeight: 8))
                else
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: slot.kapasitasInt > 0 ? slot.listPendaftar.length / slot.kapasitasInt : 0, backgroundColor: wheat, valueColor: AlwaysStoppedAnimation<Color>(slot.isFull ? spicedApple : mochaMousse), minHeight: 8)),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: canRegister
                      ? ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.pushNamed(context, '/mahasiswa/slot/daftar', arguments: slot.id);
                            if (result == true) _refreshData();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: apricotBrandy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text('Daftar Sekarang', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        )
                      : Container(
                          decoration: BoxDecoration(color: wheat, borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text(isExpired ? 'Sudah Lewat' : 'Slot Penuh', style: TextStyle(color: mochaMousse, fontWeight: FontWeight.bold))),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    // Cek apakah mahasiswa belum punya pembimbing
    final belumPunyaPembimbing = _nipPembimbing == null || _nipPembimbing!.isEmpty || _nipPembimbing == '-';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            belumPunyaPembimbing ? Icons.person_search : Icons.event_busy, 
            size: 64, 
            color: mochaMousse
          ),
          SizedBox(height: 24),
          Text(
            belumPunyaPembimbing 
                ? 'Belum Ada Pembimbing' 
                : 'Tidak Ada Slot Tersedia', 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cacaoNibs)
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              belumPunyaPembimbing 
                  ? 'Anda harus memiliki pembimbing terlebih dahulu sebelum dapat melihat slot bimbingan'
                  : 'Pembimbing belum membuat slot atau coba periksa lagi nanti', 
              style: TextStyle(color: mochaMousse),
              textAlign: TextAlign.center,
            ),
          ),
          if (belumPunyaPembimbing) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/mahasiswa/permintaan/form'),
              icon: Icon(Icons.add),
              label: Text('Ajukan Pembimbing'),
              style: ElevatedButton.styleFrom(backgroundColor: apricotBrandy, foregroundColor: buttercream),
            ),
          ],
        ],
      ),
    );
  }
}