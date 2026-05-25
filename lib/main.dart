import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise notifications early so scheduled reminders survive app restart.
  await NotificationService().init();

  runApp(const ProviderScope(child: TraackitApp()));
}
