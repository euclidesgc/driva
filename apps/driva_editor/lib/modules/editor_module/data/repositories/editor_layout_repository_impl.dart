import 'dart:convert';

import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/data/models/editor_layout_model.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_layout_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditorLayoutRepositoryImpl implements EditorLayoutRepository {
  const EditorLayoutRepositoryImpl(this.prefs);
  static const _layoutKey = 'editor.layout';

  final SharedPreferences prefs;

  @override
  Future<Either<Failure, EditorLayoutSnapshot>> getLayout() async {
    try {
      final raw = prefs.getString(_layoutKey);
      // Chave ausente é o caminho normal (primeira sessão do editor): D12
      // resolve isso aqui mesmo, em `Right`, sem sequer tentar decodificar.
      if (raw == null) return const Right(EditorLayoutSnapshot());

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const Left(
          ValidationFailure('Layout salvo não é um objeto JSON.'),
        );
      }
      return EditorLayoutModel.tryParse(decoded.cast<String, dynamic>());
    } on FormatException {
      // JSON corrompido é a mesma família de falha que o schema zard rejeitar
      // — D12 trata os dois como `Left(ValidationFailure)`. Quem lê decide
      // se dobra para o padrão; este repositório só relata a verdade.
      return const Left(
        ValidationFailure('Layout salvo não é um JSON válido.'),
      );
    } on Exception catch (_) {
      return const Left(UnexpectedFailure('Falha ao ler o layout do editor.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveLayout(EditorLayoutSnapshot layout) async {
    try {
      final json = jsonEncode(EditorLayoutModel.toJson(layout));
      await prefs.setString(_layoutKey, json);
      return const Right(unit);
    } on Exception catch (_) {
      return const Left(
        UnexpectedFailure('Falha ao salvar o layout do editor.'),
      );
    }
  }
}
