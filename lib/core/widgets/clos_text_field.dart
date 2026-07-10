import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Single-line text input: surface2 field, border2 border brightening to
/// hi2 on focus, button radius, 44px tall. Label sits above in the small
/// field-label style with an optional trailing widget (e.g. a forgot
/// password link).
class ClosTextField extends StatefulWidget {
  const ClosTextField({
    super.key,
    required this.label,
    this.labelTrailing,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;

  /// Right-aligned widget on the label row.
  final Widget? labelTrailing;
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<ClosTextField> createState() => _ClosTextFieldState();
}

class _ClosTextFieldState extends State<ClosTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 200);

    Widget label = Text(
      widget.label,
      style: ClosType.style(
        fontSize: 11,
        weight: FontWeight.w600,
        color: colors.dim1,
        letterSpacingEm: 0.04,
      ),
    );
    if (widget.labelTrailing != null) {
      // Bottom-aligned so a trailing link's 44px tap target grows
      // upward without pushing the label off the field.
      label = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: label),
          widget.labelTrailing!,
        ],
      );
    }

    final field = AnimatedContainer(
      duration: duration,
      curve: Curves.fastOutSlowIn,
      height: 44,
      decoration: BoxDecoration(
        color: colors.surface2,
        border: Border.all(color: _focused ? colors.hi2 : colors.border2),
        borderRadius: context.closRadius.buttonRadius,
      ),
      padding: EdgeInsets.symmetric(horizontal: sp.sp3),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        cursorColor: colors.hi1,
        style: ClosType.style(
          fontSize: 13.5,
          weight: FontWeight.w400,
          color: colors.hi1,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: ClosType.style(
            fontSize: 13.5,
            weight: FontWeight.w400,
            color: colors.dim2,
          ),
        ),
      ),
    );

    return Semantics(
      textField: true,
      label: widget.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          SizedBox(height: sp.sp1),
          Opacity(opacity: widget.enabled ? 1 : 0.45, child: field),
        ],
      ),
    );
  }
}
