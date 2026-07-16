import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// The app shell scaffold: base background behind screen content. Every
/// screen renders inside one of these. The grain overlay that used to
/// sit on top was removed 2026-07-16 (visual + latency cost); any
/// texture decision belongs to the UI overhaul, not individual screens.
class ClosScaffold extends StatelessWidget {
  const ClosScaffold({super.key, this.body});

  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    return Scaffold(
      backgroundColor: colors.base,
      body: body == null ? null : SizedBox.expand(child: body),
    );
  }
}
