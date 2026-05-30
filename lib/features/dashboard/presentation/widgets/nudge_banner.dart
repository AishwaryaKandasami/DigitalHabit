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

    // Always warm and encouraging — never critical, never red.
    if (total == 0) {
      return (
        text: 'Free day — enjoy! 🎉',
        icon: Icons.wb_sunny,
        color: AppColors.accent,
      );
    }
    if (done >= total) {
      return (
        text: 'All done — amazing! ⭐',
        icon: Icons.celebration,
        color: AppColors.accentGreen,
      );
    }

    final remaining = total - done;

    if (hour < 10) {
      return (
        text: 'Good morning! $remaining to go 🌞',
        icon: Icons.wb_twilight,
        color: AppColors.primary,
      );
    }
    if (hour < 12) {
      return (
        text: '$done of $total done — keep it up! 💪',
        icon: Icons.directions_run,
        color: AppColors.primary,
      );
    }
    if (hour < 15) {
      return (
        text: 'Great pace — $remaining left! 🌟',
        icon: Icons.restaurant,
        color: AppColors.accentGreen,
      );
    }
    if (hour < 18) {
      return (
        text: 'Almost there — $remaining to go! ✨',
        icon: Icons.bolt,
        color: AppColors.primary,
      );
    }
    if (hour < 20) {
      return (
        text: 'Finish strong — $remaining left! 🏁',
        icon: Icons.nightlight,
        color: AppColors.primary,
      );
    }
    return (
      text: 'Great day — rest up! 🌙',
      icon: Icons.bedtime,
      color: AppColors.primary,
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
