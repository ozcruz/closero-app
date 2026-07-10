import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Shows a [ClosModal] (or any dialog content) over a dimmed base
/// barrier. Returns the dialog result.
Future<T?> showClosModal<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final colors = context.closColors;
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: colors.base.withValues(alpha: 0.72),
    builder: builder,
  );
}

/// The base modal surface: surface bg, primary border, card radius,
/// optional full-bleed header (e.g. an AvatarStack) and a close
/// control in the top corner. Screen-level modals (Scenario Preview)
/// assemble on top of this.
class ClosModal extends StatelessWidget {
  const ClosModal({
    super.key,
    required this.child,
    this.header,
    this.onClose,
    this.maxWidth = 480,
    this.padding,
  });

  /// Modal body, laid out under [header].
  final Widget child;

  /// Optional full-bleed header area above the body.
  final Widget? header;

  /// Renders the close control when set.
  final VoidCallback? onClose;

  final double maxWidth;

  /// Body padding; defaults to sp6 on all sides.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
              borderRadius: context.closRadius.cardRadius,
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ?header,
                    Padding(
                      padding: padding ?? EdgeInsets.all(sp.sp6),
                      child: child,
                    ),
                  ],
                ),
                if (onClose != null)
                  Positioned(
                    top: sp.sp1,
                    right: sp.sp1,
                    child: _CloseButton(onTap: onClose!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    return Semantics(
      button: true,
      label: 'Close',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: CustomPaint(
                size: const Size(12, 12),
                painter: _CrossPainter(
                  color: _hovered ? colors.hi2 : colors.dim2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final w = size.width / 12;
    final h = size.height / 12;
    canvas.drawLine(Offset(2 * w, 2 * h), Offset(10 * w, 10 * h), paint);
    canvas.drawLine(Offset(10 * w, 2 * h), Offset(2 * w, 10 * h), paint);
  }

  @override
  bool shouldRepaint(_CrossPainter oldDelegate) => oldDelegate.color != color;
}
