import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Shared frame for the four auth screens, matching the site's auth
/// pages: brand mark over a centered 400px hairline card, both rising
/// in on load. Auth screens are no-sidebar screens, so the mark is the
/// ring icon (18px, accentDim), not the wordmark.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.card, this.below});

  final Widget card;

  /// Optional line under the card (e.g. "Free to start.").
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;

    return ClosScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: sp.sp6,
              vertical: sp.sp8,
            ),
            child: _RiseIn(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CloseroMark(),
                  SizedBox(height: sp.sp8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: ClosCard(
                      hairline: true,
                      padding: EdgeInsets.all(sp.sp8),
                      child: card,
                    ),
                  ),
                  if (below != null) ...[
                    SizedBox(height: sp.sp6),
                    below!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-shot entrance: fade in while rising 10px. Snaps under reduced
/// motion.
class _RiseIn extends StatelessWidget {
  const _RiseIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.fastOutSlowIn,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: child,
        ),
      ),
    );
  }
}

/// Dot-prefixed card eyebrow, e.g. "Log in".
class AuthEyebrow extends StatelessWidget {
  const AuthEyebrow({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: colors.mid,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: context.sp.sp2),
        Text(
          text,
          style: ClosType.style(
            fontSize: 11.5,
            weight: FontWeight.w600,
            color: colors.mid,
            letterSpacingEm: 0.02,
          ),
        ),
      ],
    );
  }
}

/// "OR" rule between the SSO stack and the form.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final line = Expanded(child: Container(height: 1, color: colors.border2));
    return Row(
      children: [
        line,
        SizedBox(width: context.sp.sp3),
        Text(
          'OR',
          style: ClosType.style(
            fontSize: 11,
            weight: FontWeight.w600,
            color: colors.dim2,
            letterSpacingEm: 0.04,
          ),
        ),
        SizedBox(width: context.sp.sp3),
        line,
      ],
    );
  }
}

/// Standalone small text link (forgot password, resend, change email).
/// body at rest, hi2 on hover; keeps a 44px tap target around the text.
class LinkText extends StatefulWidget {
  const LinkText({
    super.key,
    required this.label,
    required this.onTap,
    this.fontSize = 11.5,
    this.alignment = Alignment.center,
  });

  final String label;
  final VoidCallback? onTap;
  final double fontSize;

  /// Where the text sits inside its 44px tap target.
  final Alignment alignment;

  @override
  State<LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<LinkText> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final interactive = widget.onTap != null;

    return Semantics(
      link: true,
      enabled: interactive,
      child: MouseRegion(
        cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Align(
              alignment: widget.alignment,
              widthFactor: 1,
              child: Text(
                widget.label,
                style: ClosType.style(
                  fontSize: widget.fontSize,
                  weight: FontWeight.w600,
                  color: _hovered && interactive ? colors.hi2 : colors.body,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered switch line, e.g. "Don't have an account? Sign up free".
class AuthSwitchLine extends StatefulWidget {
  const AuthSwitchLine({
    super.key,
    required this.prefix,
    required this.linkLabel,
    required this.onTap,
  });

  final String prefix;
  final String linkLabel;
  final VoidCallback onTap;

  @override
  State<AuthSwitchLine> createState() => _AuthSwitchLineState();
}

class _AuthSwitchLineState extends State<AuthSwitchLine> {
  final TapGestureRecognizer _recognizer = TapGestureRecognizer();

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebind every build: the element gets reused across step changes
    // (request to sent), and a stale onTap would fire the old action.
    _recognizer.onTap = widget.onTap;
    final colors = context.closColors;
    return Text.rich(
      TextSpan(
        text: '${widget.prefix} ',
        style: ClosType.style(
          fontSize: 13,
          weight: FontWeight.w400,
          color: colors.body,
        ),
        children: [
          TextSpan(
            text: widget.linkLabel,
            recognizer: _recognizer,
            mouseCursor: SystemMouseCursors.click,
            style: ClosType.style(
              fontSize: 13,
              weight: FontWeight.w600,
              color: colors.hi2,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// The email the user typed, confirmed above the password step, with a
/// Change action to go back.
class ConfirmedEmailRow extends StatelessWidget {
  const ConfirmedEmailRow({
    super.key,
    required this.email,
    required this.onChange,
  });

  final String email;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: sp.sp3),
      decoration: BoxDecoration(
        color: colors.surface2,
        border: Border.all(color: colors.border2),
        borderRadius: context.closRadius.buttonRadius,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClosType.style(
                fontSize: 13.5,
                weight: FontWeight.w600,
                color: colors.hi2,
              ),
            ),
          ),
          SizedBox(width: sp.sp2),
          LinkText(label: 'Change', onTap: onChange),
        ],
      ),
    );
  }
}

/// Circled envelope for the "check your inbox" states.
class MailBadge extends StatelessWidget {
  const MailBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.surface2,
        border: Border.all(color: colors.border2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: IconTheme.merge(
        data: IconThemeData(color: colors.mid, size: 16),
        child: const MailIcon(),
      ),
    );
  }
}

/// "Didn't get it?" plus a resend link.
class ResendRow extends StatelessWidget {
  const ResendRow({
    super.key,
    required this.text,
    required this.linkLabel,
    required this.onTap,
  });

  final String text;
  final String linkLabel;

  /// Null disables the link (e.g. while a send is in flight).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: ClosType.style(
            fontSize: 12.5,
            weight: FontWeight.w400,
            color: context.closColors.body,
          ),
        ),
        SizedBox(width: context.sp.sp1),
        LinkText(label: linkLabel, fontSize: 12.5, onTap: onTap),
      ],
    );
  }
}
