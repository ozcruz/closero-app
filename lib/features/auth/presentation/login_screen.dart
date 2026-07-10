import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/feature_flags.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_widgets.dart';

/// Which async action is in flight, so one spinner shows at a time and
/// the rest of the card disables.
enum AuthBusy { none, google, apple, submit }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.from});

  /// In-app location to return to after signing in (deep links).
  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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

  void _goHome() => context.go(widget.from ?? DashboardRoute.path);

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.isEmpty || !_idle) return;
    setState(() {
      _busy = AuthBusy.submit;
      _error = null;
    });
    try {
      await _auth.signInWithEmail(
        email: _emailController.text.trim(),
        password: password,
      );
      if (!mounted) return;
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        VerifyEmailRoute(from: widget.from).go(context);
      } else {
        _goHome();
      }
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
      if (mounted) _goHome();
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
      card: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthEyebrow(text: 'Log in'),
          SizedBox(height: sp.sp3),
          Text('Welcome back.', style: type.headlineLarge),
          SizedBox(height: sp.sp3),
          Text(
            'Pick up where you left off. Your next scenario is waiting.',
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
              labelTrailing: LinkText(
                label: 'Forgot password?',
                alignment: Alignment.bottomRight,
                onTap: () => const ResetPasswordRoute().go(context),
              ),
              controller: _passwordController,
              obscureText: true,
              autofocus: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
            ),
            SizedBox(height: sp.sp6),
            PrimaryButton(
              label: 'Log in',
              expand: true,
              loading: _busy == AuthBusy.submit,
              onPressed: _idle ? _submit : null,
            ),
          ],
          if (_error != null) ...[
            SizedBox(height: sp.sp4),
            InlineNotice(kind: InlineNoticeKind.error, message: _error!),
          ],
          SizedBox(height: sp.sp6),
          AuthSwitchLine(
            prefix: "Don't have an account?",
            linkLabel: 'Sign up free',
            onTap: () => SignupRoute(from: widget.from).go(context),
          ),
        ],
      ),
    );
  }
}
