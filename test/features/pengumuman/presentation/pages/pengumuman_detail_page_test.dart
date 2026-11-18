import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart'
    show nasabahDate;
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_detail_page.dart';

void main() {
  Widget page(PengumumanEntity pengumuman) =>
      MaterialApp(home: PengumumanDetailPage(pengumuman: pengumuman));

  testWidgets('shows the title, full body, and the publish date when set',
      (tester) async {
    await tester.pumpWidget(page(PengumumanEntity(
      id: '1',
      bankSampahId: 'b1',
      judul: 'Kerja bakti',
      isi: 'Isi lengkap pengumuman.',
      terbitPada: DateTime(2026, 10, 15, 3),
      bankSampahNama: 'Bank Sampah Melati',
      bankSampahKota: 'Depok',
    )));

    expect(find.text('Kerja bakti'), findsOneWidget);
    expect(find.text('Isi lengkap pengumuman.'), findsOneWidget);
    expect(find.text(nasabahDate(DateTime(2026, 10, 15, 3))), findsOneWidget);
    // Bank identity line joins the known fields with a dot separator.
    expect(find.text('Bank Sampah Melati · Depok'), findsOneWidget);
  });

  testWidgets('a row without terbit_pada omits the date line', (tester) async {
    await tester.pumpWidget(page(const PengumumanEntity(
      id: '1',
      bankSampahId: 'b1',
      judul: 'Tanpa jadwal',
      isi: 'Isi.',
    )));

    expect(find.text('Tanpa jadwal'), findsOneWidget);
    expect(find.text('Isi.'), findsOneWidget);
  });
}
