import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get headline => GoogleFonts.manrope(
        color: AppColors.primary,
        fontWeight: FontWeight.w800,
        fontSize: 24,
        letterSpacing: 9.6, // 0.4em of 24px is 9.6
      );

  static TextStyle get tagline => GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        letterSpacing: 2.1, // 0.15em of 14px is 2.1
        fontStyle: FontStyle.italic,
      );
}
