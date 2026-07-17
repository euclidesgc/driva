// Barrel raiz dos widgets app-wide (o "components" da app): widgets genéricos,
// sem estado de negócio, recebendo dados pelo construtor — organizados por
// categoria em subpastas, cada uma com seu barrel. Widget usado por vários
// módulos mora aqui; só desce de tier (módulo → feature) quando o uso
// justificar.
export 'app_shell/app_shell.dart';
export 'branding/branding.dart';
export 'buttons/buttons.dart';
export 'feedback/feedback.dart';
export 'input/input.dart';
export 'layout/layout.dart';
export 'painters/painters.dart';
