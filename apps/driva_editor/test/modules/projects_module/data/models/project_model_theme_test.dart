import 'package:driva_editor/modules/projects_module/data/models/project_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

void main() {
  Map<String, dynamic> base() => {
    'id': 'p1',
    'title': 'P',
    'createdAt': DateTime(2026),
    'updatedAt': DateTime(2026),
    'contentCount': 0,
    'categoryCount': 0,
  };

  ProjectTheme parse(Map<String, dynamic> m) => ProjectModel.tryParse(
    m,
  ).getOrElse((_) => throw StateError('falhou')).theme;

  test('tema ausente ou inválido cai no padrão', () {
    expect(parse(base()), kDefaultProjectTheme);
    expect(parse({...base(), 'theme': 'lixo'}), kDefaultProjectTheme);
    expect(parse({...base(), 'theme': null}), kDefaultProjectTheme);
  });

  test('tema válido vira o tema do kernel', () {
    final theme = parse({
      ...base(),
      'theme': {
        'colors': {'primary': '#FF0000'},
      },
    });
    expect(theme.colors[ThemeColorRole.primary], '#FF0000');
  });
}
