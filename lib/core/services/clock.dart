import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable "now" so time-dependent logic (greetings, cap-reset
/// labels, the trial window) is testable. Production is DateTime.now.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
