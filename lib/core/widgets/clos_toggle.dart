import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Grayscale switch: surface2 track, dim2 thumb when off, hi1 thumb and
/// dim1 track border when on. Deliberately never accent; switches are
/// utility controls, not one of the reserved accent uses.
///
/// The visual is 36x20; the hit target is padded to the 44px minimum.
/// A [semanticLabel] is required because the control renders no text.
class ClosToggle extends StatefulWidget {
  const ClosToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;

  /// Null renders the disabled state.
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  State<ClosToggle> createState() => _ClosToggleState();
}

class _ClosToggleState extends State<ClosToggle> {
  bool _focused = false;

  static const double _trackWidth = 36;
  static const double _trackHeight = 20;
  static const double _thumbSize = 14;
  static const double _thumbInset = 2;

  bool get _interactive => widget.onChanged != null;

  void _toggle() => widget.onChanged?.call(!widget.value);

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final on = widget.value;

    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 150);

    Widget track = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      width: _trackWidth,
      height: _trackHeight,
      decoration: BoxDecoration(
        color: colors.surface2,
        border: Border.all(
          color: on || _focused ? colors.dim1 : colors.border2,
        ),
        borderRadius: BorderRadius.circular(context.closRadius.full),
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: Curves.easeOut,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _thumbInset - 1),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOut,
            width: _thumbSize,
            height: _thumbSize,
            decoration: BoxDecoration(
              color: on ? colors.hi1 : colors.dim2,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );

    if (!_interactive) {
      track = Opacity(opacity: 0.45, child: track);
    }

    return Semantics(
      container: true,
      toggled: on,
      enabled: _interactive,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: _interactive,
        mouseCursor:
            _interactive ? SystemMouseCursors.click : MouseCursor.defer,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _toggle();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _interactive ? _toggle : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Center(child: track),
          ),
        ),
      ),
    );
  }
}
