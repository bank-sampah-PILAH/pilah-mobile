import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';

/// Hosts [child] in the same shape the real pages use: a RefreshIndicator
/// filling the remaining space of a Column (i.e. bounded height).
Widget _host({required Widget child, required Future<void> Function() onRefresh}) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 100), // stand-in for the page header
          Expanded(
            child: RefreshIndicator(onRefresh: onRefresh, child: child),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('EmptyView', () {
    testWidgets('pull-to-refresh fires even though the content never overflows',
        (tester) async {
      var refreshCount = 0;

      await tester.pumpWidget(_host(
        onRefresh: () async => refreshCount++,
        child: const EmptyView(
          title: 'Belum Ada Nasabah',
          subtitle: 'Tekan tombol + untuk menambah nasabah pertama.',
          icon: Icons.people_outline,
        ),
      ));

      expect(find.text('Belum Ada Nasabah'), findsOneWidget);
      expect(refreshCount, 0);

      await tester.fling(find.text('Belum Ada Nasabah'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(refreshCount, 1, reason: 'an empty state must still be pullable');
    });

    testWidgets('renders content without overflowing its bounded viewport',
        (tester) async {
      await tester.pumpWidget(_host(
        onRefresh: () async {},
        child: const EmptyView(title: 'Belum Ada Transaksi'),
      ));

      // pumpWidget throws on a RenderFlex overflow, so reaching here without
      // an exception is the assertion; confirm it actually laid out too.
      expect(tester.takeException(), isNull);
      expect(find.text('Belum Ada Transaksi'), findsOneWidget);
    });
  });
}
