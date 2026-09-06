/// Formats a waste weight (kg) for display in the Indonesian locale.
///
/// One home for every on-screen weight so the app reads consistently: rounds to
/// at most two decimals, trims unnecessary trailing zeros, and uses a comma as
/// the decimal separator.
///
///   2      -> "2"
///   2.5    -> "2,5"
///   10.125 -> "10,13"
///   0.05   -> "0,05"
///
/// The returned string carries **no unit** — callers append `" kg"` themselves,
/// so the number can sit inside any sentence.
///
/// This shapes display text only. Domain values, cubit state, and API DTOs keep
/// their `double`/dot-decimal form; nothing here feeds a calculation or payload.
class WeightFormatter {
  const WeightFormatter._();

  /// Accepts a [num] or a numeric [String] (dot-decimal, as the API sends).
  /// Anything unparseable formats as `"0"`.
  static String formatKg(Object? value) {
    final berat = _asDouble(value);
    final sign = berat.isNegative ? '-' : '';
    // Round in integer hundredths so the 2-decimal result never depends on the
    // platform's float-to-string tie-breaking — `10.125` must land on `13`, and
    // `int.round()` rounds halves away from zero to match the backend's
    // ROUND_HALF_UP.
    final centi = (berat.abs() * 100).round();
    final whole = centi ~/ 100;
    final frac = centi % 100;
    if (frac == 0) return '$sign$whole';
    // "05" keeps its leading zero (0,05); a trailing zero is padding (50 -> 5).
    final fraction =
        frac.toString().padLeft(2, '0').replaceAll(RegExp(r'0+$'), '');
    return '$sign$whole,$fraction';
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().trim() ?? '') ?? 0;
  }
}
