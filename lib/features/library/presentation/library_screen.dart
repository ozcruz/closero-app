import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/user_doc.dart';
import '../data/scenario_repository.dart';
import '../domain/scenario.dart';
import 'scenario_preview_modal.dart';

/// The Simulations library (context/prototype-screens/04-simulations.png):
/// B2C/B2B track switch, then the character-select grid in two curated
/// sections. Free tier = B2C; B2B cards render locked and route to the
/// upgrade screen. Unlocked cards open the shared Scenario Preview
/// modal. Completion is a personal-best score or 'Start', never a
/// checkmark.
///
/// Accent audit: zero accent-filled elements on this view; the accent
/// CTA lives inside the modal.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, this.initialTrack = ScenarioTrack.b2c});

  final ScenarioTrack initialTrack;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late ScenarioTrack _track = widget.initialTrack;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(scenarioCatalogProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TopBar(),
        Expanded(
          child: catalog.when(
            // The fixture load resolves within a frame; no skeleton flash.
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'The library could not load.',
                    style: context.closType.headlineSmall,
                  ),
                  SizedBox(height: context.sp.sp3),
                  Text(
                    'Check your connection and try again.',
                    style: context.closType.bodyMedium,
                  ),
                  SizedBox(height: context.sp.sp6),
                  GhostButton(
                    label: 'Try again',
                    size: ClosButtonSize.medium,
                    onPressed: () => ref.invalidate(scenarioCatalogProvider),
                  ),
                ],
              ),
            ),
            data: (scenarios) => _LibraryBody(
              scenarios: scenarios,
              track: _track,
              onTrackChanged: (track) => setState(() => _track = track),
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
        'Simulations',
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

class _LibraryBody extends ConsumerWidget {
  const _LibraryBody({
    required this.scenarios,
    required this.track,
    required this.onTrackChanged,
  });

  final List<Scenario> scenarios;
  final ScenarioTrack track;
  final ValueChanged<ScenarioTrack> onTrackChanged;

  /// Free tier = B2C library; every B2B card renders locked.
  bool _locked(Entitlement entitlement) =>
      track == ScenarioTrack.b2b && entitlement == Entitlement.free;

  String get _caption => switch (track) {
        ScenarioTrack.b2c =>
          'Door-to-door, retail, phone, and high-ticket consumer closing',
        ScenarioTrack.b2b =>
          'Gatekeepers, discovery, demos, and multi-stakeholder deals',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.closColors;
    final sp = context.sp;
    final locked = _locked(ref.watch(entitlementProvider));

    final visible = scenarios.where((s) => s.track == track);
    final pickUp =
        visible.where((s) => s.bucket == ScenarioBucket.pickUp).toList();
    final fresh =
        visible.where((s) => s.bucket == ScenarioBucket.fresh).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(sp.sp10, sp.sp8, sp.sp10, sp.sp10),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.closLayout.siteContainerMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ClosSegmented(
                  segments: const ['B2C', 'B2B'],
                  selectedIndex: track.index,
                  onChanged: (i) => onTrackChanged(ScenarioTrack.values[i]),
                ),
              ),
              SizedBox(height: sp.sp3),
              Center(
                child: Text(
                  _caption,
                  textAlign: TextAlign.center,
                  style: ClosType.style(
                    fontSize: 13,
                    weight: FontWeight.w400,
                    color: colors.dim1,
                  ),
                ),
              ),
              SizedBox(height: sp.sp8),
              if (pickUp.isNotEmpty) ...[
                const SectionHeader(
                  title: 'Pick up where you left off',
                  variant: SectionHeaderVariant.label,
                ),
                SizedBox(height: sp.sp4),
                _ScenarioGrid(scenarios: pickUp, locked: locked),
                SizedBox(height: sp.sectionGap),
              ],
              if (fresh.isNotEmpty) ...[
                const SectionHeader(
                  title: 'New scenarios',
                  variant: SectionHeaderVariant.label,
                ),
                SizedBox(height: sp.sp4),
                _ScenarioGrid(scenarios: fresh, locked: locked),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive character-select grid. Locked cards route to the upgrade
/// screen; unlocked cards open the shared Scenario Preview modal.
class _ScenarioGrid extends StatelessWidget {
  const _ScenarioGrid({required this.scenarios, required this.locked});

  final List<Scenario> scenarios;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1020
            ? 4
            : width >= 760
                ? 3
                : width >= 520
                    ? 2
                    : 1;

        final rows = <Widget>[];
        for (var start = 0; start < scenarios.length; start += columns) {
          if (start > 0) rows.add(SizedBox(height: sp.sp5));
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = start; i < start + columns; i++) ...[
                  if (i > start) SizedBox(width: sp.sp5),
                  Expanded(
                    child: i < scenarios.length
                        ? _card(context, scenarios[i])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }

  Widget _card(BuildContext context, Scenario scenario) {
    return ScenarioCard(
      name: scenario.name,
      description: scenario.cardLine,
      duration: scenario.duration,
      difficulty: scenario.difficultyBadge,
      initials: scenario.initials,
      tint: scenario.tint,
      status: scenario.status(locked: locked),
      bestScore: scenario.bestScore,
      onTap: () {
        if (locked) {
          const UpgradeRoute().go(context);
        } else {
          showScenarioPreviewModal(context, scenario: scenario);
        }
      },
    );
  }
}
