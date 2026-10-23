import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:pilah_mobile/design/widgets/nasabah_page_app_bar.dart';

import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart'
    show nasabahDate;
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/nasabah_pengumuman_state.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_detail_page.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/providers/nasabah_pengumuman_provider.dart';

/// The nasabah's announcement list (PIL-244). Latest first, one card per
/// announcement, unread rows carry a dot; tap marks it read and opens the
/// detail.
class PengumumanPage extends ConsumerWidget {
  const PengumumanPage({super.key, this.membershipId});

  static const route = '/pengumuman';

  final String? membershipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authenticationProvider);
    final auth = state is Authenticated ? state.authEntity : null;
    if (auth?.role != 'nasabah') {
      return const Scaffold(
        body: Center(child: Text('Silakan masuk sebagai nasabah.')),
      );
    }
    return _PengumumanListBody(
      key: ValueKey((auth!.id, auth.email, membershipId)),
      membershipId: membershipId,
    );
  }
}

class _PengumumanListBody extends ConsumerStatefulWidget {
  const _PengumumanListBody({super.key, this.membershipId});

  final String? membershipId;

  @override
  ConsumerState<_PengumumanListBody> createState() =>
      _PengumumanListBodyState();
}

class _PengumumanListBodyState extends ConsumerState<_PengumumanListBody> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadNextPageNearEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(nasabahPengumumanProvider.notifier)
            .load(membershipId: widget.membershipId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadNextPageNearEnd)
      ..dispose();
    super.dispose();
  }

  void _loadNextPageNearEnd() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 320) {
      return;
    }
    ref.read(nasabahPengumumanProvider.notifier).loadNextPage();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nasabahPengumumanProvider);
    final notifier = ref.read(nasabahPengumumanProvider.notifier);
    return Scaffold(
      backgroundColor: NasabahStyle.background,
      appBar: const NasabahPageAppBar(
        title: 'Pengumuman',
        showBack: true,
      ),
      body: switch (state.status) {
        NasabahPengumumanStatus.initial ||
        NasabahPengumumanStatus.loading =>
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SkeletonListItem(),
                SizedBox(height: 12),
                SkeletonListItem(),
                SizedBox(height: 12),
                SkeletonListItem(),
              ],
            ),
          ),
        NasabahPengumumanStatus.failure => Column(
            children: [
              Expanded(
                child: EmptyView(
                  title: 'Gagal Memuat Data',
                  subtitle: state.error,
                  icon: Icons.error_outline,
                ),
              ),
              TextButton(
                onPressed: () => notifier.load(
                  membershipId: widget.membershipId,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        NasabahPengumumanStatus.loaded => state.items.isEmpty
            ? const EmptyView(
                title: 'Belum ada pengumuman',
                subtitle:
                    'Pengumuman dari bank sampah Anda akan muncul di sini.',
                icon: Icons.campaign_outlined,
              )
            : AppRefreshIndicator(
                onRefresh: () => notifier.load(
                  membershipId: widget.membershipId,
                  silent: true,
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _PengumumanRow(
                      key: ValueKey('pengumuman-${state.items[index].id}'),
                      pengumuman: state.items[index],
                    );
                  },
                ),
              ),
      },
    );
  }
}

class _PengumumanRow extends ConsumerWidget {
  const _PengumumanRow({super.key, required this.pengumuman});

  final PengumumanEntity pengumuman;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NasabahCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () async {
            final router = GoRouter.of(context);
            await ref
                .read(nasabahPengumumanProvider.notifier)
                .tandaiDibaca(pengumuman.id);
            await router.push(
              '${PengumumanDetailPage.route}?id=${Uri.encodeComponent(pengumuman.id)}',
              extra: pengumuman,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pengumuman.judul,
                        style: NasabahStyle.text(15, weight: FontWeight.w600),
                      ),
                    ),
                    if (!pengumuman.dibaca)
                      Container(
                        key: const ValueKey('pengumuman-belum-dibaca'),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: NasabahStyle.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  pengumuman.isi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: NasabahStyle.text(13, color: NasabahStyle.muted),
                ),
                const SizedBox(height: 8),
                if (pengumuman.terbitPada != null)
                  Text(
                    nasabahDate(pengumuman.terbitPada!),
                    style: NasabahStyle.text(11, color: NasabahStyle.muted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
