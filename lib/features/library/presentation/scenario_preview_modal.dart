import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/scenario.dart';

/// Opens the shared Scenario Preview modal
/// (context/prototype-screens/22-scenario-preview.png). Launched from
/// the Library grid and the Dashboard hero, always with a [Scenario]
/// from the one shared catalog.
Future<void> showScenarioPreviewModal(
  BuildContext context, {
  required Scenario scenario,
}) {
  return showClosModal<void>(
    context,
    builder: (context) => ScenarioPreviewModal(scenario: scenario),
  );
}

/// The modal body: persona art header with the difficulty badge, name
/// and role, synopsis, methodology tags (they live ONLY here, never on
/// cards), meta panel, personal best, and the session CTA.
///
/// Accent audit: the Start/Resume session CTA is the modal's one
/// accent-filled element.
class ScenarioPreviewModal extends StatelessWidget {
  const ScenarioPreviewModal({super.key, required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return ClosModal(
      onClose: () => Navigator.of(context).pop(),
      header: _Header(scenario: scenario),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            scenario.synopsis,
            style: context.closType.bodyMedium.copyWith(height: 1.55),
          ),
          SizedBox(height: sp.sp4),
          Wrap(
            spacing: sp.sp2,
            runSpacing: sp.sp2,
            children: [
              for (final tag in scenario.methodologyTags)
                ClosBadge(label: tag),
            ],
          ),
          SizedBox(height: sp.sp4),
          ClosCard(
            variant: ClosCardVariant.inset,
            padding: EdgeInsets.all(sp.sp4),
            child: Wrap(
              spacing: sp.sp6,
              runSpacing: sp.sp2,
              children: [
                _MetaItem(label: 'Est.', value: scenario.duration),
                _MetaItem(label: 'Targets', value: scenario.targets),
                _MetaItem(
                  label: 'Difficulty',
                  value: scenario.difficultyLabel,
                ),
              ],
            ),
          ),
          if (scenario.bestScore != null) ...[
            SizedBox(height: sp.sp3),
            ClosCard(
              variant: ClosCardVariant.inset,
              padding: EdgeInsets.symmetric(
                horizontal: sp.sp4,
                vertical: sp.sp3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your personal best',
                      style: ClosType.style(
                        fontSize: 13,
                        weight: FontWeight.w400,
                        color: colors.body,
                      ),
                    ),
                  ),
                  Text(
                    '${scenario.bestScore}',
                    style: ClosType.style(
                      fontSize: 20,
                      weight: FontWeight.w700,
                      color: scoreTextColor(colors, scenario.bestScore!),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: sp.sp6),
          Row(
            children: [
              GhostButton(
                label: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(width: sp.sp3),
              Expanded(
                child: PrimaryButton(
                  label: scenario.inProgress
                      ? 'Resume session'
                      : 'Start session',
                  expand: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                    ColdCallSimRoute(scenarioId: scenario.id).go(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-bleed persona art with the difficulty badge top-left and the
/// name and role over the foot of the gradient.
class _Header extends StatelessWidget {
  const _Header({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AvatarStack(
            initials: scenario.initials,
            tint: scenario.tint,
            semanticLabel: '${scenario.name}, AI persona',
          ),
          Positioned(
            top: sp.sp3,
            left: sp.sp3,
            child: ClosBadge(label: scenario.difficultyBadge),
          ),
          Positioned(
            left: sp.sp6,
            right: sp.sp6,
            bottom: sp.sp4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  scenario.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.closType.headlineLarge,
                ),
                SizedBox(height: sp.sp1),
                Text(
                  scenario.roleLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClosType.style(
                    fontSize: 13,
                    weight: FontWeight.w400,
                    color: colors.mid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One 'label value' pair in the meta panel, matching the dashboard
/// hero's meta strip.
class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    return Text.rich(
      TextSpan(
        text: '$label ',
        style: ClosType.style(
          fontSize: 12,
          weight: FontWeight.w400,
          color: colors.dim1,
        ),
        children: [
          TextSpan(
            text: value,
            style: ClosType.style(
              fontSize: 12,
              weight: FontWeight.w500,
              color: colors.mid,
            ),
          ),
        ],
      ),
    );
  }
}
