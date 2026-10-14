import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/icon_editor.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/icon_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart' show iconLibraries;

const _field = PropField(
  key: 'icon',
  kind: FieldKind.iconName,
  label: 'Ícone',
  group: FieldGroups.content,
);

Future<List<Object?>> _pump(WidgetTester t, Object? value) async {
  final changes = <Object?>[];
  await t.binding.setSurfaceSize(const Size(800, 600));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: IconEditor(field: _field, value: value, onChanged: changes.add),
      ),
    ),
  );
  return changes;
}

void main() {
  testWidgets('botão mostra "None" sem valor e a prévia com valor', (t) async {
    await _pump(t, null);
    expect(find.text('None'), findsOneWidget);
    await _pump(t, 'material:home');
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.text('material:home'), findsOneWidget);
  });

  testWidgets('valor desconhecido mostra o fallback e o nome cru', (t) async {
    await _pump(t, 'outra:x');
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.text('outra:x'), findsOneWidget);
  });

  testWidgets('buscar "home" filtra; clicar grava library:name e fecha', (
    t,
  ) async {
    final changes = await _pump(t, null);
    await t.tap(find.byType(IconEditor));
    await t.pumpAndSettle();
    final total = iconLibraries['material']!.length;
    expect(find.text('Material ($total)'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'home');
    await t.pumpAndSettle();
    final cells = find.byType(IconPickerCell);
    expect(cells, findsWidgets);
    expect(t.widgetList(cells).length, lessThan(total));
    await t.tap(find.byTooltip('home'));
    await t.pumpAndSettle();
    expect(changes, ['material:home']);
    expect(find.byType(IconPickerDialog), findsNothing);
  });

  testWidgets('grade virtualizada: constrói poucas células', (t) async {
    await _pump(t, null);
    await t.tap(find.byType(IconEditor));
    await t.pumpAndSettle();
    final total = iconLibraries['material']!.length;
    final built = t.widgetList(find.byType(IconPickerCell)).length;
    expect(built, lessThanOrEqualTo(100));
    expect(built, lessThan(total));
  });

  testWidgets('busca sem resultado mostra "Nenhum ícone"', (t) async {
    await _pump(t, null);
    await t.tap(find.byType(IconEditor));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'zzzz');
    await t.pumpAndSettle();
    expect(find.text('Nenhum ícone'), findsOneWidget);
  });

  testWidgets('None devolve null', (t) async {
    final changes = await _pump(t, 'material:home');
    await t.tap(find.byType(IconEditor));
    await t.pumpAndSettle();
    await t.tap(find.text('None').last);
    await t.pumpAndSettle();
    expect(changes, [null]);
  });
}
