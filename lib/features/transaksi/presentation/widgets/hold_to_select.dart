import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';

/// Menahan [child] selama [duration] memilihnya. Bawaannya sama dengan long
/// press sistem (setengah detik), seperti memilih chat di WhatsApp. Selama ditahan, warna hijau
/// mengisi dari kiri ke kanan; melepas atau menggeser jari sebelum penuh
/// membatalkan, dan sebuah ketukan biasa tetap sampai ke [child].
class HoldToSelect extends StatefulWidget {
  const HoldToSelect({
    super.key,
    required this.child,
    required this.onSelected,
    this.enabled = true,
    this.bleed = 0,
    this.duration = kLongPressTimeout,
  });

  final Widget child;
  final VoidCallback onSelected;

  /// Mati saat baris sudah dalam mode pilih atau memang tidak bisa dipilih.
  final bool enabled;

  /// Seberapa jauh warna isian keluar dari [child] ke kiri dan kanan, supaya
  /// sama dengan warna baris yang sudah terpilih.
  final double bleed;
  final Duration duration;

  @override
  State<HoldToSelect> createState() => _HoldToSelectState();
}

class _HoldToSelectState extends State<HoldToSelect>
    with SingleTickerProviderStateMixin {
  static const _slop = 18.0;

  late final AnimationController _fill;
  Offset? _start;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        HapticFeedback.mediumImpact();
        _fill.value = 0;
        widget.onSelected();
      });
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  void _cancel() {
    _start = null;
    if (_fill.isAnimating || _fill.value > 0) _fill.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      onPointerDown: (event) {
        _start = event.position;
        _fill.forward(from: 0);
      },
      onPointerMove: (event) {
        final start = _start;
        if (start != null && (event.position - start).distance > _slop) {
          _cancel();
        }
      },
      onPointerUp: (_) => _cancel(),
      onPointerCancel: (_) => _cancel(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          Positioned(
            top: 0,
            bottom: 0,
            left: -widget.bleed,
            right: -widget.bleed,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _fill,
                builder: (context, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _fill.value,
                  child: DecoratedBox(
                    key: const ValueKey('hold-to-select-fill'),
                    decoration: BoxDecoration(
                      color: AppColors.greenDark.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
