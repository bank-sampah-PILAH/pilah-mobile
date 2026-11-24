import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// The `before_send` step of posthog-js for an `$exception` event: the web
/// counterpart of `scrubExceptionEvent`, in the shape the browser library
/// uses. It lives with the other error code so that a change to what leaves
/// the app on an error is made in one package, not in the analytics client.
///
/// What posthog-js is about to send, handed over just before. An exception
/// carries the message of the error, which can hold a name, an amount or an
/// address, so every `$exception` is reduced to its type here, whatever put it
/// there. An exception with no type is dropped. Every other event passes
/// untouched.
/// The name under which `PosthogWebErrorReporter` tells [scrubWebExceptionEvent]
/// that nobody caught an error. posthog-js has no way to say so itself, and the
/// marker is removed before the event is sent.
const webNotHandledMarker = '__not_handled';

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
        properties?.getProperty<JSAny?>(webNotHandledMarker.toJS).dartify() ==
            false;
    if (properties != null && properties.has(webNotHandledMarker)) {
      properties.delete(webNotHandledMarker.toJS);
    }
    for (final entry in list?.toDart ?? const <JSObject>[]) {
      final type = entry.getProperty<JSAny?>('type'.toJS).dartify();
      if (type is! String || type.isEmpty) return null;
      entry.setProperty('value'.toJS, type.toJS);
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
