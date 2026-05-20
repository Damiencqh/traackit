import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.paper,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accent,
          onPrimary: AppColors.paper,
          surface: AppColors.card,
          onSurface: AppColors.ink,
          surfaceContainerHighest: AppColors.paperWarm,
        ),
        textTheme: TextTheme(
          headlineLarge: AppText.display(size: 38),
          headlineMedium: AppText.display(size: 28),
          titleLarge: AppText.serifBody(size: 18),
          bodyLarge: AppText.ui(size: 15),
          bodyMedium: AppText.ui(size: 13.5),
          labelMedium: AppText.eyebrow(),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.paper,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: AppColors.ink),
          titleTextStyle: AppText.serifBody(size: 18),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.lineSoft),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.line,
          thickness: 1,
          space: 1,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          elevation: 6,
          shape: CircleBorder(),
        ),
      );
}
