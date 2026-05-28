import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/project.dart';
import 'storage_service.dart';

/// Builds an MP4 timelapse from a project's photos using FFmpeg (libx264).
///
/// Output: 1080x1920 portrait, 8 fps. Each photo is scaled to fit while
/// preserving aspect ratio, with black letterboxing where the photo's
/// ratio doesn't match 9:16. Everything runs on-device; nothing is uploaded.
class TimelapseService {
  TimelapseService(this._storage);
  final StorageService _storage;

  Future<String> generate(Project project, {int fps = 8}) async {
    if (project.photos.length < 2) {
      throw StateError('Need at least 2 photos to make a timelapse.');
    }

    // 1. Stage photos into a temp dir with sequential names that
    //    FFmpeg's image2 demuxer understands: frame_0000.jpg, ...
    final tmp = await getTemporaryDirectory();
    final staging = Directory(p.join(tmp.path, 'tl_${project.id}'));
    if (staging.existsSync()) staging.deleteSync(recursive: true);
    staging.createSync(recursive: true);

    // Oldest -> newest so the video reads chronologically.
    final sorted = [...project.photos]
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));

    for (var i = 0; i < sorted.length; i++) {
      final src = await _storage.resolvePhotoPath(sorted[i].filePath);
      final name = 'frame_${i.toString().padLeft(4, '0')}.jpg';
      await File(src).copy(p.join(staging.path, name));
    }

    // 2. Output path inside the app sandbox.
    final docs = await getApplicationDocumentsDirectory();
    final outPath = p.join(
      docs.path,
      'timelapses',
      '${project.id}_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    Directory(p.dirname(outPath)).createSync(recursive: true);

    // 3. Build and run the ffmpeg command.
    //    -framerate N : each JPEG lasts 1/N sec
    //    scale+pad    : fit into 1080x1920 with black letterboxing
    //    setsar=1     : square pixels (avoids playback warping)
    //    libx264 + yuv420p : universally playable H.264
    //    +faststart   : lets the share-sheet preview start immediately
    final inputPattern = p.join(staging.path, 'frame_%04d.jpg');
    final cmd = '-framerate $fps '
        '-i "$inputPattern" '
        '-vf "scale=1080:1920:force_original_aspect_ratio=decrease,'
        'pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1" '
        '-c:v libx264 -pix_fmt yuv420p -movflags +faststart '
        '-y "$outPath"';

    final session = await FFmpegKit.execute(cmd);
    final rc = await session.getReturnCode();

    // 4. Clean up staging regardless of outcome.
    try {
      staging.deleteSync(recursive: true);
    } catch (_) {}

    if (ReturnCode.isSuccess(rc)) {
      return outPath;
    }
    final logs = await session.getOutput();
    throw Exception('FFmpeg failed (rc=$rc).\n${logs ?? '(no logs)'}');
  }
}
