export 'projects_routes.dart';
export 'projects_injection.dart';

// Desvio da regra "barrel só rota+DI": contents_module lê UM projeto por id.
export 'domain/entities/project.dart';
export 'domain/use_cases/get_project_use_case.dart';
