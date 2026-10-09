import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

import '../blocs/draft_editor_state.dart';
import 'draft_format.dart';

/// The totals of a draft, pinned above the action buttons so they stay in view
/// while the nasabah list scrolls and is edited. Closed it shows only what is
/// paid out; tapped, or swiped up, it also shows the pencairan and potongan.
/// [aksi] is the row of buttons beneath, or null for a draft that is final.
class EditorSummaryPanel extends StatefulWidget {
  final DraftEditorState state;
  final Widget? aksi;

  const EditorSummaryPanel({super.key, required this.state, this.aksi});

  @override
  State<EditorSummaryPanel> createState() => _EditorSummaryPanelState();
}

class _EditorSummaryPanelState extends State<EditorSummaryPanel> {
  static const _emerald = Color(0xFF006D44);
  bool _terbuka = false;

  void _atur(bool terbuka) => setState(() => _terbuka = terbuka);

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Container(
      key: const Key('ringkasan-panel'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              key: const Key('ringkasan-toggle'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _atur(!_terbuka),
              onVerticalDragEnd: (detail) {
                final kecepatan = detail.primaryVelocity ?? 0;
                if (kecepatan < -100) _atur(true);
                if (kecepatan > 100) _atur(false);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Total dibayar',
                          style: AppTextStyle.small
                              .copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              rupiah(state.totalDibayar),
                              key: const Key('total-dibayar'),
                              style: AppTextStyle.headline1.copyWith(
                                color: _emerald,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _terbuka
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _terbuka
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Column(
                        children: [
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 12),
                          _Baris(
                            label: 'Total pencairan',
                            nilai: rupiah(state.totalNominal),
                            nilaiKey: const Key('total-nominal'),
                          ),
                          const SizedBox(height: 8),
                          _Baris(
                            label: 'Total potongan',
                            nilai: state.totalPotongan > 0
                                ? '− ${rupiah(state.totalPotongan)}'
                                : rupiah(state.totalPotongan),
                            nilaiKey: const Key('total-potongan'),
                            warna: state.totalPotongan > 0
                                ? AppColors.statOrange
                                : null,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            if (widget.aksi != null) widget.aksi!,
          ],
        ),
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  final String label;
  final String nilai;
  final Key nilaiKey;
  final Color? warna;

  const _Baris({
    required this.label,
    required this.nilai,
    required this.nilaiKey,
    this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyle.small.copyWith(color: Colors.grey[500]),
          ),
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              nilai,
              key: nilaiKey,
              style: AppTextStyle.title1.copyWith(
                color: warna ?? Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
