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

  /// Whether the user has already captured a photo today.
  bool get hasPhotoToday {
    final now = DateTime.now();
    return photos.any((p) =>
        p.capturedAt.year == now.year &&
        p.capturedAt.month == now.month &&
        p.capturedAt.day == now.day);
  }

  /// Number of distinct days you've captured a photo for this project.
  /// Equal to `photos.length` because the upsert-today logic guarantees
  /// at most one photo per calendar day.
  int get daysIn {
    final unique = <String>{};
    for (final p in photos) {
      unique.add(
          '${p.capturedAt.year}-${p.capturedAt.month}-${p.capturedAt.day}');
    }
    return unique.length;
  }

  /// Date of the oldest photo, or null if none captured yet.
  DateTime? get firstPhotoDate {
    if (photos.isEmpty) return null;
    final sorted = [...photos]
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    return sorted.first.capturedAt;
  }

  /// Date of the most recent photo, or null if none captured yet.
  DateTime? get latestPhotoDate {
    if (photos.isEmpty) return null;
    final sorted = [...photos]
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    return sorted.last.capturedAt;
  }

  /// Inclusive day count from first to latest photo.
  int get calendarSpan {
    if (photos.isEmpty) return 0;
    final first = firstPhotoDate!;
    final last = latestPhotoDate!;
    final firstDay = DateTime(first.year, first.month, first.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    return lastDay.difference(firstDay).inDays + 1;
  }

  /// Consecutive days of capture ending today (or yesterday if no photo today).
  int get currentStreak {
    if (photos.isEmpty) return 0;
    final dates = <DateTime>{
      for (final p in photos)
        DateTime(p.capturedAt.year, p.capturedAt.month, p.capturedAt.day),
    };
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime cursor;
    if (dates.contains(today)) {
      cursor = today;
    } else if (dates.contains(yesterday)) {
      cursor = yesterday;
    } else {
      return 0;
    }

    var streak = 0;
    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
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
