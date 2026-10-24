import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_membership_content.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

/// Answers `home()` from a script, recording the membership asked for.
class _ScriptedRepository extends PreviewNasabahRepository {
  _ScriptedRepository(this.answers);

  final List<Object> answers;
  final asked = <String?>[];

  @override
  Future<NasabahHome> home({String? membershipId}) async {
    asked.add(membershipId);
    final answer = answers.removeAt(0);
    if (answer is Exception) throw answer;
    return super.home(membershipId: answer as String);
  }
}

void main() {
  late _ScriptedRepository repository;

  Future<void> pumpContent(WidgetTester tester, List<Object> answers,
      {String? membershipId}) async {
    repository = _ScriptedRepository(answers);
    di.registerSingleton<NasabahRepository>(repository);
    addTearDown(() => di.unregister<NasabahRepository>());
    await tester.pumpWidget(MaterialApp(
      home: NasabahMembershipContent(
        membershipId: membershipId,
        builder: (id) => Text('membership:$id'),
      ),
    ));
  }

  testWidgets('uses a membership that is already known without asking',
      (tester) async {
    await pumpContent(tester, [], membershipId: 'm-given');

    expect(find.text('membership:m-given'), findsOneWidget);
    expect(repository.asked, isEmpty);
  });

  testWidgets('resolves the active membership while showing progress',
      (tester) async {
    await pumpContent(tester, ['m-active']);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('membership:m-active'), findsOneWidget);
  });

  testWidgets('lets the user choose between several banks', (tester) async {
    await pumpContent(tester, [
      const NasabahApiException('Pilih bank sampah Anda.', choices: [
        MembershipChoice('m1', 'Bank Melati'),
        MembershipChoice('m2', 'Bank Mawar'),
      ]),
      'm2',
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Pilih bank sampah Anda.'), findsOneWidget);
    await tester.tap(find.text('Bank Mawar'));
    await tester.pumpAndSettle();

    expect(repository.asked, [null, 'm2']);
    expect(find.text('membership:m2'), findsOneWidget);
  });

  testWidgets('offers a retry after a failure that has no choices',
      (tester) async {
    await pumpContent(tester, [Exception('boom'), 'm-active']);
    await tester.pumpAndSettle();

    expect(find.text('Data gagal dimuat. Silakan coba lagi.'), findsOneWidget);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.text('membership:m-active'), findsOneWidget);
  });
}
