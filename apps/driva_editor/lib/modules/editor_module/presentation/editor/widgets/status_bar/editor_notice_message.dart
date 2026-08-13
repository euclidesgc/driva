import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_notice.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_notice_kind.dart';
import 'package:sdui_core/sdui_core.dart';

abstract final class EditorNoticeMessage {
  static String of(EditorNotice notice) {
    final subject = notice.subjectType;
    final label = subject == null
        ? null
        : descriptorFor(subject)?.label ?? subject;
    return switch (notice.kind) {
      EditorNoticeKind.dropRedirected =>
        '${label ?? 'O destino'} não recebe esse widget — '
            'ele foi encaixado no container acima.',
      EditorNoticeKind.dropCycle =>
        'Um widget não pode ser movido para dentro de si mesmo.',
      EditorNoticeKind.dropNoSlot =>
        'Não há onde encaixar: nenhum widget acima do destino aceita filhos.',
      EditorNoticeKind.dropUnknownTarget =>
        'O destino do arraste não existe mais.',
      EditorNoticeKind.rootNotMovable =>
        'A raiz do conteúdo não pode ser movida para dentro dela mesma.',
    };
  }
}
