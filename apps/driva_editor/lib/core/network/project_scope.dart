class ProjectScope {
  ProjectScope({String? initialProjectId})
    : projectId = initialProjectId ?? _defaultProjectId;

  static const _defaultProjectId = 'default';

  String projectId;

  void reset() => projectId = _defaultProjectId;
}
