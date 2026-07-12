/// Formatação de data/hora para exibição — Dart puro, sem `intl`.
///
/// O backend devolve timestamps em UTC (ISO 8601 com `Z`); aqui convertemos
/// para o fuso local antes de exibir, no formato brasileiro `dd/MM/yyyy HH:mm`.
class DateFormatUtil {
  const DateFormatUtil._();

  /// `2026-07-12T12:15:00Z` → `12/07/2026 09:15` (no fuso local).
  static String dayMonthYearHourMinute(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = _two(local.day);
    final month = _two(local.month);
    final year = local.year.toString().padLeft(4, '0');
    final hour = _two(local.hour);
    final minute = _two(local.minute);
    return '$day/$month/$year $hour:$minute';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
