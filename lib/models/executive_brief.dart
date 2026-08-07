// Structured executive brief produced by the AI edge function (or the offline
// engine as a fallback).

class BriefPriority {
  final String title;
  final String why;
  final String action;
  const BriefPriority(
      {required this.title, this.why = '', this.action = ''});

  factory BriefPriority.fromJson(Map<String, dynamic> m) => BriefPriority(
        title: (m['title'] ?? '').toString(),
        why: (m['why'] ?? '').toString(),
        action: (m['action'] ?? '').toString(),
      );
}

class BriefItem {
  final String title;
  final String detail;
  const BriefItem({required this.title, this.detail = ''});

  factory BriefItem.fromJson(Map<String, dynamic> m) => BriefItem(
        title: (m['title'] ?? '').toString(),
        detail: (m['detail'] ?? '').toString(),
      );
}

class ExecutiveBrief {
  final int score;
  final String scoreReason;
  final String greeting;
  final String headline;
  final List<BriefPriority> priorities;
  final List<BriefItem> risks;
  final List<BriefItem> opportunities;
  final String recommendation;

  /// 'openai' | 'gemini' | 'offline'
  final String provider;

  const ExecutiveBrief({
    required this.score,
    required this.scoreReason,
    required this.greeting,
    required this.headline,
    required this.priorities,
    required this.risks,
    required this.opportunities,
    required this.recommendation,
    required this.provider,
  });

  bool get isOffline => provider == 'offline';

  static int _int(dynamic v) {
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) {
    if (v is! List) return const [];
    return v
        .whereType<Map>()
        .map((e) => f(Map<String, dynamic>.from(e)))
        .toList();
  }

  factory ExecutiveBrief.fromJson(Map<String, dynamic> m, String provider) {
    return ExecutiveBrief(
      score: _int(m['score']).clamp(0, 100),
      scoreReason: (m['score_reason'] ?? '').toString(),
      greeting: (m['greeting'] ?? 'Good morning').toString(),
      headline: (m['headline'] ?? '').toString(),
      priorities: _list(m['priorities'], BriefPriority.fromJson),
      risks: _list(m['risks'], BriefItem.fromJson),
      opportunities: _list(m['opportunities'], BriefItem.fromJson),
      recommendation: (m['recommendation'] ?? '').toString(),
      provider: provider,
    );
  }

  String get scoreLabel {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Healthy';
    if (score >= 50) return 'Needs attention';
    return 'At risk';
  }
}
