import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_detail_page.dart';

PengumumanEntity _entity({DateTime? terbitPada}) => PengumumanEntity(
      id: '1',
      bankSampahId: 'b',
      judul: 'Kerja bakti',
      isi: 'Isi lengkap.',
      terbitPada: terbitPada,
    );

void main() {
  testWidgets('shows the title, publish date and full body', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PengumumanDetailPage(
        pengumuman: _entity(terbitPada: DateTime.utc(2026, 10, 15, 3)),
      ),
    ));

    expect(find.text('Kerja bakti'), findsOneWidget);
    expect(find.text('Isi lengkap.'), findsOneWidget);
    // Rendered in local time, padded to two digits.
    expect(find.text('15/10/2026'), findsOneWidget);
  });

  testWidgets('omits the date row when terbitPada is null', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PengumumanDetailPage(pengumuman: _entity()),
    ));

    expect(find.text('Kerja bakti'), findsOneWidget);
    expect(find.text('15/10/2026'), findsNothing);
  });
}
