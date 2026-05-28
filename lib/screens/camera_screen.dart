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
/// - Opens the back camera by default (triggering iOS permission prompt on first use)
/// - Shows the live preview + ghost-of-yesterday + dashed template silhouette
/// - Flip button to switch between back/front cameras
/// - On shutter tap: takes a JPEG, saves it to the project's photo folder,
///   adds a Photo to state, pops back to the previous screen.
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
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;

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

    // Save the camera list and start with the back camera if available.
    _cameras = cameras;
    final backIndex = cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    _currentCameraIndex = backIndex >= 0 ? backIndex : 0;

    await _initController(_cameras[_currentCameraIndex]);
  }

  /// Initialise a CameraController for a given camera description.
  /// Disposes the previous controller cleanly first.
  Future<void> _initController(CameraDescription camera) async {
    await _controller?.dispose();

    final controller = CameraController(
      camera,
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

  /// Switches between back and front (or whatever cameras are available).
  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _capturing) return;

    final newIndex = (_currentCameraIndex + 1) % _cameras.length;
    setState(() {
      _currentCameraIndex = newIndex;
      _controller = null; // shows loading spinner during the flip
    });
    await _initController(_cameras[newIndex]);
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
          .addOrReplaceTodayPhoto(widget.project.id, photo);

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
    final prefs = ref.watch(userPrefsProvider).value;
    final ghostEnabled = prefs?.ghostEnabled ?? true;
    final ghostOpacity = prefs?.ghostOpacity ?? 0.30;

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

// Ghost of yesterday — previous-day photo at adjustable opacity.
              // Toggle + opacity live in Settings; off = template outline only.
              if (ghostEnabled && widget.project.ghostPhoto != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: FutureBuilder<String>(
                      future: ref.read(storageServiceProvider).resolvePhotoPath(
                          widget.project.ghostPhoto!.filePath),
                      builder: (context, ghostSnap) {
                        if (!ghostSnap.hasData) {
                          return const SizedBox.shrink();
                        }
                        return Opacity(
                          opacity: ghostOpacity,
                          child: Image.file(
                            File(ghostSnap.data!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        );
                      },
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

              // Shutter — bottom center.
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child:
                    Center(child: _Shutter(onTap: _capture, busy: _capturing)),
              ),

              // Flip-camera button — bottom right, alongside the shutter.
              if (_cameras.length > 1)
                Positioned(
                  bottom: 50,
                  right: 32,
                  child: GestureDetector(
                    onTap: _flipCamera,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.cameraswitch_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
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
