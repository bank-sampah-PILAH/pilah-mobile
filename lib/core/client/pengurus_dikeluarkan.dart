import 'dart:async';

import 'package:dio/dio.dart';

/// The machine-readable `code` the backend puts on the 403 it answers a pengurus
/// with once the Pengurus Utama has removed them from the bank sampah.
const pengurusDikeluarkanCode = 'pengurus_dikeluarkan';

/// Shown when the refusal carries the code but no message of its own.
const pengurusDikeluarkanFallbackMessage =
    'Anda sudah dikeluarkan dari bank sampah ini oleh Pengurus Utama.';

/// Announces that the signed-in pengurus has been removed from their bank
/// sampah. Whatever request notices first raises it; the app shell listens, so
/// the user is sent away wherever they happened to be.
abstract final class PengurusDikeluarkanSignal {
  static final _controller = StreamController<String>.broadcast(sync: true);

  /// The message to show the user, once per refusal.
  static Stream<String> get stream => _controller.stream;

  static void raise(String message) => _controller.add(message);
}

/// Watches every response for the removal refusal and raises
/// [PengurusDikeluarkanSignal]. The error itself carries on to the caller
/// unchanged.
class PengurusDikeluarkanInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    final data = response?.data;
    if (response?.statusCode == 403 &&
        data is Map &&
        data['code'] == pengurusDikeluarkanCode) {
      final message = data['error']?.toString();
      PengurusDikeluarkanSignal.raise(
        message == null || message.isEmpty
            ? pengurusDikeluarkanFallbackMessage
            : message,
      );
    }
    handler.next(err);
  }
}
