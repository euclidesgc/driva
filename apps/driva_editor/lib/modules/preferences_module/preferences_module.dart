export 'preferences_injection.dart'; // o register, para o injection.dart raiz
// A presentation do tema (cubit + botão + ponte para ThemeMode) é pública
// porque monta acima do MaterialApp e nas top bars dos outros módulos.
export 'domain/entities/app_theme_mode.dart'; // o AppThemeMode é do contrato público do tema
export 'presentation/theme/cubit/theme_cubit.dart';
export 'presentation/theme/theme_mode_x.dart';
export 'presentation/theme/widgets/theme_mode_button.dart';

// Sem rota: o módulo não é uma página, é a camada de preferências + o controle
// de tema. De fora, expõe "registre minhas dependências" e o tema para a UI.
