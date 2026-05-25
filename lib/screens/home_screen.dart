import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../models/project.dart';
import '../state/app_state.dart';
import '../widgets/project_card.dart';
import '../widgets/section_divider.dart';
import 'camera_screen.dart';
import 'new_project_screen.dart';
import 'project_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPrefsProvider);
    final projects = ref.watch(projectsProvider);
    final dateLabel = DateFormat('EEEE · d MMMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Greeting(
                name: prefs.value?.name ?? 'there',
                date: dateLabel,
                onSettingsTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const SizedBox(height: 30),
              const SectionDivider(label: 'Traack Box'),
              const SizedBox(height: 14),
              Expanded(
                child: projects.when(
                  data: (list) => list.isEmpty
                      ? const _EmptyState()
                      : _ProjectList(projects: list),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text('Could not load projects: $e'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewProjectScreen()),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String name;
  final String date;
  final VoidCallback onSettingsTap;

  const _Greeting({
    required this.name,
    required this.date,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi, $name.', style: AppText.display(size: 32)),
              const SizedBox(height: 8),
              Text(
                date,
                style: AppText.ui(size: 12, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onSettingsTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.lineSoft),
            ),
            child: const Icon(Icons.settings_outlined,
                size: 18, color: AppColors.ink),
          ),
        ),
      ],
    );
  }
}

class _ProjectList extends ConsumerWidget {
  final List<Project> projects;
  const _ProjectList({required this.projects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = projects[i];
        return Dismissible(
          key: ValueKey(p.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      'Delete this traack?',
                      style: AppText.serifBody(size: 18),
                    ),
                    content: Text(
                      'Every photo in "${p.name}" will be gone. This cannot be undone.',
                      style: AppText.ui(size: 14, color: AppColors.inkMuted),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'Cancel',
                          style:
                              AppText.ui(size: 14, color: AppColors.inkMuted),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB45050),
                        ),
                        child: Text(
                          'Delete',
                          style: AppText.ui(
                            size: 14,
                            weight: FontWeight.w600,
                            color: const Color(0xFFB45050),
                          ),
                        ),
                      ),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (_) {
            ref.read(projectsProvider.notifier).deleteProject(p.id);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 26),
            decoration: BoxDecoration(
              color: const Color(0xFFB45050),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'DELETE',
                  style: AppText.ui(
                    size: 11,
                    color: Colors.white,
                    weight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          child: ProjectCard(
            project: p,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectDetailScreen(projectId: p.id),
              ),
            ),
            onCapture: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CameraScreen(project: p),
              ),
            ),
            onLongPress: () => _renameProject(context, ref, p),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nothing tracked yet.',
              textAlign: TextAlign.center,
              style: AppText.serifBody(size: 22, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the + to start your first traack.',
              textAlign: TextAlign.center,
              style: AppText.ui(size: 13, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _renameProject(
    BuildContext context, WidgetRef ref, Project project) async {
  final controller = TextEditingController(text: project.name);

  final newName = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Rename traack', style: AppText.serifBody(size: 18)),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: AppText.serifBody(size: 16),
        decoration: const InputDecoration(border: OutlineInputBorder()),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: AppText.ui(size: 14, color: AppColors.inkMuted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text(
            'Save',
            style: AppText.ui(
              size: 14,
              weight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ),
      ],
    ),
  );

  if (newName != null && newName.isNotEmpty && newName != project.name) {
    await ref
        .read(projectsProvider.notifier)
        .renameProject(project.id, newName);
  }
}
