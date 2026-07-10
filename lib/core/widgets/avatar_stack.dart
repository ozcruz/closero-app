import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../theme/theme.dart';

/// Decorative tint for the placeholder art gradient, mapped to the
/// artX tokens. Per persona and purely decorative, never semantic.
enum AvatarArtTint { neutral, violet, umber, moss, slate }

/// Persona avatar host: a permanent gradient placeholder with an
/// optional Rive layer mounted on top.
///
/// The placeholder is the loading state AND the fallback; it is never
/// removed from the tree, even while the Rive layer renders. This
/// widget is only the mounting slot: loading the .riv file, resolving
/// the LipSync state machine, holding input handles, and all
/// lipsync/idle driving live in the session driver (see
/// context/rive-contract.md). Pass the externally created
/// [controller]; pass null (or clear it on failure) to fall back to
/// the placeholder. Never crash on a missing rig.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    this.initials,
    this.tint = AvatarArtTint.neutral,
    this.controller,
    this.fit = Fit.cover,
    this.semanticLabel,
  });

  /// Placeholder initials, e.g. 'SV'. Rendered large and faint.
  final String? initials;

  /// Art gradient cast for this persona.
  final AvatarArtTint tint;

  /// Externally created controller with its artboard and state
  /// machine already resolved. Null shows the placeholder alone.
  final RiveWidgetController? controller;

  final Fit fit;

  /// e.g. 'Sandra Voss, AI persona'.
  final String? semanticLabel;

  Color _tintColor(ClosColors colors) => switch (tint) {
        AvatarArtTint.neutral => colors.surface2,
        AvatarArtTint.violet => colors.artViolet,
        AvatarArtTint.umber => colors.artUmber,
        AvatarArtTint.moss => colors.artMoss,
        AvatarArtTint.slate => colors.artSlate,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;

    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Permanent placeholder layer. Never removed.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_tintColor(colors), colors.base],
                ),
              ),
            ),
            if (initials != null)
              // Scales with the box: the glyphs fill ~a third of the
              // shorter side, like the prototype card art.
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.55,
                  heightFactor: 0.38,
                  child: FittedBox(
                    child: Text(
                      initials!,
                      style: ClosType.style(
                        fontSize: 48,
                        weight: FontWeight.w700,
                        color: colors.dim3,
                        letterSpacingEm: -0.02,
                      ),
                    ),
                  ),
                ),
              ),
            if (controller != null)
              RiveWidget(controller: controller!, fit: fit),
          ],
        ),
      ),
    );
  }
}
