/// A single captured frame in a project.
class Photo {
  final String id;
  final String projectId;
  final String filePath; // relative path inside app documents directory
  final DateTime capturedAt;
  final int dayIndex; // 1-based: which day of the project this is

  const Photo({
    required this.id,
    required this.projectId,
    required this.filePath,
    required this.capturedAt,
    required this.dayIndex,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'filePath': filePath,
        'capturedAt': capturedAt.toIso8601String(),
        'dayIndex': dayIndex,
      };

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        filePath: json['filePath'] as String,
        capturedAt: DateTime.parse(json['capturedAt'] as String),
        dayIndex: json['dayIndex'] as int,
      );
}
