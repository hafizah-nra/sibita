import 'package:flutter/material.dart';
import '../model/permintaan_model.dart';
import '../util/app_colors.dart';
import 'badge_status.dart';

class KartuPermintaan extends StatelessWidget {
  final PermintaanModel permintaan;
  final VoidCallback? onTap;

  const KartuPermintaan({Key? key, required this.permintaan, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      permintaan.judul,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cherry,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  BadgeStatus(
                    text: permintaan.status.toString().split('.').last,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Bidang: ${permintaan.bidang}',
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
