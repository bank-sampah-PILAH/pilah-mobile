import 'package:pilah_mobile/core/errors/error_scrubber.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// The `beforeSend` step that cleans the message of an `$exception` event, so
/// whatever put it there (our reporter, or the SDK's own capture) is cleaned.
///
/// An exception event in a shape nobody planned for cannot be cleaned, and
/// sending it as it is would defeat the point, so it is dropped (`null`).
///
/// Events the native SDKs capture by themselves, such as a Java crash, never
/// pass through here: they leave without being cleaned.
PostHogEvent? scrubExceptionEvent(PostHogEvent event) {
  if (event.event != r'$exception') return event;
  final list = event.properties?[r'$exception_list'];
  if (list is! List) return null;
  for (final entry in list) {
    if (entry is! Map) return null;
    final value = entry['value'];
    if (value is String) entry['value'] = ErrorScrubber.clean(value);
  }
  return event;
}
