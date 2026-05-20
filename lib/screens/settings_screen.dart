import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../state/app_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPrefsProvider).value;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings.', style: AppText.display(size: 36)),
              const SizedBox(height: 26),
              _GroupLabel('YOU'),
              _SettingsCard(children: [
                _Row(
                  label: 'Name',
                  trailing: Text(
                    prefs?.name ?? '—',
                    style: AppText.serifBody(size: 13, color: AppColors.inkMuted),
                  ),
                  onTap: () => _editName(context, ref, prefs?.name ?? ''),
                ),
              ]),
              const SizedBox(height: 26),
              _GroupLabel('PRIVACY'),
              _SettingsCard(children: [
                _Row(
                  label: 'Password lock',
                  trailing: Switch.adaptive(
                    value: prefs?.lockEnabled ?? false,
                    activeColor: AppColors.accent,
                    onChanged: (v) => ref
                        .read(userPrefsProvider.notifier)
                        .setLockEnabled(v),
                  ),
                ),
              ]),
              const SizedBox(height: 26),
              _GroupLabel('REMINDERS'),
              _SettingsCard(children: [
                _Row(
                  label: 'Daily reminder',
                  trailing: Text(
                    prefs?.reminderTime ?? '10:00',
                    style: AppText.serifBody(size: 13, color: AppColors.inkMuted),
                  ),
                  onTap: () => _editReminder(
                      context, ref, prefs?.reminderTime ?? '10:00'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editName(
      BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Your name', style: AppText.serifBody(size: 18)),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(userPrefsProvider.notifier).setName(result);
    }
  }

  Future<void> _editReminder(
      BuildContext context, WidgetRef ref, String current) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 10,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await ref.read(userPrefsProvider.notifier).setReminderTime(formatted);
    }
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: AppText.eyebrow(size: 10)),
      );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lineSoft),
        ),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                const Divider(height: 1, color: AppColors.lineSoft),
            ],
          ],
        ),
      );
}

class _Row extends StatelessWidget {
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  const _Row({required this.label, required this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppText.ui(size: 14))),
            trailing,
          ],
        ),
      ),
    );
  }
}
