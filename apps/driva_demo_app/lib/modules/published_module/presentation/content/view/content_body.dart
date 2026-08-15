import 'package:driva_demo_app/modules/published_module/presentation/content/cubit/content_cubit.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/view/content_error_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/view/rendered_content_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContentBody extends StatelessWidget {
  const ContentBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContentCubit, ContentState>(
      builder: (context, state) => switch (state) {
        ContentLoading() => const Center(child: CircularProgressIndicator()),
        ContentLoaded(:final content) => RenderedContentView(content: content),
        ContentError(:final failure) => ContentErrorView(failure: failure),
      },
    );
  }
}
