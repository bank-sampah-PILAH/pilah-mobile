import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/route_patterns.dart';

Widget _page(BuildContext _, GoRouterState __) => const SizedBox();

void main() {
  test('nested routes are listed with the path of every parent in front', () {
    final patterns = routePatternsOf([
      GoRoute(path: '/dashboard', builder: _page),
      GoRoute(
        path: '/nasabah',
        builder: _page,
        routes: [
          GoRoute(path: 'new', builder: _page),
          GoRoute(
            path: ':id',
            builder: _page,
            routes: [GoRoute(path: 'transaksi/:transaksiId', builder: _page)],
          ),
        ],
      ),
    ]);

    expect(patterns, [
      '/dashboard',
      '/nasabah',
      '/nasabah/new',
      '/nasabah/:id',
      '/nasabah/:id/transaksi/:transaksiId',
    ]);
  });

  test('a shell adds no path of its own, its pages are listed as they are', () {
    final patterns = routePatternsOf([
      ShellRoute(
        builder: (_, __, child) => child,
        routes: [GoRoute(path: '/laporan', builder: _page)],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => shell,
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/profil', builder: _page)],
          ),
        ],
      ),
    ]);

    expect(patterns, ['/laporan', '/profil']);
  });
}
