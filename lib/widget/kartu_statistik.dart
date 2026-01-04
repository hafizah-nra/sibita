import 'package:flutter/material.dart';
import '../util/app_colors.dart';

class KartuStatistik extends StatelessWidget {
  final String judul;
  final int nilai;
  final Color? backgroundColor;
  final Color? textColor;

  const KartuStatistik({
    Key? key,
    required this.judul,
    required this.nilai,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.orange;
    final textCol = textColor ?? Colors.white;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgColor, bgColor.withOpacity(0.8)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                judul,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textCol,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '$nilai',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
