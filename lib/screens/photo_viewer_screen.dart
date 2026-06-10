import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../models/photo.dart';
import '../models/project.dart';
import '../state/app_state.dart';

/// Full-screen photo viewer. Reached by long-pressing a tile in the project grid.
/// Stays open until dismissed via the translucent X.
/// Supports pinch-to-zoom, share-to-save, and permanent delete.
class PhotoViewerScreen extends ConsumerWidget {
  final Project project;
  final Photo photo;

  const PhotoViewerScreen({
    super.key,
    required this.project,
    required this.photo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(storageServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // The photo itself — pinch and pan to zoom.
          Positioned.fill(
            child: FutureBuilder<String>(
              future: storage.resolvePhotoPath(photo.filePath),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: Image.file(
                      File(snap.data!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.white54, size: 48),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Top bar — close on left, actions on right.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _CircleControl(
                      icon: Icons.close,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    _CircleControl(
                      icon: Icons.ios_share,
                      onTap: () => _share(context, ref),
                    ),
                    const SizedBox(width: 12),
                    _CircleControl(
                      icon: Icons.delete_outline,
                      onTap: () => _confirmDelete(context, ref),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom caption — capture date.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 12),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      DateFormat('d MMM yyyy').format(photo.capturedAt),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final box = context.findRenderObject() as RenderBox?;
    final path =
        await ref.read(storageServiceProvider).resolvePhotoPath(photo.filePath);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : const Rect.fromLTWH(0, 0, 1, 1),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete this photo?', style: AppText.serifBody(size: 18)),
        content: Text(
          "This can't be undone. The photo will be permanently removed from the project — your other days stay untouched.",
          style: AppText.ui(size: 14, color: AppColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AppText.ui(size: 14, color: AppColors.inkMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: AppText.ui(
                  size: 14,
                  weight: FontWeight.w600,
                  color: const Color(0xFFB23A3A),
                )),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    await ref.read(projectsProvider.notifier).removePhoto(project.id, photo.id);

    if (!context.mounted) return;
    Navigator.pop(context); // close the viewer; grid rebuilds via Riverpod
  }
}

class _CircleControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleControl({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
