import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/widgets/auth_widgets.dart';
import '../data/onboarding_store.dart';
import '../domain/onboarding_answers.dart';
import '../domain/recommended_scenario.dart';

/// How long a tapped answer stays highlighted before the flow
/// auto-advances. One tunable const: adjust here after the real-device
/// timing pass, nowhere else.
const Duration kOnboardingSelectionHold = Duration(milliseconds: 350);

enum OnboardingStep { welcome, name, track, experience, focus, reveal }

/// Six steps, one question per screen (01-onboarding.png). The wordmark
/// lives only here: 400px hero on the welcome step, 60px in the topbar
/// after. Question steps auto-advance after a short selection hold; the
/// reveal ends in a single CTA to the Dashboard and never auto-starts
/// a sim.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    super.key,
    this.initialStep = OnboardingStep.welcome,
  });

  /// Test hook so goldens can capture any step directly. Production
  /// always starts at [OnboardingStep.welcome].
  final OnboardingStep initialStep;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late OnboardingStep _step = widget.initialStep;

  final TextEditingController _nameController = TextEditingController();
  bool _savingName = false;
  String? _nameError;

  SellTrack? _track;
  ExperienceLevel? _experience;
  FocusArea? _focus;
  Timer? _holdTimer;

  RecommendedScenario? _recommended;

  @override
  void dispose() {
    _holdTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _goTo(OnboardingStep step) {
    _holdTimer?.cancel();
    setState(() => _step = step);
  }

  /// Records the answer, holds the highlight, then advances.
  void _select<T>(T value, void Function(T) assign, OnboardingStep next) {
    _holdTimer?.cancel();
    setState(() => assign(value));
    _holdTimer = Timer(kOnboardingSelectionHold, () {
      if (!mounted) return;
      if (next == OnboardingStep.reveal) {
        _finish();
      } else {
        _goTo(next);
      }
    });
  }

  Future<void> _submitName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Enter a name to continue.');
      return;
    }
    setState(() {
      _savingName = true;
      _nameError = null;
    });
    try {
      await ref.read(authServiceProvider).updateDisplayName(name);
      if (mounted) _goTo(OnboardingStep.track);
    } on Object catch (e) {
      if (mounted) setState(() => _nameError = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  /// Computes and persists the recommendation, then shows the reveal.
  /// The saved scenario id is what the Dashboard hero pre-loads at
  /// session zero.
  void _finish() {
    final track = _track;
    final experience = _experience;
    final focus = _focus;
    if (track == null || experience == null || focus == null) return;
    final answers = OnboardingAnswers(
      track: track,
      experience: experience,
      focus: focus,
    );
    final recommended = recommendScenario(answers);
    // Best effort: a failed prefs write must not strand the user here.
    unawaited(
      ref.read(onboardingStoreProvider).saveResult(
            answers: answers,
            recommendedScenarioId: recommended.id,
          ),
    );
    setState(() {
      _recommended = recommended;
      _step = OnboardingStep.reveal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;

    return ClosScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(showWordmark: _step != OnboardingStep.welcome),
            _ProgressStripe(
              progress:
                  _step.index / (OnboardingStep.values.length - 1),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: sp.sp6,
                    vertical: sp.sp8,
                  ),
                  child: _StepSwitcher(child: _buildStep()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      OnboardingStep.welcome => _WelcomeStep(
          key: const ValueKey(OnboardingStep.welcome),
          onStart: () => _goTo(OnboardingStep.name),
        ),
      OnboardingStep.name => _StepFrame(
          key: const ValueKey(OnboardingStep.name),
          headline: 'What should we call you?',
          subtext: 'First name is fine.',
          onBack: () => _goTo(OnboardingStep.welcome),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClosTextField(
                label: 'Your name',
                controller: _nameController,
                hintText: 'e.g. Sandra',
                autofocus: true,
                autofillHints: const [AutofillHints.givenName],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitName(),
              ),
              if (_nameError != null) ...[
                SizedBox(height: context.sp.sp2),
                InlineNotice(
                  kind: InlineNoticeKind.error,
                  message: _nameError!,
                ),
              ],
              SizedBox(height: context.sp.sp4),
              PrimaryButton(
                label: 'Continue',
                loading: _savingName,
                expand: true,
                onPressed: _submitName,
              ),
            ],
          ),
        ),
      OnboardingStep.track => _StepFrame(
          key: const ValueKey(OnboardingStep.track),
          headline: 'Who do you sell to?',
          onBack: () => _goTo(OnboardingStep.name),
          child: _OptionList(
            options: [
              _Option(
                label: 'I sell to businesses',
                selected: _track == SellTrack.business,
                onTap: () => _select(
                  SellTrack.business,
                  (v) => _track = v,
                  OnboardingStep.experience,
                ),
              ),
              _Option(
                label: 'I sell to people, directly',
                selected: _track == SellTrack.consumer,
                onTap: () => _select(
                  SellTrack.consumer,
                  (v) => _track = v,
                  OnboardingStep.experience,
                ),
              ),
            ],
          ),
        ),
      OnboardingStep.experience => _StepFrame(
          key: const ValueKey(OnboardingStep.experience),
          headline: 'How long have you been in sales?',
          onBack: () => _goTo(OnboardingStep.track),
          child: _OptionList(
            options: [
              for (final (level, label) in [
                (ExperienceLevel.gettingStarted, 'Just getting started'),
                (ExperienceLevel.underTwoYears, 'Under 2 years'),
                (ExperienceLevel.twoToFiveYears, '2 to 5 years'),
                (ExperienceLevel.fivePlusYears, '5 years or more'),
              ])
                _Option(
                  label: label,
                  selected: _experience == level,
                  onTap: () => _select(
                    level,
                    (v) => _experience = v,
                    OnboardingStep.focus,
                  ),
                ),
            ],
          ),
        ),
      OnboardingStep.focus => _StepFrame(
          key: const ValueKey(OnboardingStep.focus),
          headline: 'Where do you want to improve most?',
          onBack: () => _goTo(OnboardingStep.experience),
          child: _OptionList(
            options: [
              for (final (area, label) in [
                (FocusArea.objections, 'Handling objections'),
                (FocusArea.discovery, 'Asking better questions'),
                (FocusArea.rapport, 'Building rapport'),
                (FocusArea.closing, 'Closing the deal'),
                (FocusArea.tonality, 'Tonality and pacing'),
              ])
                _Option(
                  label: label,
                  selected: _focus == area,
                  onTap: () => _select(
                    area,
                    (v) => _focus = v,
                    OnboardingStep.reveal,
                  ),
                ),
            ],
          ),
        ),
      OnboardingStep.reveal => _RevealStep(
          key: const ValueKey(OnboardingStep.reveal),
          scenario: _recommended ?? gatekeeperScenario,
          name: _nameController.text.trim(),
          onContinue: () => const DashboardRoute().go(context),
        ),
    };
  }
}

/// Onboarding topbar: hairline bottom border, 60px wordmark once past
/// the welcome step (where the wordmark is the hero instead).
class _TopBar extends StatelessWidget {
  const _TopBar({required this.showWordmark});

  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    return Container(
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: showWordmark ? const CloseroWordmark(width: 60) : null,
    );
  }
}

