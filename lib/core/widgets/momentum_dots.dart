import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Live-sim momentum footer: 5 dots, solid green fills for strong
/// moves, the latest filled dot pulses, caption in mid. This is the
/// ONLY mid-call progress signal; never a live score.
class MomentumDots extends StatefulWidget {
  const MomentumDots({
    super.key,
    required this.filled,
    this.caption,
  });

  /// Strong moves logged this call, 0 to 5.
  final int filled;

  /// e.g. '3 strong moves this call. Full score at the reveal.'
  final String? caption;

  @override
  State<MomentumDots> createState() => _MomentumDotsState();
}

class _MomentumDotsState extends State<MomentumDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate =
        !MediaQuery.of(context).disableAnimations && widget.filled > 0;
    if (animate && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!animate && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void didUpdateWidget(MomentumDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filled == 0 && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final filled = widget.filled.clamp(0, 5);

    return Semantics(
      label: '$filled of 5 strong moves this call',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 5; i++) ...[
              if (i > 0) SizedBox(width: sp.sp2),
              _dot(colors, index: i, filled: filled),
            ],
            if (widget.caption != null) ...[
              SizedBox(width: sp.sp3),
              Flexible(
                child: Text(
                  widget.caption!,
                  style: ClosType.style(
                    fontSize: 12,
                    weight: FontWeight.w400,
                    color: colors.mid,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dot(ClosColors colors, {required int index, required int filled}) {
    final isFilled = index < filled;
    final isLatest = isFilled && index == filled - 1;

    Widget dot = DecoratedBox(
      decoration: BoxDecoration(
        color: isFilled ? colors.green : colors.dim3,
        shape: BoxShape.circle,
      ),
      child: const SizedBox(width: 8, height: 8),
    );

    if (isLatest) {
      dot = AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_pulse.value);
          return Opacity(
            opacity: 1 - 0.45 * t,
            child: Transform.scale(scale: 1 + 0.25 * t, child: child),
          );
        },
        child: dot,
      );
    }
    return dot;
  }
}
