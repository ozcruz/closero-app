import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_widgets.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  String? _error;
  String? _info;

  AuthService get _auth => ref.read(authServiceProvider);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Sends the link. AuthService already treats unknown emails as
  /// success, so this can't be used to probe for accounts.
  Future<void> _send({required bool resend}) async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await _auth.sendPasswordReset(email);
      if (mounted) {
        setState(() {
          _sent = true;
          if (resend) _info = 'Sent. Check your inbox and spam folder.';
        });
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _tryAgain() {
    setState(() {
      _sent = false;
      _error = null;
      _info = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(card: _sent ? _buildSent() : _buildRequest());
  }

  Widget _buildRequest() {
    final sp = context.sp;
    final type = context.closType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthEyebrow(text: 'Reset password'),
        SizedBox(height: sp.sp3),
        Text('Forgot your password?', style: type.headlineLarge),
        SizedBox(height: sp.sp3),
        Text(
          "Enter the email on your account and we'll send you a link "
          'to set a new one.',
          style: type.bodyMedium,
        ),
        SizedBox(height: sp.sp6),
        ClosTextField(
          label: 'Email',
          hintText: 'you@company.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _send(resend: false),
        ),
        SizedBox(height: sp.sp6),
        PrimaryButton(
          label: 'Send reset link',
          expand: true,
          loading: _busy,
          onPressed: _busy ? null : () => _send(resend: false),
        ),
        if (_error != null) ...[
          SizedBox(height: sp.sp4),
          InlineNotice(kind: InlineNoticeKind.error, message: _error!),
        ],
        SizedBox(height: sp.sp6),
        AuthSwitchLine(
          prefix: 'Remembered it?',
          linkLabel: 'Log in',
          onTap: () => const LoginRoute().go(context),
        ),
      ],
    );
  }

  Widget _buildSent() {
    final colors = context.closColors;
    final sp = context.sp;
    final type = context.closType;
    final email = _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(alignment: Alignment.centerLeft, child: MailBadge()),
        SizedBox(height: sp.sp4),
        const AuthEyebrow(text: 'Check your inbox'),
        SizedBox(height: sp.sp3),
        Text('Link sent.', style: type.headlineLarge),
        SizedBox(height: sp.sp3),
        Text.rich(
          TextSpan(
            text: 'If an account exists for ',
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
                text: ", we've sent a link to reset your password.",
              ),
            ],
          ),
        ),
        SizedBox(height: sp.sp4),
        Row(
          children: [
            Expanded(
              child: Text(
                "Didn't get it? Check spam, or",
                style: ClosType.style(
                  fontSize: 12.5,
                  weight: FontWeight.w400,
                  color: colors.body,
                ),
              ),
            ),
            LinkText(
              label: _busy ? 'Sending' : 'Resend link',
              fontSize: 12.5,
              onTap: _busy ? null : () => _send(resend: true),
            ),
          ],
        ),
        if (_info != null) ...[
          SizedBox(height: sp.sp2),
          InlineNotice(kind: InlineNoticeKind.info, message: _info!),
        ],
        if (_error != null) ...[
          SizedBox(height: sp.sp2),
          InlineNotice(kind: InlineNoticeKind.error, message: _error!),
        ],
        SizedBox(height: sp.sp4),
        AuthSwitchLine(
          prefix: 'Wrong email?',
          linkLabel: 'Try again',
          onTap: _tryAgain,
        ),
      ],
    );
  }
}
