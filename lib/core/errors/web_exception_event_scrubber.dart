import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:pilah_mobile/core/errors/error_scrubber.dart';

/// The `before_send` step of posthog-js for an `$exception` event: the web
/// counterpart of `scrubExceptionEvent`, in the shape the browser library
/// uses. It lives with the other error code so that a change to what leaves
/// the app on an error is made in one package, not in the analytics client.
///
/// What posthog-js is about to send, handed over just before. An exception
/// carries the message of the error, which can hold a name, an address or a
/// token, so the message of every `$exception` is cleaned here, whatever
/// put it there. Every other event passes untouched.
JSAny? scrubWebExceptionEvent(JSAny? captureResult) {
  if (captureResult == null) return null;
  try {
    final result = captureResult as JSObject;
    if (result.getProperty<JSAny?>('event'.toJS).dartify() != r'$exception') {
      return captureResult;
    }
    final properties = result.getProperty<JSObject?>('properties'.toJS);
    final list =
        properties?.getProperty<JSArray<JSObject>?>(r'$exception_list'.toJS);
    // posthog-js calls every error it is handed "handled". The reporter says
    // when nobody caught it, and this is the only place the flag can change.
    final notHandled =
        properties?.getProperty<JSAny?>('ditangani'.toJS).dartify() == false;
    for (final entry in list?.toDart ?? const <JSObject>[]) {
      final value = entry.getProperty<JSAny?>('value'.toJS).dartify();
      if (value is String) {
        entry.setProperty('value'.toJS, ErrorScrubber.clean(value).toJS);
      }
      if (notHandled) {
        final mechanism = entry.getProperty<JSObject?>('mechanism'.toJS);
        mechanism?.setProperty('handled'.toJS, false.toJS);
      }
    }
    if (notHandled) {
      properties?.setProperty(r'$exception_handled'.toJS, false.toJS);
    }
    return captureResult;
  } catch (_) {
    // An exception event in a shape nobody planned for cannot be cleaned,
    // and sending it as it is would defeat the point: drop it instead.
    return null;
  }
}
