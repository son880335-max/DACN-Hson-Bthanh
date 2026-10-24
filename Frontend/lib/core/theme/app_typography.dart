import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Hệ thống Typography theo DESIGN.md: Font Be Vietnam Pro
/// Quy tắc: Chữ nội dung 18sp, chữ phụ tối thiểu 16sp, nhãn/nút 17sp (600)
class AppTypography {
  static TextStyle pageTitle = GoogleFonts.beVietnamPro(
    fontSize: 26,
    height: 34 / 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle sectionTitle = GoogleFonts.beVietnamPro(
    fontSize: 21,
    height: 30 / 21,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle cardTitle = GoogleFonts.beVietnamPro(
    fontSize: 19,
    height: 26 / 19,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle body = GoogleFonts.beVietnamPro(
    fontSize: 18,
    height: 28 / 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.beVietnamPro(
    fontSize: 18,
    height: 28 / 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle button = GoogleFonts.beVietnamPro(
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
  );

  static TextStyle secondary = GoogleFonts.beVietnamPro(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle secondaryMedium = GoogleFonts.beVietnamPro(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static TextStyle chip = GoogleFonts.beVietnamPro(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
  );
}
