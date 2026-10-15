import 'package:sdui_core/sdui_core.dart';

/// O nome em pt-BR de um [PropValueType], como a pessoa lê no seletor de
/// variável: o tipo que o campo espera e o tipo que cada fonte entrega.
String propValueTypeLabel(PropValueType type) => switch (type) {
  PropValueType.text => 'texto',
  PropValueType.integer => 'número inteiro',
  PropValueType.decimal => 'número',
  PropValueType.dimension => 'tamanho em pixels',
  PropValueType.boolean => 'booleano',
  PropValueType.color => 'cor',
  PropValueType.option => 'opção',
  PropValueType.spacing => 'espaçamento',
  PropValueType.alignment => 'alinhamento',
  PropValueType.icon => 'ícone',
  PropValueType.any => 'qualquer',
  PropValueType.declared => 'definido pela fonte',
};
