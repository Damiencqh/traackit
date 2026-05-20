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