/// 2px step progress under the topbar. Neutral ramp, never accent.
class _ProgressStripe extends StatelessWidget {
  const _ProgressStripe({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 300);
    return SizedBox(
      height: 2,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: duration,
          curve: Curves.fastOutSlowIn,
          widthFactor: progress.clamp(0, 1),
          heightFactor: 1,
          child: ColoredBox(color: colors.hi2),
        ),
      ),
    );
  }
}

/// Cross-fades steps with a slight rise. Snaps under reduced motion.
class _StepSwitcher extends StatelessWidget {
  const _StepSwitcher({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 240);
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.fastOutSlowIn,
      switchOutCurve: Curves.fastOutSlowIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// The welcome hero: 400px wordmark over a faint decorative glow, the
/// three-questions promise, one CTA.
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final type = context.closType;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            // Elliptical so the glow fades out before every box edge.
            gradient: RadialGradient(
              transform: const _EllipticalGlow(2.2),
              colors: [
                colors.hi1.withValues(alpha: 0.05),
                colors.hi1.withValues(alpha: 0),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: sp.sp16,
              vertical: sp.sp12,
            ),
            // Hero size is locked at 400px; narrow viewports scale down.
            child: LayoutBuilder(
              builder: (context, constraints) => CloseroWordmark(
                width: math.min(400, constraints.maxWidth),
              ),
            ),
          ),
        ),
        SizedBox(height: sp.sp8),
        Text(
          "Three quick questions.\nThen you're in.",
          textAlign: TextAlign.center,
          style: type.displaySmall,
        ),
        SizedBox(height: sp.headlineToSubtext),
        Text(
          'No fluff, just enough for us to get your first session right.',
          textAlign: TextAlign.center,
          style: ClosType.style(
            fontSize: 14,
            weight: FontWeight.w400,
            color: colors.body,
          ),
        ),
        SizedBox(height: sp.sp8),
        PrimaryButton(label: "Let's go", onPressed: onStart),
      ],
    );
  }
}

