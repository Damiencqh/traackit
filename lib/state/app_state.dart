import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/photo.dart';
import '../models/project.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

// ─── Services ──────────────────────────────────────────────────

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ─── User preferences (name, lock, reminders) ──────────────────

class UserPrefs {
  final String name;
  final bool lockEnabled;
  final String reminderTime; // "HH:mm"

  const UserPrefs({
    required this.name,
    required this.lockEnabled,
    required this.reminderTime,
  });

  UserPrefs copyWith({String? name, bool? lockEnabled, String? reminderTime}) =>
      UserPrefs(
        name: name ?? this.name,
        lockEnabled: lockEnabled ?? this.lockEnabled,
        reminderTime: reminderTime ?? this.reminderTime,
      );
}

class UserPrefsNotifier extends AsyncNotifier<UserPrefs> {
  static const _kName = 'user.name';
  static const _kLock = 'user.lockEnabled';
  static const _kReminder = 'user.reminderTime';

  @override
  Future<UserPrefs> build() async {
    final sp = await SharedPreferences.getInstance();
    return UserPrefs(
      name: sp.getString(_kName) ?? 'there',
      lockEnabled: sp.getBool(_kLock) ?? false,
      reminderTime: sp.getString(_kReminder) ?? '10:00',
    );
  }

  Future<void> setName(String name) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kName, name);
    state = AsyncData((state.value ?? await build()).copyWith(name: name));
  }

  Future<void> setLockEnabled(bool enabled) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kLock, enabled);
    state = AsyncData(
        (state.value ?? await build()).copyWith(lockEnabled: enabled));
  }

  Future<void> setReminderTime(String time) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kReminder, time);
    state =
        AsyncData((state.value ?? await build()).copyWith(reminderTime: time));

    // Reschedule the daily reminder for the new time.
    await ref.read(notificationServiceProvider).scheduleDailyReminder(time);
  }
}

final userPrefsProvider =
    AsyncNotifierProvider<UserPrefsNotifier, UserPrefs>(UserPrefsNotifier.new);

// ─── Projects ──────────────────────────────────────────────────

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    final storage = ref.read(storageServiceProvider);
    return storage.loadProjects();
  }

  Future<void> addProject(Project project) async {
    final current = state.value ?? [];
    final updated = [...current, project];
    await ref.read(storageServiceProvider).saveProjects(updated);
    state = AsyncData(updated);
  }

  Future<void> renameProject(String id, String newName) async {
    final current = state.value ?? [];
    final updated = [
      for (final p in current)
        if (p.id == id) p.copyWith(name: newName) else p
    ];
    await ref.read(storageServiceProvider).saveProjects(updated);
    state = AsyncData(updated);
  }

  Future<void> addPhotoToProject(String projectId, Photo photo) async {
    final current = state.value ?? [];
    final updated = [
      for (final p in current)
        if (p.id == projectId) p.copyWith(photos: [...p.photos, photo]) else p
    ];
    await ref.read(storageServiceProvider).saveProjects(updated);
    state = AsyncData(updated);
  }

  Future<void> deleteProject(String id) async {
    final current = state.value ?? [];
    final project = current.firstWhere(
      (p) => p.id == id,
      orElse: () => throw StateError('Project not found'),
    );

    // Best-effort: delete photo files from disk.
    final storage = ref.read(storageServiceProvider);
    for (final photo in project.photos) {
      try {
        await storage.deletePhotoFile(photo.filePath);
      } catch (_) {
        // missing file shouldn't block project deletion
      }
    }

    final updated = current.where((p) => p.id != id).toList();
    await storage.saveProjects(updated);
    state = AsyncData(updated);
  }
}

final projectsProvider = AsyncNotifierProvider<ProjectsNotifier, List<Project>>(
    ProjectsNotifier.new);
