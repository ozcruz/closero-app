import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/feature_flags.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_providers.dart';
import 'login_screen.dart' show AuthBusy;
import 'widgets/auth_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key, this.from});

  /// In-app location to land on once signed up and verified.
  final String? from;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordStep = false;
  String? _error;
  AuthBusy _busy = AuthBusy.none;

  AuthService get _auth => ref.read(authServiceProvider);

  bool get _idle => _busy == AuthBusy.none;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _continueToPassword() {
    if (_emailController.text.trim().isEmpty) return;
    setState(() {
      _passwordStep = true;
      _error = null;
    });
  }

  void _changeEmail() {
    setState(() {
      _passwordStep = false;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_idle) return;
    final password = _passwordController.text;
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    setState(() {
      _busy = AuthBusy.submit;
      _error = null;
    });
    try {
      await _auth.signUpWithEmail(
        email: _emailController.text.trim(),
        password: password,
      );
      if (mounted) VerifyEmailRoute(from: widget.from).go(context);
    } on Object catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = AuthBusy.none);
    }
  }

  Future<void> _sso(Future<void> Function() signIn, AuthBusy kind) async {
    if (!_idle) return;
    setState(() {
      _busy = kind;
      _error = null;
    });
    try {
      await signIn();
      // SSO emails arrive verified; go straight in.
      if (mounted) context.go(widget.from ?? DashboardRoute.path);
    } on Object catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = AuthBusy.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final type = context.closType;

    return AuthShell(
      below: Text(
        'Free to start. No credit card required.',
        style: ClosType.style(
          fontSize: 12.5,
          weight: FontWeight.w400,
          color: context.closColors.body,
        ),
      ),
      card: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthEyebrow(text: 'Sign up'),
          SizedBox(height: sp.sp3),
          Text('Create your free account.', style: type.headlineLarge),
          SizedBox(height: sp.sp3),
          Text(
            'Practice the call before it costs you the deal. '
            'Takes under a minute.',
            style: type.bodyMedium,
          ),
          SizedBox(height: sp.sp6),
          SsoButton(
            label: 'Continue with Google',
            expand: true,
            loading: _busy == AuthBusy.google,
            onPressed:
                _idle ? () => _sso(_auth.signInWithGoogle, AuthBusy.google) : null,
          ),
          if (kAppleSsoEnabled) ...[
            SizedBox(height: sp.sp2),
            SsoButton(
              label: 'Continue with Apple',
              expand: true,
              loading: _busy == AuthBusy.apple,
              onPressed:
                  _idle ? () => _sso(_auth.signInWithApple, AuthBusy.apple) : null,
            ),
          ],
          SizedBox(height: sp.sp5),
          const AuthDivider(),
          SizedBox(height: sp.sp5),
          if (!_passwordStep) ...[
            ClosTextField(
              label: 'Email',
              hintText: 'you@company.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _continueToPassword(),
            ),
            SizedBox(height: sp.sp6),
            PrimaryButton(
              label: 'Continue',
              expand: true,
              onPressed: _idle ? _continueToPassword : null,
            ),
          ] else ...[
            ConfirmedEmailRow(
              email: _emailController.text.trim(),
              onChange: _changeEmail,
            ),
            SizedBox(height: sp.sp4),
            ClosTextField(
              label: 'Password',
              hintText: 'At least 8 characters',
              controller: _passwordController,
              obscureText: true,
              autofocus: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _submit(),
            ),
            SizedBox(height: sp.sp6),
            PrimaryButton(
              label: 'Create free account',
              expand: true,
              loading: _busy == AuthBusy.submit,
              onPressed: _idle ? _submit : null,
            ),
          ],
          if (_error != null) ...[
            SizedBox(height: sp.sp4),
            InlineNotice(kind: InlineNoticeKind.error, message: _error!),
          ],
          SizedBox(height: sp.sp5),
          const _Fineprint(),
          SizedBox(height: sp.sp5),
          AuthSwitchLine(
            prefix: 'Already have an account?',
            linkLabel: 'Log in',
            onTap: () => LoginRoute(from: widget.from).go(context),
          ),
        ],
      ),
    );
  }
}

/// Terms and privacy live on the marketing site.
class _Fineprint extends StatefulWidget {
  const _Fineprint();

  @override
  State<_Fineprint> createState() => _FineprintState();
}

class _FineprintState extends State<_Fineprint> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(Uri.parse('https://closero.app/terms.html'));
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(Uri.parse('https://closero.app/privacy.html'));
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final base = ClosType.style(
      fontSize: 11.5,
      weight: FontWeight.w400,
      color: colors.body,
    ).copyWith(height: 1.5);
    final link = ClosType.style(
      fontSize: 11.5,
      weight: FontWeight.w600,
      color: colors.hi2,
    );

    return Text.rich(
      TextSpan(
        text: "By signing up, you agree to Closero's ",
        style: base,
        children: [
          TextSpan(
            text: 'Terms of Service',
            style: link,
            recognizer: _termsRecognizer,
            mouseCursor: SystemMouseCursors.click,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: link,
            recognizer: _privacyRecognizer,
            mouseCursor: SystemMouseCursors.click,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
