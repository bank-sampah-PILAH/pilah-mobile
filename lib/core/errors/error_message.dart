import 'package:pilah_mobile/core/errors/error_scrubber.dart';
import 'package:pilah_mobile/core/errors/error_type_name.dart';

/// The text sent with an error: its own message, cleaned.
abstract final class ErrorMessage {
  static String of(Object error) {
    final text = error.toString();
    // The default text of an object, `Instance of 'X'`, holds the class name,
    // which a release web build has shortened. The stable name says more.
    if (text.startsWith('Instance of ')) return ErrorTypeName.of(error);
    return ErrorScrubber.clean(text);
  }
}
