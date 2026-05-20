import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../state/app_state.dart';
import 'camera_screen.dart';

/// View a single project: big day counter + grid of photos so far.
/// Timelapse export lives here in a later milestone.
class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider).value ?? [];
    final project = projects.where((p) => p.id == projectId).firstOrNull;
    final storage = ref.read(storageServiceProvider);

    if (project == null) {
      return const Scaffold(
        body: Center(child: Text('Project not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(project.name, style: AppText.serifBody(size: 22)),
              const SizedBox(height: 5),
              Text(
                'started ${DateFormat('d MMMM').format(project.createdAt)}',
                style: AppText.ui(size: 11.5, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.line),
                    bottom: BorderSide(color: AppColors.line),
                  ),
                ),
                width: double.infinity,
                child: Column(
                  children: [
                    Text(
                      '${project.daysIn}',
                      style: AppText.display(size: 80),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'DAYS TRACKED',
                      style: AppText.eyebrow(size: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: project.photos.length + 1,
                  itemBuilder: (context, i) {
                    if (i == project.photos.length) {
                      return _TodayTile(
                        onTap: project.hasPhotoToday
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CameraScreen(project: project),
                                  ),
                                ),
                      );
                    }
                    final photo = project.photos[i];
                    return FutureBuilder<String>(
                      future: storage.resolvePhotoPath(photo.filePath),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return Container(color: AppColors.paperWarm);
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(snap.data!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: AppColors.paperWarm),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.paper,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  onPressed: project.photos.length < 2
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Timelapse export — coming soon'),
                            ),
                          );
                        },
                  child: Text(
                    'GENERATE TIMELAPSE',
                    style: AppText.ui(
                      size: 12,
                      color: AppColors.paper,
                      weight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayTile extends StatelessWidget {
  final VoidCallback? onTap;
  const _TodayTile({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: onTap == null ? AppColors.line : AppColors.accent,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Icon(
            onTap == null ? Icons.check : Icons.add,
            color: onTap == null ? AppColors.inkSoft : AppColors.accent,
          ),
        ),
      ),
    );
  }
}
