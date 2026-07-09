import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'grain_overlay.dart';

/// The app shell scaffold: base background plus the grain overlay on top of
/// screen content. Every screen renders inside one of these; screens never
/// apply their own grain.
class ClosScaffold extends StatelessWidget {
  const ClosScaffold({super.key, this.body});

  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    return Scaffold(
      backgroundColor: colors.base,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ?body,
          Positioned.fill(child: GrainOverlay(color: colors.hi1)),
        ],
      ),
    );
  }
}
