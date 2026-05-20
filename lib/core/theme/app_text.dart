import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography helpers.
///
/// Fraunces (italic) is the editorial serif — used for the greeting,
/// project names, big numbers, and decorative moments.
/// Geist is the workhorse sans for UI text. Until you bundle the Geist
/// font files (see README), we fall back to GoogleFonts.inter which is
/// the closest free analogue.
class AppText {
  AppText._();

  static TextStyle display({
    double size = 32,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w300,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontStyle: FontStyle.italic,
        fontWeight: weight,
        color: color,
        height: 1.0,
        letterSpacing: -0.025 * size,
      );

  static TextStyle serifBody({
    double size = 16,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
    bool italic = true,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        fontWeight: weight,
        color: color,
        height: 1.2,
      );

  /// Replace .inter() with .geistVariable() once you add it to assets.
  static TextStyle ui({
    double size = 14,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle eyebrow({
    Color color = AppColors.inkMuted,
    double size = 11,
  }) =>
      ui(
        size: size,
        color: color,
        weight: FontWeight.w500,
        letterSpacing: size * 0.18,
      );

  static TextStyle button() => ui(
        size: 10.5,
        color: AppColors.accent,
        weight: FontWeight.w600,
        letterSpacing: 1.0,
      );
}
