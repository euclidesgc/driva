import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_mock_viewport.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/device_frame.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/version_compare_candidate_bar.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/version_compare_inert_preview.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// O mock da direita no modo de comparação: a versão escolhida no histórico,
/// inerte, ao lado do rascunho ao vivo.
///
/// Tem `RepaintBoundary` próprio porque os dois mocks vivem na mesma `Row` e
/// o da esquerda repinta a cada tecla digitada — sem a barreira, o snapshot
/// histórico, que nunca muda entre trocas de versão, repintaria junto.
///
/// [unsafeView] substitui a moldura quando a comparação não pôde ser feita
/// com segurança (IDs duplicados): o lugar do mock é onde o usuário procura
/// a resposta, então a explicação mora ali, não numa faixa distante.
///
/// [showBar] desliga [VersionCompareCandidateBar] quando a identificação já
/// vem de uma barra externa que atravessa os dois lados — lado a lado, ela
/// mora em `VersionCompareModeBar`, não duplicada aqui. Continua ligada por
/// padrão para o uso avulso (faixa estreita, um mock por vez).
///
/// A moldura entra em [CanvasMockViewport], a mesma cadeia de layout do
/// rascunho: um `Column` com `Expanded` daria constraints **tight** ao
/// filho, e o `SizedBox` interno de `DeviceFrame` seria forçado a esse
/// tamanho em vez do próprio, distorcendo a moldura mesmo com o mesmo
/// `effectiveScale` do rascunho. Reusar o widget, em vez de uma variante
/// própria, é o que impede o defeito de voltar de um lado só.
class VersionCompareMockPane extends StatelessWidget {
  const VersionCompareMockPane({
    required this.device,
    required this.effectiveScale,
    required this.spec,
    required this.candidate,
    required this.onOlder,
    required this.onNewer,
    required this.onLoadFullVersion,
    required this.onClose,
    this.showBar = true,
    this.unsafeView,
    this.imageUrlResolver,
    super.key,
  });

  final DevicePreset device;
  final double effectiveScale;
  final ContentSpec spec;
  final LoadedHistoryEntry candidate;
  final VoidCallback? onOlder;
  final VoidCallback? onNewer;
  final VoidCallback onLoadFullVersion;
  final VoidCallback onClose;
  final bool showBar;
  final Widget? unsafeView;
  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showBar)
          VersionCompareCandidateBar(
            candidate: candidate,
            onOlder: onOlder,
            onNewer: onNewer,
            onLoadFullVersion: onLoadFullVersion,
            onClose: onClose,
          ),
        Expanded(
          child: unsafeView != null
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.s32),
                  child: unsafeView,
                )
              : CanvasMockViewport(
                  effectiveScale: effectiveScale,
                  child: DeviceFrame(
                    device: device,
                    highlighted: false,
                    child: VersionCompareInertPreview(
                      spec: spec,
                      imageUrlResolver: imageUrlResolver,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
