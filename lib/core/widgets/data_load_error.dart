import 'package:flutter/material.dart';

import 'clos_buttons.dart';
import 'clos_icons.dart';
import 'empty_state.dart';

/// A load-failure state for a data screen backed by a Firestore/auth
/// stream: a calm line and a Try again action that re-runs the query, so
/// a dropped stream lands here instead of an endless blank skeleton.
///
/// Reuses [EmptyState] (icon in a neutral surface2 box, headline, body,
/// action) so every data screen fails the same, calm way.
class DataLoadError extends StatelessWidget {
  const DataLoadError({
    super.key,
    required this.title,
    required this.onRetry,
  });

  /// Screen-specific headline, e.g. 'The dashboard could not load.'.
  final String title;

  /// Re-runs the query (typically `ref.invalidate(theProvider)`).
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: const AlertIcon(),
        title: title,
        body: 'Check your connection and try again.',
        action: GhostButton(
          label: 'Try again',
          size: ClosButtonSize.medium,
          onPressed: onRetry,
        ),
      ),
    );
  }
}
