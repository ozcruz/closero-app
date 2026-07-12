/// One advanced-framework reference card. Reference only: there is no
/// drill-down; the card's single link points at the scenario library.
class Methodology {
  const Methodology({
    required this.id,
    required this.name,
    required this.era,
    required this.summary,
    required this.concepts,
    required this.scenarioCount,
    this.bestAverage,
  });

  final String id;

  /// e.g. 'Sandler Method'.
  final String name;

  /// Year the framework was published or founded, e.g. '1967'.
  final String era;

  /// Two or three reference sentences on the mechanics.
  final String summary;

  /// Four concept chips, e.g. 'Pain funnel'.
  final List<String> concepts;

  /// Library scenarios tagged with this framework.
  final int scenarioCount;

  /// Server-written average across this framework's completed
  /// scenarios; null renders 'Not started'.
  final int? bestAverage;
}

/// The five Closer frameworks, the fixed reference set. Sandler,
/// SPIN, Challenger, Straight Line, and 7th Level, in shelf order.
const methodologyCatalog = [
  Methodology(
    id: 'sandler',
    name: 'Sandler Method',
    era: '1967',
    summary: 'Reverse selling built on pain-based discovery. The prospect '
        'talks themselves into the deal by uncovering their own pain '
        'before you ever pitch. You are not chasing the deal, they are '
        'qualifying for your time.',
    concepts: [
      'Pain funnel',
      'Up-front contracts',
      'No free consulting',
      'Reverse selling',
    ],
    scenarioCount: 6,
    bestAverage: 74,
  ),
  Methodology(
    id: 'spin',
    name: 'SPIN Selling',
    era: '1988',
    summary: 'Question-led discovery for complex, multi-stakeholder '
        'sales. Situation, Problem, Implication, Need-payoff: each stage '
        'earns the right to move to the next, so you never pitch before '
        'the prospect feels the cost of doing nothing.',
    concepts: [
      'Situation questions',
      'Problem questions',
      'Implication questions',
      'Need-payoff questions',
    ],
    scenarioCount: 5,
    bestAverage: 68,
  ),
  Methodology(
    id: 'challenger',
    name: 'Challenger Sale',
    era: '2011',
    summary: 'Teach, tailor, and take control. Lead with a piece of '
        'commercial insight the prospect has not considered, reframe the '
        'deal around it, then stay steady through the constructive '
        'tension that creates.',
    concepts: [
      'Commercial teaching',
      'Tailored messaging',
      'Constructive tension',
      'Deal control',
    ],
    scenarioCount: 4,
  ),
  Methodology(
    id: 'straight-line',
    name: 'Straight Line Selling',
    era: '2017',
    summary: 'Certainty-first persuasion built for fast-cycle, '
        'high-volume selling. Keep the prospect moving in a straight '
        'line toward the close, loop back on objections without losing '
        'control, and let tonality carry as much weight as the words.',
    concepts: [
      'Three tens',
      'Looping',
      'Tonality control',
      'State management',
    ],
    scenarioCount: 5,
    bestAverage: 71,
  ),
  Methodology(
    id: 'seventh-level',
    name: '7th Level',
    era: '2016',
    summary: 'Neuro-emotional persuasion questioning. Detached, curious '
        'questions lower the prospect\'s guard so they persuade '
        'themselves, and verbal pacing does the heavy lifting long '
        'before any pitch.',
    concepts: [
      'NEPQ',
      'Connecting questions',
      'Problem awareness',
      'Commitment questions',
    ],
    scenarioCount: 4,
    bestAverage: 62,
  ),
];
