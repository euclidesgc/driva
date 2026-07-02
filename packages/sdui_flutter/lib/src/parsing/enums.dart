import 'package:flutter/widgets.dart';

/// Conversores de enum (string do spec → enum Flutter), com o default do
/// catálogo embutido como fallback.

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
