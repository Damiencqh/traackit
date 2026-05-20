/// Built-in overlay templates. A new project picks one of these;
/// the camera screen renders the corresponding silhouette over the preview.
enum TemplateKind {
  face,
  torso,
  plant,
  custom;

  String get label {
    switch (this) {
      case TemplateKind.face:
        return 'Face';
      case TemplateKind.torso:
        return 'Torso';
      case TemplateKind.plant:
        return 'Plant';
      case TemplateKind.custom:
        return 'Custom';
    }
  }

  String toJson() => name;

  static TemplateKind fromJson(String value) => TemplateKind.values
      .firstWhere((t) => t.name == value, orElse: () => TemplateKind.face);
}
