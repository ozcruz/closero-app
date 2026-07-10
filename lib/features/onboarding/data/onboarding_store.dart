import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/onboarding_answers.dart';

/// Local persistence for the onboarding result (shared_preferences,
/// per the v1 persistence decision: Firestore stays the source of
/// truth for account data, prefs hold client-side product state).
///
/// The recommended scenario id saved here is what keeps the Dashboard
/// hero from being empty at session zero.
class OnboardingStore {
  const OnboardingStore();

  static const _kComplete = 'onboarding.complete';
  static const _kTrack = 'onboarding.track';
  static const _kExperience = 'onboarding.experience';
  static const _kFocus = 'onboarding.focus';
  static const _kRecommendedScenarioId = 'onboarding.recommendedScenarioId';

  Future<void> saveResult({
    required OnboardingAnswers answers,
    required String recommendedScenarioId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTrack, answers.track.name);
    await prefs.setString(_kExperience, answers.experience.name);
    await prefs.setString(_kFocus, answers.focus.name);
    await prefs.setString(_kRecommendedScenarioId, recommendedScenarioId);
    await prefs.setBool(_kComplete, true);
  }

  Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kComplete) ?? false;
  }

  Future<String?> recommendedScenarioId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRecommendedScenarioId);
  }

  Future<OnboardingAnswers?> answers() async {
    final prefs = await SharedPreferences.getInstance();
    final track = SellTrack.parse(prefs.getString(_kTrack));
    final experience = ExperienceLevel.parse(prefs.getString(_kExperience));
    final focus = FocusArea.parse(prefs.getString(_kFocus));
    if (track == null || experience == null || focus == null) return null;
    return OnboardingAnswers(
      track: track,
      experience: experience,
      focus: focus,
    );
  }
}

final onboardingStoreProvider =
    Provider<OnboardingStore>((ref) => const OnboardingStore());
