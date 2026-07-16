import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/services/analytics_events.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/user_doc.dart';
import '../domain/methodology.dart';

/// Methodologies (context/prototype-screens/12-methodologies.png):
/// five advanced-framework reference cards, no drill-down. Part of
/// Closer: free accounts get the upgrade banner and the cards render
/// blurred, inert, and hidden from screen readers. Each card's only
/// link points at the scenario library.
///
/// Accent audit: zero accent-filled elements on this view, locked or
/// unlocked; the gate's Upgrade CTA is a ghost button.
class MethodologiesScreen extends ConsumerWidget {
  const MethodologiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.closColors;
    final sp = context.sp;
    // Effective tier, not raw entitlement: trialing users are unlocked.
    final locked = ref.watch(effectiveTierProvider) == Entitlement.free;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(sp.sp10, sp.sp8, sp.sp10, sp.sp10),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: context.closLayout.siteContainerMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Text(
                        locked
                            ? 'Five advanced closing frameworks, pulled '
                                'from across the scenario library. Part of '
                                'Closer: upgrade to study the mechanics, '
                                'then prove them in a live session.'
                            : 'Five advanced closing frameworks, pulled '
                                'from across the scenario library. Study '
                                'the mechanics, then prove them in a live '
                                'session.',
                        style: ClosType.style(
                          fontSize: 14,
                          weight: FontWeight.w400,
                          color: colors.body,
                        ).copyWith(height: 1.55),
                      ),
                    ),
                    SizedBox(height: sp.sp6),
                    if (locked) ...[
                      const _UpgradeGate(),
                      SizedBox(height: sp.sp6),
                    ],
                    for (final (i, methodology)
                        in methodologyCatalog.indexed) ...[
                      if (i > 0) SizedBox(height: sp.sp5),
                      locked
                          // Gated reference content: unreadable,
                          // inert, and excluded from semantics so the
                          // paywall holds for screen readers too.
                          ? ExcludeSemantics(
                              child: IgnorePointer(
                                child: ImageFiltered(
                                  imageFilter: ui.ImageFilter.blur(
                                    sigmaX: 5,
                                    sigmaY: 5,
                                  ),
                                  child: _MethodologyCard(
                                    methodology: methodology,
                                  ),
                                ),
                              ),
                            )
                          : _MethodologyCard(methodology: methodology),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return Container(
      constraints: const BoxConstraints(minHeight: 57),
      padding: EdgeInsets.symmetric(horizontal: sp.sp10, vertical: sp.sp4),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Text(
        'Methodologies',
        style: ClosType.style(
          fontSize: 15,
          weight: FontWeight.w700,
          color: colors.hi1,
          letterSpacingEm: -0.01,
        ),
      ),
    );
  }
}

/// The Closer gate: lock, pitch, and a ghost Upgrade CTA (this screen
/// carries no accent).
class _UpgradeGate extends StatelessWidget {
  const _UpgradeGate();

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return ClosCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 640;

          final lockBox = Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.surface2,
              border: Border.all(color: colors.border2),
              borderRadius: context.closRadius.buttonRadius,
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: colors.dim2, size: 16),
              child: const Center(child: LockIcon()),
            ),
          );

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Advanced frameworks are part of Closer',
                style: context.closType.headlineSmall,
              ),
              SizedBox(height: sp.sp1),
              Text(
                'Sandler, SPIN, Challenger, Straight Line and 7th Level, '
                'plus the full B2B scenario library. Upgrade to unlock.',
                style: context.closType.bodyMedium.copyWith(height: 1.5),
              ),
            ],
          );

          final cta = GhostButton(
            label: 'Upgrade',
            size: ClosButtonSize.medium,
            onPressed: () =>
                const UpgradeRoute(source: UpgradeSource.lockedCard)
                    .go(context),
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    lockBox,
                    SizedBox(width: sp.sp4),
                    Expanded(child: copy),
                  ],
                ),
                SizedBox(height: sp.sp4),
                cta,
              ],
            );
          }
          return Row(
            children: [
              lockBox,
              SizedBox(width: sp.sp4),
              Expanded(child: copy),
              SizedBox(width: sp.sp4),
              cta,
            ],
          );
        },
      ),
    );
  }
}

class _MethodologyCard extends StatelessWidget {
  const _MethodologyCard({required this.methodology});

  final Methodology methodology;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return ClosCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(sp.sp6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.surface2,
                    border: Border.all(color: colors.border2),
                    borderRadius: context.closRadius.buttonRadius,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(color: colors.dim2, size: 16),
                    child: const Center(child: MethodologiesIcon()),
                  ),
                ),
                SizedBox(width: sp.sp5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: sp.sp3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            methodology.name,
                            style: context.closType.headlineSmall,
                          ),
                          ClosBadge(label: methodology.era),
                        ],
                      ),
                      SizedBox(height: sp.headlineToSubtext),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Text(
                          methodology.summary,
                          style: context.closType.bodyMedium
                              .copyWith(height: 1.55),
                        ),
                      ),
                      SizedBox(height: sp.sp4),
                      Wrap(
                        spacing: sp.sp2,
                        runSpacing: sp.sp2,
                        children: [
                          for (final concept in methodology.concepts)
                            ClosBadge(label: concept),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: sp.sp6, vertical: sp.sp3),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                Expanded(child: _FooterStats(methodology: methodology)),
                _SeeScenariosLink(
                  onTap: () => const SimulationsRoute().go(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Scenario count plus the server-written framework average (score
/// text on the scoreText ramp), or 'Not started'.
class _FooterStats extends StatelessWidget {
  const _FooterStats({required this.methodology});

  final Methodology methodology;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final best = methodology.bestAverage;

    final style = ClosType.style(
      fontSize: 12,
      weight: FontWeight.w400,
      color: colors.dim1,
    );

    return Text.rich(
      TextSpan(
        text: '${methodology.scenarioCount} scenarios · ',
        style: style,
        children: [
          if (best == null)
            const TextSpan(text: 'Not started')
          else ...[
            const TextSpan(text: 'Best avg '),
            TextSpan(
              text: '$best%',
              style: ClosType.style(
                fontSize: 12,
                weight: FontWeight.w600,
                color: scoreTextColor(colors, best),
              ),
            ),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SeeScenariosLink extends StatefulWidget {
  const _SeeScenariosLink({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SeeScenariosLink> createState() => _SeeScenariosLinkState();
}

class _SeeScenariosLinkState extends State<_SeeScenariosLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;

    return Semantics(
      button: true,
      label: 'See scenarios using this',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: ExcludeSemantics(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.centerRight,
              child: Text(
                'See scenarios using this →',
                style: ClosType.style(
                  fontSize: 12,
                  weight: FontWeight.w600,
                  color: _hovered ? colors.hi2 : colors.mid,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
