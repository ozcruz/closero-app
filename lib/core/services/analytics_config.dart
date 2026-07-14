/// Compile-time PostHog configuration, set with --dart-define.
library;

/// The PostHog project API key (phc_...). This is a publishable,
/// client-side key by design (posthog-js runs it in the browser);
/// passing it with --dart-define keeps it out of committed source, not
/// out of the shipped bundle. Empty by default so a build without it
/// configured runs the no-op analytics service and never contacts
/// PostHog.
/// Set with: flutter build web --dart-define=POSTHOG_API_KEY=phc_...
const String kPosthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');

/// PostHog ingestion host. US cloud by default, matching the project's
/// region (chosen for a US-based operator; PostHog data residency is
/// fixed per project at creation and cannot be changed after).
/// Override for the EU cloud with:
/// --dart-define=POSTHOG_HOST=https://eu.i.posthog.com
const String kPosthogHost = String.fromEnvironment(
  'POSTHOG_HOST',
  defaultValue: 'https://us.i.posthog.com',
);
