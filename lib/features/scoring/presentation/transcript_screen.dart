import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/session_repository.dart';
import '../domain/session_doc.dart';
import 'score_screen.dart';
import 'scoring_shell.dart';

/// Full transcript (09-transcript.png): read-only utterance list in a
/// 720px centered column under a session meta strip. Annotated lines
/// carry green/warn/red text and edges only, never accent; the
/// annotation copy is the matching key moment's note, so the score
/// screen and transcript never drift apart. Deep links from Key
/// Moments (`?moment=n`, indexing the Strong-Watch-Missed order)
/// scroll to the linked utterance.
///
/// Accent audit: zero accent-filled elements on this view.
class TranscriptScreen extends ConsumerWidget {
  const TranscriptScreen({super.key, required this.sessionId, this.moment});

  final String sessionId;

  /// Index into [orderedKeyMoments], from the `moment` query param.
  final int? moment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(sessionViewProvider(sessionId));

    Widget message(String title, String body, Widget action) => Column(
          children: [
            SizedBox(height: context.sp.sp16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.closType.headlineSmall,
            ),
            SizedBox(height: context.sp.sp3),
            Text(
              body,
              textAlign: TextAlign.center,
              style: context.closType.bodyMedium,
            ),
            SizedBox(height: context.sp.sp6),
            action,
          ],
        );

    return view.when(
      loading: () => const ScoringShell(
        title: 'Full transcript',
        maxWidth: 720,
        child: SizedBox.shrink(),
      ),
      error: (error, stackTrace) => ScoringShell(
        title: 'Full transcript',
        maxWidth: 520,
        child: message(
          'The transcript could not load.',
          'Check your connection and try again.',
          GhostButton(
            label: 'Try again',
            size: ClosButtonSize.medium,
            onPressed: () => ref.invalidate(sessionViewProvider(sessionId)),
          ),
        ),
      ),
      data: (view) {
        if (view == null || view.doc.transcript.isEmpty) {
          return ScoringShell(
            title: 'Full transcript',
            maxWidth: 520,
            child: message(
              'There is no transcript for this session.',
              view == null
                  ? 'It may have been removed, or the link is out of date.'
                  : 'The call ended before any conversation was recorded.',
              GhostButton(
                label: 'Back to dashboard',
                size: ClosButtonSize.medium,
                onPressed: () => const DashboardRoute().go(context),
              ),
            ),
          );
        }
        return _TranscriptBody(view: view, moment: moment);
      },
    );
  }
}

class _TranscriptBody extends StatefulWidget {
  const _TranscriptBody({required this.view, required this.moment});

  final SessionView view;
  final int? moment;

  @override
  State<_TranscriptBody> createState() => _TranscriptBodyState();
}

class _TranscriptBodyState extends State<_TranscriptBody> {
  final _targetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Deep link: scroll the linked utterance into view once laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _targetKey.currentContext;
      if (target == null || !mounted) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.12,
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final doc = view.doc;
    final moments = orderedKeyMoments(doc);
    final momentIndex = widget.moment;
    final targetUtterance =
        momentIndex != null && momentIndex >= 0 && momentIndex < moments.length
            ? moments[momentIndex].utteranceIndex
            : null;

    // The note under an annotated bubble is its key moment's text.
    final notesByUtterance = {
      for (final moment in doc.keyMoments)
        moment.utteranceIndex: moment.text.replaceAll('\n', ' '),
    };

    return ScoringShell(
      title: 'Full transcript',
      meta: sessionMetaLine(view),
      trailing: GhostButton(
        label: 'Back to score',
        size: ClosButtonSize.medium,
        onPressed: () => ScoreRoute(sessionId: doc.id).go(context),
      ),
      metaBar: _SessionMetaBar(view: view),
      maxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, utterance) in doc.transcript.indexed) ...[
            if (i > 0) SizedBox(height: context.sp.sp6),
            KeyedSubtree(
              key: i == targetUtterance ? _targetKey : null,
              child: TranscriptLine(
                speaker: utterance.speaker == Speaker.rep
                    ? 'You'
                    : view.personaShortName,
                text: utterance.text,
                timestamp: formatClock(utterance.tsMs ~/ 1000),
                annotationKind: utterance.annotation == null
                    ? null
                    : momentHintKind(utterance.annotation!),
                annotation: notesByUtterance[i],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The meta strip under the topbar: persona, duration, framework, and
/// the overall score (score text ramp, never accent).
class _SessionMetaBar extends StatelessWidget {
  const _SessionMetaBar({required this.view});

  final SessionView view;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final total = view.doc.score?.total;

    final labelStyle = ClosType.style(
      fontSize: 12,
      weight: FontWeight.w400,
      color: colors.dim1,
    );
    final valueStyle = ClosType.style(
      fontSize: 12,
      weight: FontWeight.w600,
      color: colors.hi2,
    );

    Widget pair(String label, String value, {Color? valueColor}) => Text.rich(
          TextSpan(
            text: '$label ',
            style: labelStyle,
            children: [
              TextSpan(
                text: value,
                style: valueColor == null
                    ? valueStyle
                    : valueStyle.copyWith(color: valueColor),
              ),
            ],
          ),
        );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: sp.sp6, vertical: sp.sp3),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: sp.sp8,
        runSpacing: sp.sp2,
        children: [
          Text.rich(
            TextSpan(
              text: view.personaName,
              style: valueStyle,
              children: [
                TextSpan(text: ' · ${view.personaRole}', style: labelStyle),
              ],
            ),
          ),
          pair('Duration', formatClock(view.doc.durationSec)),
          if (view.methodologyLabel != null)
            pair('Method', view.methodologyLabel!),
          if (total != null)
            pair(
              'Overall score',
              '$total',
              valueColor: scoreTextColor(colors, total),
            ),
        ],
      ),
    );
  }
}
