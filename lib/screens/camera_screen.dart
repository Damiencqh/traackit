import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../core/theme/app_text.dart';
import '../models/photo.dart';
import '../models/project.dart';
import '../state/app_state.dart';
import '../widgets/template_overlay.dart';

/// Camera capture screen.
///
/// Scaffolding for v0.1:
///   - Opens the back camera (triggering iOS permission prompt on first use)
///   - Shows the live preview + dashed template silhouette
///   - On shutter tap: takes a JPEG, saves it to the project's photo folder,
///     adds a Photo to state, pops back to the previous screen.
///
/// Still TODO in later milestones:
///   - Front-facing camera toggle
///   - Ghost-of-yesterday overlay (last photo at low opacity)
///   - Grid lines, exposure lock, tap-to-focus
///   - Block re-capture for the same day (or offer "replace today's photo")
class CameraScreen extends ConsumerStatefulWidget {
  final Project project;

  const CameraScreen({super.key, required this.project});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initFuture = _setupCamera();
  }

  Future<void> _setupCamera() async {
    // 1. Discover cameras — this triggers iOS's camera permission prompt
    //    on first use via AVFoundation directly (no permission_handler).
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } catch (e) {
      setState(() => _error = 'Camera access denied or unavailable: $e');
      return;
    }
    if (cameras.isEmpty) {
      setState(() => _error = 'No cameras on this device.');
      return;
    }

    // Prefer the back camera; fall back to whatever's first.
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    // 2. Initialise controller
    final controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
    } catch (e) {
      setState(() => _error = 'Could not initialise camera: $e');
      return;
    }
    if (!mounted) return;
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _capturing) return;

    setState(() => _capturing = true);
    try {
      final shot = await ctrl.takePicture();
      final storage = ref.read(storageServiceProvider);

      // Move temp file into project folder with a unique name.
      final dir = await storage.photoDirFor(widget.project.id);
      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final dest = p.join(dir.path, filename);
      await File(shot.path).copy(dest);

      // Stored as a path relative to the documents directory so backups
      // still work even if the absolute path changes between app versions.
      final relative = p.join('projects', widget.project.id, filename);

      final photo = Photo(
        id: const Uuid().v4(),
        projectId: widget.project.id,
        filePath: relative,
        capturedAt: DateTime.now(),
        dayIndex: widget.project.daysIn,
      );

      await ref
          .read(projectsProvider.notifier)
          .addPhotoToProject(widget.project.id, photo);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'Could not capture: $e';
        _capturing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E0C),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Day ${widget.project.daysIn}',
          style: AppText.serifBody(size: 18, color: Colors.white),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snap) {
          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  style: AppText.ui(size: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (_controller == null || !_controller!.value.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Live preview — fill the screen, cropping if needed.
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.previewSize?.height ?? 1,
                    height: _controller!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),

              // Template silhouette overlay
              Positioned.fill(
                child: TemplateOverlay(kind: widget.project.template),
              ),

              // Hint text
              Positioned(
                top: kToolbarHeight + MediaQuery.of(context).padding.top + 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'ALIGN WITH THE OUTLINE',
                    style: AppText.eyebrow(color: Colors.white70, size: 10),
                  ),
                ),
              ),

              // Shutter
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child:
                    Center(child: _Shutter(onTap: _capture, busy: _capturing)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  final VoidCallback onTap;
  final bool busy;
  const _Shutter({required this.onTap, required this.busy});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: busy ? Colors.white54 : Colors.white,
          ),
        ),
      ),
    );
  }
}
