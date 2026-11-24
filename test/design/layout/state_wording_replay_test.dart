import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/privacy/replay_privacy.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/design/layout/page_state_view.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';

import '../../support/pump_app.dart';

/// The wording of the empty, failed and filter states is fixed by the app, so
/// the screen recording shows it. A subtitle or a message can come from the
/// server, so those stay hidden.
void main() {
  Finder revealed(Finder text) => find.ancestor(
        of: text,
        matching: find.byType(RevealInReplay),
      );

  testWidgets('an empty view shows its title and hides its subtitle',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: EmptyView(
          title: 'Belum ada nasabah',
          subtitle: 'Pesan dari server',
        ),
      ),
    ));

    expect(revealed(find.text('Belum ada nasabah')), findsOneWidget);
    expect(revealed(find.text('Pesan dari server')), findsNothing);
  });

  testWidgets('the retry button of a failed page is shown, its message is not',
      (tester) async {
    await pumpRouted(
      tester,
      Scaffold(
        body: PageStateView(
          state: PageState.error,
          emptyTitle: 'Belum ada nasabah',
          errorMessage: 'Gagal memuat Budi Santoso',
          onRetry: () {},
          child: const SizedBox.expand(),
        ),
      ),
      size: const Size(1440, 900),
    );

    expect(revealed(find.text('Coba lagi')), findsOneWidget);
    expect(revealed(find.text('Gagal memuat Budi Santoso')), findsNothing);
  });

  testWidgets('a filter chip shows its label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppChip(label: 'Aktif', selected: true, onTap: () {}),
      ),
    ));

    expect(revealed(find.text('Aktif')), findsOneWidget);
  });
}
