/// Invariantes ao tema, por isso `static const`. Calibradas pelas durações já
/// usadas: micro-transições até o wait de tooltip.
abstract final class AppDurations {
  static const Duration micro = Duration(milliseconds: 120);

  static const Duration fast = Duration(milliseconds: 160);

  static const Duration quick = Duration(milliseconds: 200);

  static const Duration normal = Duration(milliseconds: 300);

  static const Duration slow = Duration(milliseconds: 400);
}
