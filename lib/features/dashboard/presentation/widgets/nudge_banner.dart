import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// In-app reminder banner driven by current time-of-day and today's task
/// progress. Re-renders every 2 hours while the dashboard is open so the
/// message stays fresh without needing real push notifications.
class NudgeBanner extends StatefulWidget {
  final int doneCount;
  final int totalCount;

  const NudgeBanner({
    super.key,
    required this.doneCount,
    required this.totalCount,
  });

  @override
  State<NudgeBanner> createState() => _NudgeBannerState();
}

class _NudgeBannerState extends State<NudgeBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh the banner every 2 hours so the message reflects time-of-day.
    _timer = Timer.periodic(const Duration(hours: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  ({String text, IconData icon, Color color}) _nudgeForNow() {
    final hour = DateTime.now().hour;
    final done = widget.doneCount;
    final total = widget.totalCount;

    // Edge cases first.
    if (total == 0) {
      return (
        text: 'No tasks planned today — enjoy a free day! 🎉',
        icon: Icons.wb_sunny,
        color: AppColors.accent,
      );
    }
    if (done >= total) {
      return (
        text: 'All $total tasks done — your creature is proud! ⭐',
        icon: Icons.celebration,
        color: AppColors.accentGreen,
      );
    }

    final remaining = total - done;

    // Expected progress at this point in the day (between 8 AM and 8 PM).
    const startHour = 8;
    const endHour = 20;
    final clamped = hour.clamp(startHour, endHour);
    final expected = ((clamped - startHour) / (endHour - startHour) * total)
        .round();
    final behind = done < expected - 1; // small grace

    // Time-of-day buckets.
    if (hour < 10) {
      return (
        text: 'Good morning! $remaining tasks for today.',
        icon: Icons.coffee,
        color: AppColors.accent,
      );
    }
    if (hour < 12) {
      return (
        text: behind
            ? 'Morning check-in: $done of $total done. Time to get going!'
            : 'Morning check-in: $done of $total done — keep it up!',
        icon: Icons.directions_run,
        color: behind ? AppColors.accentRed : AppColors.primary,
      );
    }
    if (hour < 15) {
      return (
        text: behind
            ? 'Lunchtime nudge — only $done of $total done. Time to catch up.'
            : 'Halfway through — $done of $total done. Great pace!',
        icon: Icons.restaurant,
        color: behind ? AppColors.accentRed : AppColors.accentGreen,
      );
    }
    if (hour < 18) {
      return (
        text: behind
            ? 'Afternoon: $remaining still to go. You can do it!'
            : 'Afternoon: $remaining left. Almost there!',
        icon: Icons.bolt,
        color: behind ? AppColors.accentRed : AppColors.primary,
      );
    }
    if (hour < 20) {
      return (
        text: 'Evening wrap-up: $remaining more to finish strong! 🏁',
        icon: Icons.nightlight,
        color: AppColors.primary,
      );
    }
    return (
      text: 'Wind-down time — tomorrow is a new day! 🌙',
      icon: Icons.bedtime,
      color: AppColors.textSecondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = _nudgeForNow();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: n.color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: n.color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(n.icon, color: n.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              n.text,
              style: AppTextStyles.body.copyWith(color: n.color),
            ),
          ),
        ],
      ),
    );
  }
}
