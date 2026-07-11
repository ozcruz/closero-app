import 'package:closero_app/features/settings/data/settings_store.dart';
import 'package:closero_app/features/settings/presentation/change_password_screen.dart';
import 'package:closero_app/features/settings/presentation/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsStore', () {
    test('defaults: B2C, audio, both notifications on', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await const SettingsStore().load();
      expect(prefs.audience, PracticeAudience.b2c);
      expect(prefs.simType, PracticeSimType.audio);
      expect(prefs.streakReminder, isTrue);
      expect(prefs.weeklySummary, isTrue);
    });

    test('round-trips every field', () async {
      SharedPreferences.setMockInitialValues({});
      const store = SettingsStore();
      await store.save(
        const SettingsPrefs(
          audience: PracticeAudience.b2b,
          simType: PracticeSimType.video,
          streakReminder: false,
          weeklySummary: false,
        ),
      );
      final loaded = await store.load();
      expect(loaded.audience, PracticeAudience.b2b);
      expect(loaded.simType, PracticeSimType.video);
      expect(loaded.streakReminder, isFalse);
      expect(loaded.weeklySummary, isFalse);
    });

    test('unknown stored values fall back to safe defaults', () async {
      SharedPreferences.setMockInitialValues({
        'settings.defaultAudience': 'enterprise',
        'settings.defaultSimType': 'hologram',
      });
      final prefs = await const SettingsStore().load();
      expect(prefs.audience, PracticeAudience.b2c);
      expect(prefs.simType, PracticeSimType.audio);
    });
  });

  group('newPasswordError', () {
    test('accepts a compliant password', () {
      expect(newPasswordError('closerdeal42'), isNull);
    });

    test('rejects short, letter-less, and number-less passwords', () {
      expect(newPasswordError('short1a'), isNotNull);
      expect(newPasswordError('1234567890'), isNotNull);
      expect(newPasswordError('passwordonly'), isNotNull);
    });
  });

  group('joinedLabel', () {
    test('formats month and year, and tolerates null', () {
      expect(joinedLabel(DateTime(2026, 2, 14)), 'Joined Feb 2026');
      expect(joinedLabel(null), isNull);
    });
  });
}
