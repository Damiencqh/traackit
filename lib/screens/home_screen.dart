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

class _ProjectList extends StatelessWidget {
  final List<Project> projects;
  const _ProjectList({required this.projects});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = projects[i];
        return ProjectCard(
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
