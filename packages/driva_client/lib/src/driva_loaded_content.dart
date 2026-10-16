import 'package:equatable/equatable.dart';
import 'package:sdui_core/sdui_core.dart';

class DrivaLoadedContent extends Equatable {
  const DrivaLoadedContent({required this.spec, required this.theme});

  final ContentSpec spec;
  final ProjectTheme theme;

  @override
  List<Object?> get props => [spec, theme];
}
