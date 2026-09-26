import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';

/// Client-side mirror of the backend rules, so the form can react before
/// submitting. The backend stays the authority and re-checks every rule.
class PencairanValidator {
  const PencairanValidator._();

  static String? nominal(int? nominal, {required int saldo}) {
    if (nominal == null) return 'Nominal wajib diisi';
    if (nominal <= 0) return 'Nominal harus lebih dari nol';
    if (nominal > saldo) return 'Maksimal Rp ${formatRupiahId(saldo)}';
    return null;
  }

  /// An edit can move saldo either way, so the backend's recompute is the
  /// only authority on whether it is covered; locally, just a positive value.
  static String? nominalEdit(int? nominal) {
    if (nominal == null) return 'Nominal wajib diisi';
    if (nominal <= 0) return 'Nominal harus lebih dari nol';
    return null;
  }
}
