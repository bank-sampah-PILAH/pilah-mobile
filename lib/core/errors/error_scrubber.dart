/// Cleans the text of an error before it leaves the app.
///
/// An error message often carries what was being handled when it was thrown:
/// a name, an email address, a phone number, a token, an amount. None of that
/// may reach the monitoring service, so every message goes through here first.
abstract final class ErrorScrubber {
  /// The longest message sent; the rest is cut off.
  static const maxLength = 200;

  static final _email = RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+');
  static final _phone = RegExp(r'\+?\d[\d\s-]{6,}\d');

  /// `Bearer <anything>` and a bare JWT (three base64url parts, the first two
  /// starting with `eyJ`, which is `{"` encoded).
  static final _token = RegExp(
    r'Bearer\s+[\w.~+/-]+=*|eyJ[\w-]+\.eyJ[\w-]+\.[\w-]+',
    caseSensitive: false,
  );

  /// `Rp 1.500.000`, `Rp250.000,50`.
  static final _money = RegExp(r'Rp\s?\d[\d.,]*', caseSensitive: false);

  static String clean(String text) {
    var out = text
        .replaceAll(_token, '[token]')
        .replaceAll(_money, '[uang]')
        .replaceAll(_email, '[email]')
        .replaceAll(_phone, '[angka]');
    if (out.length > maxLength) out = out.substring(0, maxLength);
    return out;
  }
}
