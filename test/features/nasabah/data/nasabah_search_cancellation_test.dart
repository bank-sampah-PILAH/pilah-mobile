import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/data/datasources/nasabah_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/nasabah/data/repositories/nasabah_repository_impl.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_usecase.dart';

import '../../../support/nasabah_support.dart';
import '../../../support/stub_api.dart';

void main() {
  testWidgets('cancellation reaches Dio through the real customer search stack',
      (tester) async {
    final api = StubApi()
      ..on('GET', '/api/v1/nasabah', json: nasabahPage([]))
      ..latency = const Duration(seconds: 5);
    final useCase = GetNasabahUseCase(
      NasabahRepositoryImpl(NasabahRemoteDataSourceImpl(api.network)),
    );
    final token = CancelToken();
    NetworkException? failure;
    var completed = false;
    final request = useCase
        .execute(GetNasabahParams(
      search: '000123',
      cancelToken: token,
    ))
        .then((result) {
      result.fold(
          (error) => failure = error, (_) => fail('Expected cancellation'));
      completed = true;
    });
    for (var frame = 0; frame < 10 && api.requests.isEmpty; frame++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(api.requests, hasLength(1));
    token.cancel('Superseded');
    for (var frame = 0; frame < 10 && !completed; frame++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(completed, isTrue, reason: 'must not wait for the delayed response');
    expect(failure, isA<RequestCancelled>());
    await request;
    await tester.pump(const Duration(seconds: 5));
    expect(api.requests, hasLength(1),
        reason: 'cancellation must not be retried');
  });
}
