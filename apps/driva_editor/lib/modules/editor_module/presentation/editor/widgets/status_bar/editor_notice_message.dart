import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_notice.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_notice_kind.dart';
import 'package:sdui_core/sdui_core.dart';

abstract final class EditorNoticeMessage {
  static String of(EditorNotice notice) {
    final subject = notice.subjectType;
    final label = subject == null
        ? null
        : descriptorFor(subject)?.label ?? subject;
    final wrapper = notice.wrapperType;
    final wrapperLabel = wrapper == null
        ? null
        : descriptorFor(wrapper)?.label ?? wrapper;
    return switch (notice.kind) {
      EditorNoticeKind.dropRedirected =>
        '${label ?? 'O destino'} não recebe esse widget — '
            'ele foi encaixado no container acima.',
      EditorNoticeKind.dropCycle =>
        'Um widget não pode ser movido para dentro de si mesmo.',
      EditorNoticeKind.dropWrapped =>
        '${label ?? 'O destino'} não recebia esse widget — os dois foram '
            'agrupados numa ${wrapperLabel ?? 'Column'}.',
      EditorNoticeKind.dropUnknownTarget =>
        'O destino do arraste não existe mais.',
      EditorNoticeKind.rootNotMovable =>
        'A raiz do conteúdo não pode ser movida para dentro dela mesma.',
      EditorNoticeKind.rootNotDuplicable =>
        'A raiz do conteúdo não tem irmãos: duplique um widget de dentro dela.',
      EditorNoticeKind.nodeCopied =>
        '${label ?? 'Widget'} copiado — cole com Ctrl+V.',
      EditorNoticeKind.clipboardEmpty =>
        'Nada para colar: copie um widget antes, com Ctrl+C.',
      EditorNoticeKind.nodeWrapped => 'Envolvido numa ${label ?? 'Column'}.',
      EditorNoticeKind.publishFailed => 'Falha ao publicar. Tente novamente.',
      EditorNoticeKind.unpublishFailed =>
        'Falha ao despublicar. Tente novamente.',
      EditorNoticeKind.restoreFailed =>
        'Falha ao restaurar essa versão. Tente novamente.',
      EditorNoticeKind.loadPublishedFailed =>
        'Falha ao buscar a versão publicada. Tente novamente.',
    };
  }

  /// Só as falhas de publicar/despublicar/restaurar ganham ícone de erro na
  /// barra de status — as demais são dicas neutras sobre o arraste.
  static bool isFailure(EditorNoticeKind kind) => switch (kind) {
    EditorNoticeKind.publishFailed ||
    EditorNoticeKind.unpublishFailed ||
    EditorNoticeKind.restoreFailed ||
    EditorNoticeKind.loadPublishedFailed => true,
    _ => false,
  };
}
