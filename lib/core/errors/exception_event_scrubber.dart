import 'package:posthog_flutter/posthog_flutter.dart';

/// The `beforeSend` step that keeps the message of an `$exception` event from
/// leaving the app: each exception is reduced to its type, whatever put it
/// there (our reporter, or the SDK's own capture).
///
/// The message of an exception can hold a name, an amount or an address that
/// was being handled, and no pattern can tell those from ordinary text. The type
/// and the stack are what a developer needs, and neither holds such data.
///
/// An exception event in a shape nobody planned for (no list, an empty one), or
/// one with no type to put in place of the message, cannot be made safe, so it
/// is dropped (`null`).
///
/// Native crash capture is kept off (see `PosthogMobileClient`) because those
/// events would not pass through here.
PostHogEvent? scrubExceptionEvent(PostHogEvent event) {
  if (event.event != r'$exception') return event;
  final list = event.properties?[r'$exception_list'];
  if (list is! List || list.isEmpty) return null;
  for (final entry in list) {
    if (entry is! Map) return null;
    final type = entry['type'];
    if (type is! String || type.isEmpty) return null;
    entry['value'] = type;
  }
  return event;
}
