import 'package:closero_app/features/dashboard/data/dashboard_repository.dart';
import 'package:closero_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:closero_app/features/onboarding/data/onboarding_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FixtureDashboardRepository', () {
    test('serves the canonical Sandra Voss sheet', () async {
      SharedPreferences.setMockInitialValues({});
      final data =
          await const FixtureDashboardRepository(OnboardingStore()).load();

      expect(data.streakDays, 9);
      expect(data.earning.currentLabel, r'$64K');
      expect(data.earning.entryLabel, r'$40K entry');
      expect(data.earning.topLabel, r'$150K top performer');
      expect(data.earning.nextTierNote, contains('per published comp data'));
      // Skill-tier movement only, never a personal dollar delta.
      expect(data.earning.tierDelta, isNot(contains(r'$')));

      expect(data.recentSessions, hasLength(3));
      expect(data.recentSessions.map((s) => s.score), [84, 61, 77]);
      expect(data.skills, hasLength(5));
    });

    test('sorts skills weakest first', () async {
      SharedPreferences.setMockInitialValues({});
      final data =
          await const FixtureDashboardRepository(OnboardingStore()).load();

      final percents = data.skills.map((s) => s.percent).toList();
      expect(percents, [38, 46, 54, 63, 71]);
      expect(data.skills.first.label, 'Objection handling');
    });

    test('hero falls back to the canonical gatekeeper at session zero',
        () async {
      SharedPreferences.setMockInitialValues({});
      final data =
          await const FixtureDashboardRepository(OnboardingStore()).load();

      expect(data.featured.id, gatekeeperFeatured.id);
      expect(data.featured.title, 'Cold Call, SaaS Gatekeeper');
    });

    test('hero resolves the onboarding-recommended scenario', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding.recommendedScenarioId': 'cold-call-skeptical-homeowner',
      });
      final data =
          await const FixtureDashboardRepository(OnboardingStore()).load();

      expect(data.featured.id, homeownerFeatured.id);
      expect(data.featured.personaLine, 'Denise, homeowner');
    });

    test('hero falls back to the gatekeeper on an unknown stored id',
        () async {
      SharedPreferences.setMockInitialValues({
        'onboarding.recommendedScenarioId': 'retired-scenario',
      });
      final data =
          await const FixtureDashboardRepository(OnboardingStore()).load();

      expect(data.featured.id, gatekeeperFeatured.id);
    });
  });

  group('greetingFor', () {
    test('is mechanically true to the clock', () {
      expect(greetingFor(DateTime(2026, 7, 10, 9)), 'Good morning');
      expect(greetingFor(DateTime(2026, 7, 10, 11, 59)), 'Good morning');
      expect(greetingFor(DateTime(2026, 7, 10, 12)), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 7, 10, 16, 59)), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 7, 10, 17)), 'Good evening');
      expect(greetingFor(DateTime(2026, 7, 10, 23)), 'Good evening');
    });
  });
}
