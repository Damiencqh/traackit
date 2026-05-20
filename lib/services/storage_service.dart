import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/project.dart';

/// On-device persistence for projects and their photos.
///
/// Project metadata lives in a single JSON file (`projects.json`)
/// inside the app documents directory. Photos are stored as JPEGs
/// in a per-project subfolder. Nothing ever touches the network.
///
/// For larger libraries (>200 projects or >10k photos) move to
/// sqflite or isar. JSON is fine for v1.
class StorageService {
  static const _projectsFile = 'projects.json';

  Future<Directory> _docsDir() async =>
      await getApplicationDocumentsDirectory();

  Future<File> _projectsJson() async {
    final dir = await _docsDir();
    return File(p.join(dir.path, _projectsFile));
  }

  /// Folder where this project's photo files live.
  Future<Directory> photoDirFor(String projectId) async {
    final dir = await _docsDir();
    final photos = Directory(p.join(dir.path, 'projects', projectId));
    if (!await photos.exists()) {
      await photos.create(recursive: true);
    }
    return photos;
  }

  /// Absolute file path on disk for a given relative photo path.
  Future<String> resolvePhotoPath(String relativePath) async {
    final dir = await _docsDir();
    return p.join(dir.path, relativePath);
  }

  Future<List<Project>> loadProjects() async {
    final file = await _projectsJson();
    if (!await file.exists()) return [];

    try {
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((j) => Project.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Corrupt file — log and start clean rather than crashing.
      // ignore: avoid_print
      print('[StorageService] failed to load projects: $e');
      return [];
    }
  }

  Future<void> saveProjects(List<Project> projects) async {
    final file = await _projectsJson();
    final encoded = jsonEncode(projects.map((p) => p.toJson()).toList());
    await file.writeAsString(encoded);
  }

  Future<void> deletePhotoFile(String relativePath) async {
    final full = await resolvePhotoPath(relativePath);
    final file = File(full);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
