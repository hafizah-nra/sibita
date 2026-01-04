import 'package:flutter/material.dart';
import '../util/app_colors.dart';

class BadgeStatus extends StatelessWidget {
  final String text;
  final Color? color;

  const BadgeStatus({Key? key, required this.text, this.color})
    : super(key: key);

  Color _getStatusColor() {
    if (color != null) return color!;

    final lowerText = text.toLowerCase();
    if (lowerText.contains('terima') || lowerText.contains('diterima')) {
      return Colors.green;
    } else if (lowerText.contains('tolak') || lowerText.contains('ditolak')) {
      return AppColors.cherry;
    } else if (lowerText.contains('pending') ||
        lowerText.contains('menunggu')) {
      return AppColors.cream2;
    }
    return AppColors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final textColor = statusColor == AppColors.cream2
        ? AppColors.cherry
        : Colors.white;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
