import 'package:bloc/bloc.dart';
import 'package:driva_demo_app/core/error/error.dart';
import 'package:driva_demo_app/modules/published_module/domain/entities/entities.dart';
import 'package:driva_demo_app/modules/published_module/domain/use_cases/use_cases.dart';
import 'package:equatable/equatable.dart';

part 'content_state.dart';

class ContentCubit extends Cubit<ContentState> {
  ContentCubit({required this.getPublishedContent, required this.slug})
    : super(const ContentLoading());

  final GetPublishedContentUseCase getPublishedContent;
  final String slug;

  Future<void> load() async {
    emit(const ContentLoading());
    final result = await getPublishedContent(slug);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => ContentError(failure: failure),
        (content) => ContentLoaded(content: content),
      ),
    );
  }
}
