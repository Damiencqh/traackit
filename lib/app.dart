import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'widgets/app_lock_gate.dart';

class TraackitApp extends ConsumerWidget {
  const TraackitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Traackit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // builder wraps the navigator, so the lock sits above every route.
      builder: (context, child) =>
          AppLockGate(child: child ?? const SizedBox.shrink()),
      home: const HomeScreen(),
    );
  }
}
