import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_paged_list_view.dart';

NasabahEntity _nasabah(int nomor) => NasabahEntity(
      id: 'n-$nomor',
      idNasabah: 'NAS-${nomor.toString().padLeft(4, '0')}',
      name: 'Nasabah $nomor',
      phone: '08123456789',
      balance: 'Rp 0',
      isActive: true,
      address: 'Jl. Melati',
      initials: 'NN',
      avatarColor: const Color(0xFFEAF5EC),
      textColor: const Color(0xFF2F6B45),
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '01/01/1990',
      status: 'approved',
    );

void main() {
  Widget host({
    required List<NasabahEntity> items,
    required bool hasMore,
    bool isLoadingMore = false,
    VoidCallback? onLoadMore,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: NasabahPagedListView(
              items: items,
              hasMore: hasMore,
              isLoadingMore: isLoadingMore,
              onLoadMore: onLoadMore ?? () {},
            ),
          ),
        ),
      );

  testWidgets('asks for the next page when the list is scrolled near the end',
      (tester) async {
    var diminta = 0;
    await tester.pumpWidget(host(
      items: List.generate(20, _nasabah),
      hasMore: true,
      onLoadMore: () => diminta++,
    ));

    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pump();

    expect(diminta, greaterThan(0));
  });

  testWidgets('never asks for more once the last page is shown',
      (tester) async {
    var diminta = 0;
    await tester.pumpWidget(host(
      items: List.generate(20, _nasabah),
      hasMore: false,
      onLoadMore: () => diminta++,
    ));

    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pump();

    expect(diminta, 0);
  });

  testWidgets('shows a spinner at the end while the next page is loading',
      (tester) async {
    await tester.pumpWidget(host(
      items: List.generate(3, _nasabah),
      hasMore: true,
      isLoadingMore: true,
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
