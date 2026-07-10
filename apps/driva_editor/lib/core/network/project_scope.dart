/// Holds the id of the project currently open in the editor.
///
/// Mutable on purpose: no stream, no reactive state. Screens read
/// [projectId] fresh whenever they navigate/reload — they don't need to
/// react live to changes made elsewhere.
///
/// Registered as a singleton in [setupInjection] and consumed by the shared
/// Dio's interceptor (see `dio_client.dart`) to stamp every request with
/// `x-project-id`.
class ProjectScope {
  ProjectScope({String? initialProjectId})
    : projectId = initialProjectId ?? _defaultProjectId;

  static const _defaultProjectId = 'default';

  /// Id of the project currently open. Defaults to `'default'`.
  String projectId;

  /// Switches the scope to [id].
  void set(String id) => projectId = id;

  /// Restores the default scope.
  void reset() => projectId = _defaultProjectId;
}
