import 'package:flutter/material.dart';
import '../model/slot_model.dart';
import '../util/app_colors.dart';

class KartuSlot extends StatelessWidget {
  final SlotModel slot;
  final VoidCallback? onTap;

  const KartuSlot({Key? key, required this.slot, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateStr = slot.tanggalDateTime.toIso8601String().split('T').first;
    final isFull = slot.isFull;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isFull ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cherry,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      slot.lokasi,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Peserta: ${slot.listPendaftar.length}/${slot.kapasitasInt}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              if (isFull)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cherry,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Penuh',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Daftar',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
