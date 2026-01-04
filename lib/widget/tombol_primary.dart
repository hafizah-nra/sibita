import 'package:flutter/material.dart';
import '../util/app_colors.dart';

class TombolPrimary extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isOutlined;

  const TombolPrimary({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.orange, width: 2),
          foregroundColor: AppColors.orange,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }
}
