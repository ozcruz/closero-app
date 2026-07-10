import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Button sizes. Both meet the 44px minimum tap target.
enum ClosButtonSize {
  /// 46px tall, 14px label. Hero and modal CTAs.
  large,

  /// 44px tall, 13px label. In-card and settings actions.
  medium,
}

/// The one accent-filled element per view: accent fill, base text.
/// Do not place two of these on one screen.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.size = ClosButtonSize.large,
  });

  final String label;

  /// Null renders the disabled state.
  final VoidCallback? onPressed;

  /// Optional leading icon, tinted and sized by the button.
  final Widget? icon;
  final bool loading;
  final ClosButtonSize size;

  @override
  Widget build(BuildContext context) {
    return _ClosButtonBase(
      label: label,
      onPressed: onPressed,
      icon: icon,
      loading: loading,
      size: size,
      resolve: (colors, {required hovered, required pressed}) => _ButtonVisual(
        fill: pressed
            ? Color.lerp(colors.accent, colors.base, 0.08)!
            : colors.accent,
        content: colors.base,
        weight: FontWeight.w700,
        shadow: hovered && !pressed
            ? BoxShadow(
                color: colors.accent.withValues(alpha: 0.16),
                offset: const Offset(0, 6),
                blurRadius: 18,
              )
            : null,
      ),
    );
  }
}

/// Secondary action: transparent, border2 border, mid text. Never accent.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.size = ClosButtonSize.large,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;
  final ClosButtonSize size;

  @override
  Widget build(BuildContext context) {
    final weight =
        size == ClosButtonSize.large ? FontWeight.w500 : FontWeight.w600;
    return _ClosButtonBase(
      label: label,
      onPressed: onPressed,
      icon: icon,
      loading: loading,
      size: size,
      resolve: (colors, {required hovered, required pressed}) {
        final raised = hovered || pressed;
        return _ButtonVisual(
          border: BorderSide(color: raised ? colors.dim1 : colors.border2),
          content: raised ? colors.hi2 : colors.mid,
          weight: weight,
        );
      },
    );
  }
}

/// Destructive action: solid destructive fill, onDestructive text.
/// Never a red-tinted wash.
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.size = ClosButtonSize.large,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;
  final ClosButtonSize size;

  @override
  Widget build(BuildContext context) {
    return _ClosButtonBase(
      label: label,
      onPressed: onPressed,
      icon: icon,
      loading: loading,
      size: size,
      resolve: (colors, {required hovered, required pressed}) => _ButtonVisual(
        fill: pressed
            ? Color.lerp(colors.destructive, colors.base, 0.08)!
            : colors.destructive,
        content: colors.onDestructive,
        weight: FontWeight.w700,
        shadow: hovered && !pressed
            ? BoxShadow(
                color: colors.destructive.withValues(alpha: 0.16),
                offset: const Offset(0, 6),
                blurRadius: 18,
              )
            : null,
      ),
    );
  }
}

/// Resolved per-state appearance for one frame.
class _ButtonVisual {
  const _ButtonVisual({
    this.fill,
    this.border,
    required this.content,
    required this.weight,
    this.shadow,
  });

  final Color? fill;
  final BorderSide? border;
  final Color content;
  final FontWeight weight;
  final BoxShadow? shadow;
}

typedef _VisualResolver = _ButtonVisual Function(
  ClosColors colors, {
  required bool hovered,
  required bool pressed,
});

/// Shared behavior for the three buttons: eased hover lift (translateY -1px;
/// state changes snap instantly under reduced motion), pressed cancels the
/// lift, disabled dims, loading swaps in a spinner while preserving the
/// button's width, focus/keyboard activation, 44px minimum tap target.
class _ClosButtonBase extends StatefulWidget {
  const _ClosButtonBase({
    required this.label,
    required this.onPressed,
    required this.icon,
    required this.loading,
    required this.size,
    required this.resolve,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;
  final ClosButtonSize size;
  final _VisualResolver resolve;

  @override
  State<_ClosButtonBase> createState() => _ClosButtonBaseState();
}

class _ClosButtonBaseState extends State<_ClosButtonBase> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _interactive => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    final hovered = (_hovered || _focused) && _interactive;
    final pressed = _pressed && _interactive;
    final lifted = hovered && !pressed;
    final visual = widget.resolve(colors, hovered: hovered, pressed: pressed);

    final large = widget.size == ClosButtonSize.large;
    final height = large ? 46.0 : 44.0;
    final padH = large ? sp.sp6 : sp.sp5;
    final fontSize = large ? 14.0 : 13.0;

    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 200);

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          IconTheme.merge(
            data: IconThemeData(color: visual.content, size: 14),
            child: widget.icon!,
          ),
          SizedBox(width: sp.sp2),
        ],
        Text(
          widget.label,
          style: ClosType.style(
            fontSize: fontSize,
            weight: visual.weight,
            color: visual.content,
            letterSpacingEm: -0.01,
          ),
        ),
      ],
    );

    if (widget.loading) {
      content = Stack(
        alignment: Alignment.center,
        children: [
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: content,
          ),
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: visual.content,
            ),
          ),
        ],
      );
    }

    Widget button = AnimatedContainer(
      duration: duration,
      curve: Curves.fastOutSlowIn,
      transform: Matrix4.translationValues(0, lifted ? -1 : 0, 0),
      constraints:
          BoxConstraints(minWidth: 44, minHeight: height, maxHeight: height),
      padding: EdgeInsets.symmetric(horizontal: padH),
      decoration: BoxDecoration(
        color: visual.fill,
        border:
            visual.border == null ? null : Border.fromBorderSide(visual.border!),
        borderRadius: context.closRadius.buttonRadius,
        boxShadow: [if (visual.shadow != null) visual.shadow!],
      ),
      child: content,
    );

    if (!_interactive && !widget.loading) {
      button = Opacity(opacity: 0.45, child: button);
    }

    return Semantics(
      button: true,
      enabled: _interactive,
      child: FocusableActionDetector(
        enabled: _interactive,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        // Plain MouseRegion: hover must not depend on the focus
        // highlight mode, which suppresses FocusableActionDetector's
        // hover callback under touch input.
        child: MouseRegion(
          cursor: _interactive ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTapDown:
                _interactive ? (_) => setState(() => _pressed = true) : null,
            onTapUp:
                _interactive ? (_) => setState(() => _pressed = false) : null,
            onTapCancel:
                _interactive ? () => setState(() => _pressed = false) : null,
            onTap: _interactive ? widget.onPressed : null,
            child: button,
          ),
        ),
      ),
    );
  }
}
