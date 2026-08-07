import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../theme/app_theme.dart';

/// Small uppercase section label with an optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PriorityChip extends StatelessWidget {
  final Priority priority;
  final bool dense;
  const PriorityChip(this.priority, {super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 7 : 9, vertical: dense ? 2 : 3),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: priority.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          fontSize: dense ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: priority.color,
        ),
      ),
    );
  }
}

/// Simple pill/tag.
class Pill extends StatelessWidget {
  final String text;
  final Color? color;
  final IconData? icon;
  const Pill(this.text, {super.key, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).textTheme.bodySmall!.color!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: c),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: c)),
        ],
      ),
    );
  }
}

/// A stat tile used on the dashboard.
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? accent;
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? AppColors.brand;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: c, size: 18),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyState(
      {super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 46,
                color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

/// Circular "Business Health" gauge (0–100).
class ScoreRing extends StatelessWidget {
  final int score;
  final double size;
  final bool light; // white text/track for use on a coloured background
  const ScoreRing(
      {super.key, required this.score, this.size = 84, this.light = false});

  Color get _color {
    if (light) return Colors.white;
    if (score >= 85) return const Color(0xFF30A46C);
    if (score >= 70) return AppColors.brand;
    if (score >= 50) return const Color(0xFFF5A524);
    return const Color(0xFFE5484D);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (score.clamp(0, 100)) / 100,
              strokeWidth: size * 0.09,
              strokeCap: StrokeCap.round,
              backgroundColor:
                  (light ? Colors.white : _color).withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score',
                  style: TextStyle(
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: light ? Colors.white : null,
                  )),
              Text('/100',
                  style: TextStyle(
                    fontSize: size * 0.13,
                    fontWeight: FontWeight.w600,
                    color: light
                        ? Colors.white70
                        : Theme.of(context).textTheme.bodySmall?.color,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

/// A rounded avatar with initials.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  const InitialsAvatar(this.name, {super.key, this.size = 40, this.color});

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brand;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, c.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
