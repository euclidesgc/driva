import 'package:flutter/widgets.dart';

/// Conversores de enum (string do spec → enum Flutter), com o default do spec
/// embutido como fallback — o renderer recebe o JSON cru (sem defaults do Zod).

const _mainAxis = <String, MainAxisAlignment>{
  'start': MainAxisAlignment.start,
  'end': MainAxisAlignment.end,
  'center': MainAxisAlignment.center,
  'spaceBetween': MainAxisAlignment.spaceBetween,
  'spaceAround': MainAxisAlignment.spaceAround,
  'spaceEvenly': MainAxisAlignment.spaceEvenly,
};
MainAxisAlignment mainAxisAlignmentFrom(Object? v) =>
    _mainAxis[v] ?? MainAxisAlignment.start;

const _crossAxis = <String, CrossAxisAlignment>{
  'start': CrossAxisAlignment.start,
  'end': CrossAxisAlignment.end,
  'center': CrossAxisAlignment.center,
  'stretch': CrossAxisAlignment.stretch,
  'baseline': CrossAxisAlignment.baseline,
};
CrossAxisAlignment crossAxisAlignmentFrom(Object? v) =>
    _crossAxis[v] ?? CrossAxisAlignment.center;

MainAxisSize mainAxisSizeFrom(Object? v) =>
    v == 'min' ? MainAxisSize.min : MainAxisSize.max;

const _textAlign = <String, TextAlign>{
  'left': TextAlign.left,
  'right': TextAlign.right,
  'center': TextAlign.center,
  'justify': TextAlign.justify,
  'start': TextAlign.start,
  'end': TextAlign.end,
};
TextAlign textAlignFrom(Object? v) => _textAlign[v] ?? TextAlign.start;

const _overflow = <String, TextOverflow>{
  'clip': TextOverflow.clip,
  'fade': TextOverflow.fade,
  'ellipsis': TextOverflow.ellipsis,
  'visible': TextOverflow.visible,
};
TextOverflow textOverflowFrom(Object? v) => _overflow[v] ?? TextOverflow.clip;

const _alignment = <String, Alignment>{
  'topLeft': Alignment.topLeft,
  'topCenter': Alignment.topCenter,
  'topRight': Alignment.topRight,
  'centerLeft': Alignment.centerLeft,
  'center': Alignment.center,
  'centerRight': Alignment.centerRight,
  'bottomLeft': Alignment.bottomLeft,
  'bottomCenter': Alignment.bottomCenter,
  'bottomRight': Alignment.bottomRight,
};
Alignment? alignmentFrom(Object? v) => v is String ? _alignment[v] : null;

const _alignmentDirectional = <String, AlignmentDirectional>{
  'topStart': AlignmentDirectional.topStart,
  'topCenter': AlignmentDirectional.topCenter,
  'topEnd': AlignmentDirectional.topEnd,
  'centerStart': AlignmentDirectional.centerStart,
  'center': AlignmentDirectional.center,
  'centerEnd': AlignmentDirectional.centerEnd,
  'bottomStart': AlignmentDirectional.bottomStart,
  'bottomCenter': AlignmentDirectional.bottomCenter,
  'bottomEnd': AlignmentDirectional.bottomEnd,
};
AlignmentGeometry alignmentDirectionalFrom(Object? v) =>
    (v is String ? _alignmentDirectional[v] : null) ??
    AlignmentDirectional.topStart;

const _boxFit = <String, BoxFit>{
  'fill': BoxFit.fill,
  'contain': BoxFit.contain,
  'cover': BoxFit.cover,
  'fitWidth': BoxFit.fitWidth,
  'fitHeight': BoxFit.fitHeight,
  'none': BoxFit.none,
  'scaleDown': BoxFit.scaleDown,
};
BoxFit boxFitFrom(Object? v) => _boxFit[v] ?? BoxFit.contain;

StackFit stackFitFrom(Object? v) => switch (v) {
      'expand' => StackFit.expand,
      'passthrough' => StackFit.passthrough,
      _ => StackFit.loose,
    };

Clip clipFrom(Object? v) => switch (v) {
      'none' => Clip.none,
      'antiAlias' => Clip.antiAlias,
      'antiAliasWithSaveLayer' => Clip.antiAliasWithSaveLayer,
      _ => Clip.hardEdge,
    };

FlexFit flexFitFrom(Object? v) => v == 'tight' ? FlexFit.tight : FlexFit.loose;

/// Eixo (Wrap / ListView / SingleChildScrollView). Default: horizontal.
Axis axisFrom(Object? v) => v == 'vertical' ? Axis.vertical : Axis.horizontal;

const _wrapAlignment = <String, WrapAlignment>{
  'start': WrapAlignment.start,
  'end': WrapAlignment.end,
  'center': WrapAlignment.center,
  'spaceBetween': WrapAlignment.spaceBetween,
  'spaceAround': WrapAlignment.spaceAround,
  'spaceEvenly': WrapAlignment.spaceEvenly,
};

/// Alinhamento de Wrap (usado por `alignment` e `runAlignment`).
WrapAlignment wrapAlignmentFrom(Object? v) =>
    _wrapAlignment[v] ?? WrapAlignment.start;

const _wrapCross = <String, WrapCrossAlignment>{
  'start': WrapCrossAlignment.start,
  'end': WrapCrossAlignment.end,
  'center': WrapCrossAlignment.center,
};
WrapCrossAlignment wrapCrossFrom(Object? v) =>
    _wrapCross[v] ?? WrapCrossAlignment.start;
