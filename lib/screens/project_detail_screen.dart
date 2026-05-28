import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../models/project.dart';
import '../state/app_state.dart';
import 'camera_screen.dart';

/// View a single project: big day counter + grid of photos so far,
/// plus the timelapse export button.
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
                      : () => _generateTimelapse(context, ref, project),
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

  Future<void> _generateTimelapse(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    // Let the user choose playback speed first.
    final fps = await showDialog<int>(
      context: context,
      builder: (_) => _SpeedPickerDialog(photoCount: project.photos.length),
    );
    if (fps == null) return; // cancelled

    // Capture the render box now to anchor the iOS share sheet.
    // iOS 26 throws if sharePositionOrigin is a zero rect.
    final box = context.findRenderObject() as RenderBox?;

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _GeneratingDialog(),
    );

    try {
      final path =
          await ref.read(timelapseServiceProvider).generate(project, fps: fps);

      if (!context.mounted) return;
      Navigator.pop(context); // close the progress dialog

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: '${project.name} — ${project.daysIn} days',
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : const Rect.fromLTWH(0, 0, 1, 1),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't generate timelapse: $e")),
      );
    }
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

class _GeneratingDialog extends StatelessWidget {
  const _GeneratingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 22),
            Text('Weaving your days', style: AppText.serifBody(size: 18)),
            const SizedBox(height: 6),
            Text(
              'This may take a moment.',
              style: AppText.ui(size: 12, color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedPickerDialog extends StatefulWidget {
  final int photoCount;
  const _SpeedPickerDialog({required this.photoCount});

  @override
  State<_SpeedPickerDialog> createState() => _SpeedPickerDialogState();
}

class _SpeedPickerDialogState extends State<_SpeedPickerDialog> {
  double _fps = 8;

  @override
  Widget build(BuildContext context) {
    final fps = _fps.round();
    final perFrame = 1 / fps; // seconds each photo is shown
    final totalSecs = widget.photoCount / fps;

    return AlertDialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Timelapse speed', style: AppText.serifBody(size: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$fps frames per second',
            style: AppText.ui(size: 14, weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${perFrame.toStringAsFixed(2)}s per photo  ·  ~${totalSecs.toStringAsFixed(1)}s total',
            style: AppText.ui(size: 12, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _fps,
            min: 2,
            max: 12,
            divisions: 10,
            activeColor: AppColors.accent,
            label: '$fps fps',
            onChanged: (v) => setState(() => _fps = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Slower',
                  style: AppText.ui(size: 11, color: AppColors.inkMuted)),
              Text('Faster',
                  style: AppText.ui(size: 11, color: AppColors.inkMuted)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: AppText.ui(size: 14, color: AppColors.inkMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _fps.round()),
          child: Text('Generate',
              style: AppText.ui(
                  size: 14, weight: FontWeight.w600, color: AppColors.accent)),
        ),
      ],
    );
  }
}
