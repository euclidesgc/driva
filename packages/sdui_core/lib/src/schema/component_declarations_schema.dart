import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/src/model/component_param.dart';
import 'package:sdui_core/src/model/component_param_type.dart';
import 'package:sdui_core/src/model/component_state_variable.dart';
import 'package:sdui_core/src/schema/spec_validation_error.dart';
import 'package:zard/zard.dart';

final ZString _name = z.string().min(1);
final ZString _description = z.string();
final ZBool _flag = z.bool();

typedef _Declaration = ({
  String name,
  ComponentParamType type,
  bool isList,
  Object? defaultValue,
  String? description,
  List<String> options,
});

Either<SpecValidationError, List<ComponentParam>> parseComponentParams(
  Object? raw, {
  String path = 'params',
}) => _parseList(
  raw,
  path,
  (json, itemPath) => _parseParam(json, itemPath, onlyData: false),
  (param) => param.name,
);

Either<SpecValidationError, List<ComponentStateVariable>> parseComponentState(
  Object? raw, {
  String path = 'state',
}) => _parseList(
  raw,
  path,
  (json, itemPath) => _parseDeclaration(json, itemPath, onlyData: true).map(
    (declaration) => ComponentStateVariable(
      name: declaration.name,
      type: declaration.type,
      isList: declaration.isList,
      defaultValue: declaration.defaultValue,
      description: declaration.description,
      options: declaration.options,
    ),
  ),
  (variable) => variable.name,
);

Either<SpecValidationError, List<T>> _parseList<T>(
  Object? raw,
  String path,
  Either<SpecValidationError, T> Function(Map<String, dynamic>, String) parse,
  String Function(T) nameOf,
) {
  if (raw == null) return Right(List<T>.empty());
  if (raw is! List) {
    return Left(SpecValidationError('$path: esperada uma lista'));
  }

  final items = <T>[];
  final names = <String>{};
  for (var i = 0; i < raw.length; i++) {
    final itemPath = '$path[$i]';
    final item = raw[i];
    if (item is! Map) {
      return Left(SpecValidationError('$itemPath: esperado um objeto'));
    }
    final parsed = parse(item.cast<String, dynamic>(), itemPath);
    switch (parsed) {
      case Left(:final value):
        return Left(value);
      case Right(:final value):
        if (!names.add(nameOf(value))) {
          return Left(
            SpecValidationError(
              '$itemPath.name: nome "${nameOf(value)}" repetido',
            ),
          );
        }
        items.add(value);
    }
  }
  return Right(items);
}

Either<SpecValidationError, ComponentParam> _parseParam(
  Map<String, dynamic> json,
  String path, {
  required bool onlyData,
}) {
  return _parseDeclaration(json, path, onlyData: onlyData).flatMap(
    (declaration) => _scalar(_flag, json['required'], '$path.required').flatMap(
      (isRequired) => _parseCallbackParams(json, path, declaration.type).map(
        (callbackParams) => ComponentParam(
          name: declaration.name,
          type: declaration.type,
          isList: declaration.isList,
          isRequired: isRequired,
          defaultValue: declaration.defaultValue,
          description: declaration.description,
          options: declaration.options,
          callbackParams: callbackParams,
        ),
      ),
    ),
  );
}

Either<SpecValidationError, List<ComponentParam>> _parseCallbackParams(
  Map<String, dynamic> json,
  String path,
  ComponentParamType type,
) {
  if (!json.containsKey('params')) return const Right([]);
  if (type != ComponentParamType.action) {
    return Left(
      SpecValidationError(
        '$path.params: só um parâmetro do tipo '
        '"${ComponentParamType.action.name}" declara parâmetros',
      ),
    );
  }
  return _parseList(
    json['params'],
    '$path.params',
    (item, itemPath) => _parseParam(item, itemPath, onlyData: true),
    (param) => param.name,
  );
}

Either<SpecValidationError, _Declaration> _parseDeclaration(
  Map<String, dynamic> json,
  String path, {
  required bool onlyData,
}) {
  final name = _scalar(_name, json['name'], '$path.name');
  if (name case Left(:final value)) return Left(value);

  final type = ComponentParamType.fromName(json['type']);
  if (type == null) {
    return Left(
      SpecValidationError(
        '$path.type: tipo "${json['type']}" desconhecido (aceitos: '
        '${ComponentParamType.values.map((t) => t.name).join(', ')})',
      ),
    );
  }
  if (onlyData && !type.isData) {
    return Left(
      SpecValidationError(
        '$path.type: só tipo de dado é aceito aqui, e "${type.name}" '
        '(${type.label}) não é',
      ),
    );
  }

  final isList = _scalar(_flag, json['isList'], '$path.isList');
  if (isList case Left(:final value)) return Left(value);

  String? description;
  if (json['description'] != null) {
    final parsed = _scalar(
      _description,
      json['description'],
      '$path.description',
    );
    if (parsed case Left(:final value)) return Left(value);
    description = parsed.toNullable();
  }

  final options = _parseOptions(json, path, type);
  if (options case Left(:final value)) return Left(value);

  final declaration = (
    name: name.toNullable()!,
    type: type,
    isList: isList.toNullable()!,
    defaultValue: json['default'],
    description: description,
    options: options.toNullable()!,
  );
  final defaultError = _checkDefault(json, path, declaration);
  return defaultError == null ? Right(declaration) : Left(defaultError);
}

Either<SpecValidationError, List<String>> _parseOptions(
  Map<String, dynamic> json,
  String path,
  ComponentParamType type,
) {
  final raw = json['options'];
  if (type != ComponentParamType.option) {
    return raw == null
        ? const Right([])
        : Left(
            SpecValidationError(
              '$path.options: só um parâmetro do tipo '
              '"${ComponentParamType.option.name}" declara opções',
            ),
          );
  }
  if (raw is! List || raw.isEmpty || raw.any((o) => o is! String)) {
    return Left(
      SpecValidationError(
        '$path.options: esperada uma lista não vazia de textos',
      ),
    );
  }
  return Right(raw.cast<String>());
}

SpecValidationError? _checkDefault(
  Map<String, dynamic> json,
  String path,
  _Declaration declaration,
) {
  if (!json.containsKey('default')) return null;
  final type = declaration.type;
  if (!type.isData) {
    return SpecValidationError(
      '$path.default: parâmetro do tipo "${type.name}" não tem valor padrão',
    );
  }
  final accepted = type.accepts(
    declaration.defaultValue,
    isList: declaration.isList,
    options: declaration.options,
  );
  if (accepted) return null;
  final expected = declaration.isList ? 'lista de ${type.label}' : type.label;
  return SpecValidationError('$path.default: esperado $expected');
}

Either<SpecValidationError, T> _scalar<T>(
  Schema<T> schema,
  Object? value,
  String path,
) {
  final result = schema.safeParse(value);
  if (!result.success) {
    return Left(
      SpecValidationError('$path: ${z.prettifyError(result.error!)}'),
    );
  }
  return Right(result.data as T);
}
