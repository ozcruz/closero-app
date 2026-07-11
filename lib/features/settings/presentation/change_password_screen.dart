import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import 'widgets/settings_widgets.dart';

/// The password policy for new passwords, stricter than Firebase's
/// minimum. Returns a human message or null when the password passes.
@visibleForTesting
String? newPasswordError(String value) {
  if (value.length < 10) return 'Use at least 10 characters.';
  if (!value.contains(RegExp('[A-Za-z]'))) return 'Include at least one letter.';
  if (!value.contains(RegExp('[0-9]'))) return 'Include at least one number.';
  return null;
}

/// Change password (context/prototype-screens/19-settings-password.png):
/// reauthenticates with the current password, then updates. Only
/// reachable meaningfully for accounts with password login; SSO-only
/// accounts see an honest notice instead of a dead form.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final current = _current.text;
    final next = _next.text;

    String? error;
    if (current.isEmpty) {
      error = 'Enter your current password.';
    } else {
      error = newPasswordError(next);
    }
    if (error == null && next != _confirm.text) {
      error = "Those passwords don't match.";
    }
    if (error != null) {
      setState(() {
        _error = error;
        _info = null;
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(authServiceProvider).changePassword(
            currentPassword: current,
            newPassword: next,
          );
      if (mounted) {
        _current.clear();
        _next.clear();
        _confirm.clear();
        setState(() => _info = 'Password updated.');
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final colors = context.closColors;
    // Rebuild if providers change (e.g. password linked elsewhere).
    ref.watch(authStateProvider);
    final hasPassword = ref.watch(authServiceProvider).hasPasswordProvider;

    return SettingsSubPage(
      title: 'Change password',
      intro: 'Use at least 10 characters with a mix of letters and '
          "numbers. You'll stay logged in on this device.",
      children: [
        if (!hasPassword)
          const InlineNotice(
            kind: InlineNoticeKind.info,
            message: 'Password login is not set up for this account. You '
                'log in with a connected provider; manage it under '
                'Connected accounts.',
          )
        else
          ClosCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClosTextField(
                  label: 'Current password',
                  controller: _current,
                  hintText: 'Enter current password',
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: sp.sp4),
                ClosTextField(
                  label: 'New password',
                  controller: _next,
                  hintText: 'Enter new password',
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: sp.sp1),
                Text(
                  'At least 10 characters, one number, one letter.',
                  style: ClosType.style(
                    fontSize: 12,
                    weight: FontWeight.w400,
                    color: colors.mid,
                  ),
                ),
                SizedBox(height: sp.sp4),
                ClosTextField(
                  label: 'Confirm new password',
                  controller: _confirm,
                  hintText: 'Re-enter new password',
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                SizedBox(height: sp.sp6),
                Row(
                  children: [
                    PrimaryButton(
                      label: 'Update password',
                      loading: _busy,
                      onPressed: _submit,
                    ),
                    SizedBox(width: sp.sp3),
                    GhostButton(
                      label: 'Cancel',
                      onPressed: () => const SettingsRoute().go(context),
                    ),
                  ],
                ),
                if (_info != null) ...[
                  SizedBox(height: sp.sp3),
                  InlineNotice(kind: InlineNoticeKind.info, message: _info!),
                ],
                if (_error != null) ...[
                  SizedBox(height: sp.sp3),
                  InlineNotice(kind: InlineNoticeKind.error, message: _error!),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