/// Stretches a radial gradient horizontally about the box center, so a
/// circular fade becomes the wide soft glow behind the hero wordmark.
class _EllipticalGlow extends GradientTransform {
  const _EllipticalGlow(this.scaleX);

  final double scaleX;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.identity()
        ..translateByDouble(bounds.center.dx, bounds.center.dy, 0, 1)
        ..scaleByDouble(scaleX, 1, 1, 1)
        ..translateByDouble(-bounds.center.dx, -bounds.center.dy, 0, 1);
}

/// Shared frame for the question steps: back link, centered headline,
/// optional subtext, and the step's content in a 400px column.
class _StepFrame extends StatelessWidget {
  const _StepFrame({
    super.key,
    required this.headline,
    this.subtext,
    this.onBack,
    required this.child,
  });

  final String headline;
  final String? subtext;
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            headline,
            textAlign: TextAlign.center,
            style: context.closType.headlineLarge,
          ),
          if (subtext != null) ...[
            SizedBox(height: sp.headlineToSubtext),
            Text(
              subtext!,
              textAlign: TextAlign.center,
              style: ClosType.style(
                fontSize: 14,
                weight: FontWeight.w400,
                color: colors.body,
              ),
            ),
          ],
          SizedBox(height: sp.sp8),
          child,
          if (onBack != null) ...[
            SizedBox(height: sp.sp6),
            LinkText(label: 'Back', onTap: onBack),
          ],
        ],
      ),
    );
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({required this.options});

  final List<_Option> options;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, option) in options.indexed) ...[
          if (i > 0) SizedBox(height: sp.sp2),
          option,
        ],
      ],
    );
  }
}

/// One answer row. Selected state is an accentDim border (the permitted
/// selection-state use) with hi1 text; never a tinted fill.
class _Option extends StatefulWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Option> createState() => _OptionState();
}

class _OptionState extends State<_Option> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    final borderColor = widget.selected
        ? colors.accentDim
        : _hovered
            ? colors.dim1
            : colors.border2;
    final textColor = widget.selected
        ? colors.hi1
        : _hovered
            ? colors.hi2
            : colors.mid;

    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 150);

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: ExcludeSemantics(
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.fastOutSlowIn,
              constraints: const BoxConstraints(minHeight: 48),
              padding: EdgeInsets.symmetric(horizontal: sp.sp4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: borderColor),
                borderRadius: context.closRadius.buttonRadius,
              ),
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: ClosType.style(
                  fontSize: 14,
                  weight: FontWeight.w600,
                  color: textColor,
                  letterSpacingEm: -0.01,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The reveal: the pre-loaded first scenario and a single CTA to the
/// Dashboard. Never auto-starts a sim; the card is display-only.
class _RevealStep extends StatelessWidget {
  const _RevealStep({
    super.key,
    required this.scenario,
    required this.name,
    required this.onContinue,
  });

  final RecommendedScenario scenario;
  final String name;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    final headline =
        name.isEmpty ? "You're set." : "You're set, $name.";

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            headline,
            textAlign: TextAlign.center,
            style: context.closType.headlineLarge,
          ),
          SizedBox(height: sp.headlineToSubtext),
          Text(
            'We picked your first scenario from your answers. '
            'Start it whenever you like.',
            textAlign: TextAlign.center,
            style: ClosType.style(
              fontSize: 14,
              weight: FontWeight.w400,
              color: colors.body,
            ),
          ),
          SizedBox(height: sp.sectionGap),
          Center(
            child: SizedBox(
              width: 280,
              child: ScenarioCard(
                name: scenario.personaName,
                description: scenario.description,
                duration: scenario.duration,
                difficulty: scenario.difficulty,
                initials: scenario.initials,
                tint: scenario.tint,
              ),
            ),
          ),
          SizedBox(height: sp.sectionGap),
          PrimaryButton(
            label: 'Continue to dashboard',
            expand: true,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
