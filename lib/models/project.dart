import 'photo.dart';
import 'template.dart';

/// A user-tracked project (e.g. "My Strawberry Plant").
/// Owns its photos. Persisted as JSON via [StorageService].
class Project {
  final String id;
  final String name;
  final TemplateKind template;
  final DateTime createdAt;
  final List<Photo> photos;

  const Project({
    required this.id,
    required this.name,
    required this.template,
    required this.createdAt,
    this.photos = const [],
  });

  /// Days since the project was started (1-based; day 1 is the start day).
  int get daysIn => DateTime.now().difference(createdAt).inDays + 1;

  /// Whether the user has already captured a photo today.
  bool get hasPhotoToday {
    final now = DateTime.now();
    return photos.any((p) =>
        p.capturedAt.year == now.year &&
        p.capturedAt.month == now.month &&
        p.capturedAt.day == now.day);
  }

  /// Today's photo, or null if none captured today.
  Photo? get todayPhoto {
    final now = DateTime.now();
    for (final p in photos) {
      if (p.capturedAt.year == now.year &&
          p.capturedAt.month == now.month &&
          p.capturedAt.day == now.day) {
        return p;
      }
    }
    return null;
  }

  /// The most recent photo captured *before* today, or null if none.
  /// This is the camera "ghost" target — so retaking today's photo still
  /// aligns against the previous day, not the shot being replaced.
  Photo? get ghostPhoto {
    final now = DateTime.now();
    bool isToday(Photo p) =>
        p.capturedAt.year == now.year &&
        p.capturedAt.month == now.month &&
        p.capturedAt.day == now.day;
    final prior = photos.where((p) => !isToday(p)).toList()
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    return prior.isEmpty ? null : prior.last;
  }

  /// The most recently captured photo, or null if none exist yet.
  /// Used by the camera screen to render the "ghost of yesterday" overlay.
  Photo? get latestPhoto {
    if (photos.isEmpty) return null;
    final sorted = [...photos]
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    return sorted.last;
  }

  Project copyWith({
    String? name,
    TemplateKind? template,
    List<Photo>? photos,
  }) =>
      Project(
        id: id,
        name: name ?? this.name,
        template: template ?? this.template,
        createdAt: createdAt,
        photos: photos ?? this.photos,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'template': template.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'photos': photos.map((p) => p.toJson()).toList(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        template: TemplateKind.fromJson(json['template'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        photos: (json['photos'] as List<dynamic>? ?? [])
            .map((e) => Photo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
