import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/executive_brief.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class BriefScreen extends StatefulWidget {
  const BriefScreen({super.key});

  @override
  State<BriefScreen> createState() => _BriefScreenState();
}

class _BriefScreenState extends State<BriefScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadBrief();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final brief = state.brief;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Brief'),
        actions: [
          IconButton(
            tooltip: 'Regenerate',
            icon: const Icon(Icons.refresh),
            onPressed: state.briefLoading
                ? null
                : () => context.read<AppState>().loadBrief(force: true),
          ),
        ],
      ),
      body: brief == null
          ? const _Generating()
          : RefreshIndicator(
              onRefresh: () =>
                  context.read<AppState>().loadBrief(force: true),
              child: _BriefBody(brief: brief, refreshing: state.briefLoading),
            ),
    );
  }
}

class _Generating extends StatelessWidget {
  const _Generating();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(height: 16),
          Text('Analyzing your business…',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _BriefBody extends StatelessWidget {
  final ExecutiveBrief brief;
  final bool refreshing;
  const _BriefBody({required this.brief, required this.refreshing});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        Text('${brief.greeting}.',
            style: Theme.of(context).textTheme.headlineSmall),
        if (refreshing)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Refreshing…',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        const SizedBox(height: 16),
        _scoreCard(context),
        const SizedBox(height: 20),
        if (brief.priorities.isNotEmpty) ...[
          const SectionHeader("Today's priorities"),
          ...brief.priorities.map((p) => _PriorityCard(p: p)),
          const SizedBox(height: 12),
        ],
        if (brief.risks.isNotEmpty) ...[
          const SectionHeader('Risks'),
          ...brief.risks.map((r) =>
              _ItemCard(title: r.title, detail: r.detail, color: const Color(0xFFE5484D), icon: Icons.warning_amber_outlined)),
          const SizedBox(height: 12),
        ],
        if (brief.opportunities.isNotEmpty) ...[
          const SectionHeader('Opportunities'),
          ...brief.opportunities.map((o) =>
              _ItemCard(title: o.title, detail: o.detail, color: const Color(0xFF30A46C), icon: Icons.lightbulb_outline)),
          const SizedBox(height: 12),
        ],
        if (brief.recommendation.isNotEmpty) _recommendation(context),
        const SizedBox(height: 16),
        Center(child: _ProviderBadge(provider: brief.provider)),
      ],
    );
  }

  Widget _scoreCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandDeep, AppColors.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ScoreRing(score: brief.score, size: 92, light: true),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BUSINESS HEALTH',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1)),
                const SizedBox(height: 2),
                Text(brief.scoreLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                if (brief.scoreReason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(brief.scoreReason,
                      style: const TextStyle(
                          color: Colors.white70, height: 1.3, fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: AppColors.brand, size: 18),
              SizedBox(width: 8),
              Text('AI recommendation',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.brand)),
            ],
          ),
          const SizedBox(height: 8),
          Text(brief.recommendation,
              style: const TextStyle(height: 1.45, fontSize: 14)),
        ],
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  final BriefPriority p;
  const _PriorityCard({required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 10),
                    child: Icon(Icons.chevron_right, color: AppColors.brand),
                  ),
                  Expanded(
                    child: Text(p.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ],
              ),
              if (p.why.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(p.why,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.35)),
              ],
              if (p.action.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.bolt_outlined,
                        size: 14, color: AppColors.brand),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(p.action,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brand)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final String title;
  final String detail;
  final Color color;
  final IconData icon;
  const _ItemCard(
      {required this.title,
      required this.detail,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(detail,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderBadge extends StatelessWidget {
  final String provider;
  const _ProviderBadge({required this.provider});
  @override
  Widget build(BuildContext context) {
    final label = switch (provider) {
      'openai' => 'Generated by OpenAI',
      'gemini' => 'Generated by Gemini',
      'offline' => 'Offline estimate — connect AI for deeper analysis',
      _ => 'AI-generated',
    };
    return Text(label,
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center);
  }
}
