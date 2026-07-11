import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Standalone (no-sidebar) frame for the billing screens: the brand
/// ring in a slim topbar over a scrollable centered body. With a
/// [title] the bar is left-aligned with a divider and an optional close
/// action (16-billing-upgrade.png); without one the mark sits centered
/// (17-session-limit.png, 18-upgrade-success.png).
class BillingShell extends StatelessWidget {
  const BillingShell({
    super.key,
    this.title,
    this.onClose,
    required this.maxWidth,
    required this.child,
  });

  final String? title;

  /// Renders the topbar close control when set.
  final VoidCallback? onClose;
  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    final bar = title == null
        ? const Center(child: CloseroMark())
        : Row(
            children: [
              const CloseroMark(),
              SizedBox(width: sp.sp4),
              Container(width: 1, height: 16, color: colors.border2),
              SizedBox(width: sp.sp4),
              Expanded(
                child: Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClosType.style(
                    fontSize: 13,
                    weight: FontWeight.w600,
                    color: colors.mid,
                  ),
                ),
              ),
              if (onClose != null) _CloseButton(onTap: onClose!),
            ],
          );

    return ClosScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: sp.sp6, vertical: sp.sp3),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: bar,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(sp.sp6, sp.sp16, sp.sp6, sp.sp16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: child,
                ),
              ),
            ),
          ),
        ],
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Center(
              child: IconTheme.merge(
                data: IconThemeData(
                  color: _hovered ? colors.hi2 : colors.dim1,
                  size: 15,
                ),
                child: const ExcludeSemantics(child: CloseIcon()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
