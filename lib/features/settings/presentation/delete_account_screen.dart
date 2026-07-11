import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/user_doc.dart';
import 'widgets/settings_widgets.dart';

/// Delete account (context/prototype-screens/21-settings-delete.png).
/// Requires typing DELETE, reauthenticates (password or SSO popup),
/// blanks the client-writable profile fields, deletes the auth user,
/// and clears device prefs. The router's auth guard takes over from
/// there.
///
/// Honest scope: an active Closer subscription is NOT cancelled by
/// this flow (no server hook exists yet), so the screen says exactly
/// that instead of the prototype's claim.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirm = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _confirmed = false;
  String? _error;

  @override
  void dispose() {
    _confirm.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_busy || !_confirmed) return;
    final auth = ref.read(authServiceProvider);
    final needsPassword = auth.hasPasswordProvider;
    if (needsPassword && _password.text.isEmpty) {
      setState(() => _error = 'Enter your current password to confirm.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.deleteAccount(
        currentPassword: needsPassword ? _password.text : null,
      );
      // Device prefs (onboarding, practice defaults) go with the
      // account. The auth stream flip routes to login.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = authErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    ref.watch(authStateProvider);
    final hasPassword = ref.watch(authServiceProvider).hasPasswordProvider;
    final onCloser = ref.watch(entitlementProvider) == Entitlement.closer;

    return SettingsSubPage(
      title: 'Delete account',
      intro: "This permanently removes your Closero account. There's no "
          "undo, and we can't recover it afterward.",
      children: [
        const _RemovalNoticeCard(
          items: [
            'Your profile, login, and connected accounts',
            'Your practice preferences on this device',
            'Access to your sessions, progress, and achievements',
          ],
        ),
        if (onCloser) ...[
          SizedBox(height: sp.sp4),
          const InlineNotice(
            kind: InlineNoticeKind.error,
            message: 'Deleting your account does not cancel your Closer '
                'subscription. Cancel it first from Plan & billing, or '
                'from the receipt email RevenueCat sent you.',
          ),
        ],
        SizedBox(height: sp.sectionGap),
        ClosCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClosTextField(
                label: 'Type DELETE to confirm',
                controller: _confirm,
                hintText: 'DELETE',
                onChanged: (value) =>
                    setState(() => _confirmed = value == 'DELETE'),
              ),
              if (hasPassword) ...[
                SizedBox(height: sp.sp4),
                ClosTextField(
                  label: 'Current password',
                  controller: _password,
                  hintText: 'Enter current password',
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                ),
              ] else ...[
                SizedBox(height: sp.sp3),
                Text(
                  'You may be asked to confirm with your login provider.',
                  style: ClosType.style(
                    fontSize: 12.5,
                    weight: FontWeight.w400,
                    color: colors.mid,
                  ),
                ),
              ],
              SizedBox(height: sp.sp6),
              Row(
                children: [
                  DestructiveButton(
                    label: 'Permanently delete account',
                    loading: _busy,
                    onPressed: _confirmed ? _delete : null,
                  ),
                  SizedBox(width: sp.sp3),
                  GhostButton(
                    label: 'Cancel',
                    onPressed: () => const SettingsRoute().go(context),
                  ),
                ],
              ),
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

/// What deletion removes: neutral surface with a 3px red left edge and
/// red heading, never a tinted wash (per the chip/callout rules).
class _RemovalNoticeCard extends StatelessWidget {
  const _RemovalNoticeCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return ClipRRect(
      borderRadius: context.closRadius.cardRadius,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: context.closRadius.cardRadius,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: colors.red,
                child: const SizedBox(width: 3),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(sp.sp5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deleting your account will remove',
                        style: ClosType.style(
                          fontSize: 13.5,
                          weight: FontWeight.w600,
                          color: colors.red,
                        ),
                      ),
                      SizedBox(height: sp.sp2),
                      for (final item in items)
                        Padding(
                          padding: EdgeInsets.only(top: sp.sp1),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: colors.dim2,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              SizedBox(width: sp.sp2),
                              Expanded(
                                child: Text(
                                  item,
                                  style: ClosType.style(
                                    fontSize: 13,
                                    weight: FontWeight.w400,
                                    color: colors.body,
                                  ).copyWith(height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
