import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which scenario set the Simulations library opens to by default.
enum PracticeAudience {
  b2c,
  b2b;

  static PracticeAudience parse(String? raw) =>
      raw == 'b2b' ? PracticeAudience.b2b : PracticeAudience.b2c;

  String get label => this == PracticeAudience.b2b ? 'B2B' : 'B2C';
}

/// Default session format when starting a scenario.
enum PracticeSimType {
  audio,
  video;

  static PracticeSimType parse(String? raw) =>
      raw == 'video' ? PracticeSimType.video : PracticeSimType.audio;

  String get label => this == PracticeSimType.video ? 'Video' : 'Audio';
}

/// Client-side product preferences (settings screen). Device-local by
/// the v1 persistence decision: Firestore holds account data, prefs
/// hold client product state.
class SettingsPrefs {
  const SettingsPrefs({
    this.audience = PracticeAudience.b2c,
    this.simType = PracticeSimType.audio,
    this.streakReminder = true,
    this.weeklySummary = true,
  });

  final PracticeAudience audience;
  final PracticeSimType simType;
  final bool streakReminder;
  final bool weeklySummary;

  SettingsPrefs copyWith({
    PracticeAudience? audience,
    PracticeSimType? simType,
    bool? streakReminder,
    bool? weeklySummary,
  }) =>
      SettingsPrefs(
        audience: audience ?? this.audience,
        simType: simType ?? this.simType,
        streakReminder: streakReminder ?? this.streakReminder,
        weeklySummary: weeklySummary ?? this.weeklySummary,
      );
}

/// shared_preferences persistence for [SettingsPrefs].
class SettingsStore {
  const SettingsStore();

  static const _kAudience = 'settings.defaultAudience';
  static const _kSimType = 'settings.defaultSimType';
  static const _kStreakReminder = 'settings.streakReminder';
  static const _kWeeklySummary = 'settings.weeklySummary';

  Future<SettingsPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsPrefs(
      audience: PracticeAudience.parse(prefs.getString(_kAudience)),
      simType: PracticeSimType.parse(prefs.getString(_kSimType)),
      streakReminder: prefs.getBool(_kStreakReminder) ?? true,
      weeklySummary: prefs.getBool(_kWeeklySummary) ?? true,
    );
  }

  Future<void> save(SettingsPrefs value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAudience, value.audience.name);
    await prefs.setString(_kSimType, value.simType.name);
    await prefs.setBool(_kStreakReminder, value.streakReminder);
    await prefs.setBool(_kWeeklySummary, value.weeklySummary);
  }
}

final settingsStoreProvider =
    Provider<SettingsStore>((ref) => const SettingsStore());

/// The live prefs, with persisting setters. Loads once per session;
/// updates apply optimistically (shared_preferences writes don't fail
/// in practice on web/localStorage).
class SettingsPrefsNotifier extends AsyncNotifier<SettingsPrefs> {
  @override
  Future<SettingsPrefs> build() => ref.watch(settingsStoreProvider).load();

  Future<void> _update(SettingsPrefs next) async {
    state = AsyncData(next);
    await ref.read(settingsStoreProvider).save(next);
  }

  Future<void> setAudience(PracticeAudience value) async =>
      _update(_current.copyWith(audience: value));

  Future<void> setSimType(PracticeSimType value) async =>
      _update(_current.copyWith(simType: value));

  Future<void> setStreakReminder({required bool value}) async =>
      _update(_current.copyWith(streakReminder: value));

  Future<void> setWeeklySummary({required bool value}) async =>
      _update(_current.copyWith(weeklySummary: value));

  SettingsPrefs get _current => state.value ?? const SettingsPrefs();
}

final settingsPrefsProvider =
    AsyncNotifierProvider<SettingsPrefsNotifier, SettingsPrefs>(
  SettingsPrefsNotifier.new,
);
