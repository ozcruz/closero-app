import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_widgets.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.from});

  /// In-app location to land on once verified (deep links survive the
  /// verify step).
  final String? from;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  bool _busy = false;
  String? _error;
  String? _info;

  AuthService get _auth => ref.read(authServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The verification click happens in another tab; poll so this one
    // moves on without a manual refresh.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkVerified(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to this tab after clicking the email link.
    if (state == AppLifecycleState.resumed) _checkVerified();
  }

  Future<void> _checkVerified() async {
    final verified = await _auth.reloadAndCheckVerified();
    if (verified && mounted) {
      context.go(widget.from ?? DashboardRoute.path);
    }
  }

  Future<void> _resend() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await _auth.resendVerificationEmail();
      if (mounted) {
        setState(() => _info = 'Sent. Check your inbox and spam folder.');
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startOver() async {
    await _auth.signOut();
    if (mounted) const SignupRoute().go(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final type = context.closType;
    final email = ref.watch(currentUserEmailProvider) ?? 'your email';

    return AuthShell(
      below: AuthSwitchLine(
        prefix: 'Wrong email?',
        linkLabel: 'Sign out and start over',
        onTap: _startOver,
      ),
      card: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(alignment: Alignment.centerLeft, child: MailBadge()),
          SizedBox(height: sp.sp4),
          const AuthEyebrow(text: 'Verify your email'),
          SizedBox(height: sp.sp3),
          Text('Check your inbox.', style: type.headlineLarge),
          SizedBox(height: sp.sp3),
          Text.rich(
            TextSpan(
              text: 'We sent a confirmation link to ',
              style: type.bodyMedium,
              children: [
                TextSpan(
                  text: email,
                  style: ClosType.style(
                    fontSize: 14,
                    weight: FontWeight.w600,
                    color: colors.hi2,
                  ),
                ),
                const TextSpan(
                  text: '. Click it to confirm your email and start '
                      'practicing. This page moves on by itself once '
                      "you're verified.",
                ),
              ],
            ),
          ),
          SizedBox(height: sp.sp4),
          ResendRow(
            text: "Didn't get it?",
            linkLabel: _busy ? 'Sending' : 'Resend link',
            onTap: _busy ? null : _resend,
          ),
          if (_info != null) ...[
            SizedBox(height: sp.sp2),
            InlineNotice(kind: InlineNoticeKind.info, message: _info!),
          ],
          if (_error != null) ...[
            SizedBox(height: sp.sp2),
            InlineNotice(kind: InlineNoticeKind.error, message: _error!),
          ],
        ],
      ),
    );
  }
}
