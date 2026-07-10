/// Answers collected by the six-step onboarding flow. Stored locally
/// (shared_preferences) so the Dashboard can pre-load the recommended
/// scenario at session zero; never written to server-owned fields.
library;

/// Who the rep sells to. Copy never says B2B/B2C: the options read
/// "I sell to businesses" / "I sell to people, directly".
enum SellTrack {
  business,
  consumer;

  static SellTrack? parse(String? raw) => switch (raw) {
        'business' => SellTrack.business,
        'consumer' => SellTrack.consumer,
        _ => null,
      };
}

/// How long they have been selling.
enum ExperienceLevel {
  gettingStarted,
  underTwoYears,
  twoToFiveYears,
  fivePlusYears;

  static ExperienceLevel? parse(String? raw) {
    for (final level in values) {
      if (level.name == raw) return level;
    }
    return null;
  }
}

/// Where they want to improve most. One per locked scoring category
/// (context/scoring-rubric.md); the names mirror the category keys.
enum FocusArea {
  objections,
  discovery,
  rapport,
  closing,
  tonality;

  static FocusArea? parse(String? raw) {
    for (final area in values) {
      if (area.name == raw) return area;
    }
    return null;
  }
}

class OnboardingAnswers {
  const OnboardingAnswers({
    required this.track,
    required this.experience,
    required this.focus,
  });

  final SellTrack track;
  final ExperienceLevel experience;
  final FocusArea focus;
}
