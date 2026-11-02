import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_destinations.dart';

/// The destination list is about to gain a second renderer (a navigation rail
/// for wide windows) beside the existing bottom bar. Both must read the same
/// source, so that adding a form factor can never silently change *which*
/// destinations a role has.
///
/// These expectations are deliberately the ones already asserted indirectly by
/// role_navigation_test.dart through the rendered bottom bar; pinning them to
/// the source directly is what lets the second renderer be trusted.
void main() {
  group('RoleDestinations.forRole', () {
    test('staff get the five operational destinations in order', () {
      final staff = RoleDestinations.forRole('pengelola');
      expect(staff.map((d) => d.label), [
        'Dashboard',
        'Nasabah',
        'Harga',
        'Aktivitas',
        'Jadwal',
      ]);
      expect(staff.map((d) => d.branchIndex), [0, 1, 2, 3, 4]);
    });

    test('Pengumuman is not a staff destination at all', () {
      final staff = RoleDestinations.forRole('pengelola');
      expect(
        staff.map((d) => d.label),
        isNot(contains('Pengumuman')),
        reason: 'PIL-436 removes the entry point instead of disabling it, so '
            'no dead menu is left for Pengurus to see',
      );
      expect(staff.map((d) => d.branchIndex), isNot(contains(8)));
      expect(
          staff.map((d) => d.icon), isNot(contains(Icons.campaign_outlined)));
    });

    test('the bottom bar keeps all five staff destinations', () {
      final bar = RoleDestinations.forRole('pengelola', bottomBar: true);
      expect(bar.map((d) => d.label),
          ['Dashboard', 'Nasabah', 'Harga', 'Aktivitas', 'Jadwal']);
      expect(RoleDestinations.branchIndicesFor('pengelola', bottomBar: true),
          [0, 1, 2, 3, 4]);
      expect(RoleDestinations.forRole('nasabah', bottomBar: true).length, 4,
          reason: 'nasabah destinations are all in the bottom bar');
    });

    test('pengelola_induk sees the same destinations as pengelola', () {
      expect(
        RoleDestinations.forRole('pengelola_induk').map((d) => d.branchIndex),
        RoleDestinations.forRole('pengelola').map((d) => d.branchIndex),
      );
    });

    test('an approved nasabah gets four destinations', () {
      final nasabah = RoleDestinations.forRole('nasabah');
      expect(nasabah.map((d) => d.label),
          ['Beranda', 'Tabungan', 'Jadwal', 'Profil']);
      expect(nasabah.map((d) => d.branchIndex), [0, 5, 4, 7]);
    });

    test('a nasabah awaiting approval only gets Beranda and Profil', () {
      final limited = RoleDestinations.forRole('nasabah', limitedNasabah: true);
      expect(limited.map((d) => d.label), ['Beranda', 'Profil']);
      expect(limited.map((d) => d.branchIndex), [0, 7]);
    });

    test('an unknown role gets nothing rather than a default menu', () {
      expect(RoleDestinations.forRole('superadmin'), isEmpty);
      expect(RoleDestinations.forRole(null), isEmpty);
      expect(RoleDestinations.forRole('tukang-kebun'), isEmpty);
    });

    test('limitedNasabah does not narrow a staff menu', () {
      expect(
        RoleDestinations.forRole('pengelola', limitedNasabah: true).length,
        5,
        reason: 'the flag only describes a nasabah membership state',
      );
    });

    test('every destination carries an icon and a non-empty label', () {
      for (final role in ['pengelola', 'pengelola_induk', 'nasabah']) {
        for (final destination in RoleDestinations.forRole(role)) {
          expect(destination.icon, isA<IconData>());
          expect(destination.label, isNotEmpty);
        }
      }
    });
  });
}
