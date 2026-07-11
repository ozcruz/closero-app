import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/feature_flags.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import 'widgets/settings_widgets.dart';

/// SSO providers this build can link. Apple stays hidden until an
/// Apple Developer account exists (same gate as the login screen);
/// listing a provider Firebase can't serve would be a false promise.
class _ProviderDef {
  const _ProviderDef({
    required this.id,
    required this.name,
    required this.glyph,
  });

  final String id;
  final String name;
  final String glyph;
}

const List<_ProviderDef> _providers = [
  _ProviderDef(id: 'google.com', name: 'Google', glyph: 'G'),
  if (kAppleSsoEnabled)
    _ProviderDef(id: 'apple.com', name: 'Apple', glyph: 'A'),
];

/// Connected accounts
/// (context/prototype-screens/20-settings-connected.png). Linking uses
/// the Firebase popup flow; disconnecting is blocked while a provider
/// is the account's only way in.
class ConnectedAccountsScreen extends ConsumerStatefulWidget {
  const ConnectedAccountsScreen({super.key});

  @override
  ConsumerState<ConnectedAccountsScreen> createState() =>
      _ConnectedAccountsScreenState();
}

class _ConnectedAccountsScreenState
    extends ConsumerState<ConnectedAccountsScreen> {
  String? _busyProviderId;
  String? _error;

  Future<void> _connect(_ProviderDef provider) async {
    await _run(provider, () async {
      await ref.read(authServiceProvider).linkProvider(provider.id);
    });
  }

  Future<void> _disconnect(_ProviderDef provider) async {
    await _run(provider, () async {
      await ref.read(authServiceProvider).unlinkProvider(provider.id);
    });
  }

  Future<void> _run(
    _ProviderDef provider,
    Future<void> Function() action,
  ) async {
    if (_busyProviderId != null) return;
    setState(() {
      _busyProviderId = provider.id;
      _error = null;
    });
    try {
      await action();
    } on Object catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busyProviderId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    // Rebuilds when linking/unlinking reloads the user.
    ref.watch(authStateProvider);
    final auth = ref.watch(authServiceProvider);
    final linked = auth.linkedProviders;

    return SettingsSubPage(
      title: 'Connected accounts',
      intro: 'Log in faster and keep your account recoverable. You can '
          'disconnect a provider as long as one login method stays '
          'active.',
      children: [
        ClosCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _providers.length; i++)
                _ProviderRow(
                  provider: _providers[i],
                  divided: i > 0,
                  connectedEmail: linked
                      .where((p) => p.providerId == _providers[i].id)
                      .map((p) => p.email)
                      .firstOrNull,
                  connected:
                      linked.any((p) => p.providerId == _providers[i].id),
                  lastMethod: linked.length <= 1,
                  busy: _busyProviderId == _providers[i].id,
                  onConnect: () => _connect(_providers[i]),
                  onDisconnect: () => _disconnect(_providers[i]),
                ),
            ],
          ),
        ),
        if (_error != null) ...[
          SizedBox(height: sp.sp3),
          InlineNotice(kind: InlineNoticeKind.error, message: _error!),
        ],
      ],
    );
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.provider,
    required this.divided,
    required this.connected,
    required this.connectedEmail,
    required this.lastMethod,
    required this.busy,
    required this.onConnect,
    required this.onDisconnect,
  });

  final _ProviderDef provider;
  final bool divided;
  final bool connected;
  final String? connectedEmail;

  /// True when the account has a single sign-in method left, which
  /// makes disconnecting this one impossible.
  final bool lastMethod;
  final bool busy;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    // Green marks the live connected state; disconnected stays neutral.
    final status = connected
        ? Text(
            ['Connected', ?connectedEmail].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClosType.style(
              fontSize: 12.5,
              weight: FontWeight.w400,
              color: colors.green,
            ),
          )
        : Text(
            'Not connected',
            style: ClosType.style(
              fontSize: 12.5,
              weight: FontWeight.w400,
              color: colors.mid,
            ),
          );

    return Container(
      padding: EdgeInsets.symmetric(vertical: sp.sp4),
      decoration: divided
          ? BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surface2,
              border: Border.all(color: colors.border2),
              borderRadius: context.closRadius.buttonRadius,
            ),
            child: Center(
              child: Text(
                provider.glyph,
                style: ClosType.style(
                  fontSize: 14,
                  weight: FontWeight.w600,
                  color: colors.hi2,
                ),
              ),
            ),
          ),
          SizedBox(width: sp.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.name, style: context.closType.titleMedium),
                SizedBox(height: sp.sp1),
                status,
              ],
            ),
          ),
          SizedBox(width: sp.sp4),
          if (connected)
            GhostButton(
              label: 'Disconnect',
              size: ClosButtonSize.medium,
              loading: busy,
              onPressed: lastMethod ? null : onDisconnect,
            )
          else
            GhostButton(
              label: 'Connect',
              size: ClosButtonSize.medium,
              loading: busy,
              onPressed: onConnect,
            ),
        ],
      ),
    );
  }
}
