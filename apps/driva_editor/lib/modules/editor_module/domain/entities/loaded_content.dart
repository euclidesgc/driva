import 'package:driva_editor/modules/editor_module/domain/entities/publication_state.dart';
import 'package:equatable/equatable.dart';
import 'package:sdui_core/sdui_core.dart';

class LoadedContent extends Equatable {
  const LoadedContent({required this.spec, required this.publication});

  final ContentSpec spec;
  final PublicationState publication;

  @override
  List<Object?> get props => [spec, publication];
}
