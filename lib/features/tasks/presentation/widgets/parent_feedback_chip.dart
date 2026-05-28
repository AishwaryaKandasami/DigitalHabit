import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/task_log_model.dart';

/// Small inline chip that shows the parent's verification result + comment
/// on a task the kid completed.
///
/// Renders nothing when there's no parent action yet (still pending review).
class ParentFeedbackChip extends StatelessWidget {
  final TaskLogModel log;

  const ParentFeedbackChip({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final verified = log.verifiedByParent;
    final comment = (log.parentComment ?? '').trim();

    // Not yet reviewed.
    if (verified == null) return const SizedBox.shrink();

    final IconData icon;
    final Color color;
    final String label;

    if (verified == false) {
      icon = Icons.cancel_outlined;
      color = AppColors.accentRed;
      label = comment.isNotEmpty
          ? '"$comment"'
          : 'Marked not done — please try again.';
    } else if (log.parentFeedback == ParentFeedback.negative) {
      icon = Icons.thumb_down;
      color = AppColors.accentRed;
      label = comment.isNotEmpty
          ? '"$comment"'
          : 'Parent says: needs improvement.';
    } else {
      // approved (positive or no explicit feedback)
      icon = log.parentFeedback == ParentFeedback.positive
          ? Icons.thumb_up
          : Icons.verified;
      color = AppColors.accentGreen;
      label = comment.isNotEmpty
          ? '"$comment"'
          : (log.parentFeedback == ParentFeedback.positive
              ? 'Parent says: great job!'
              : 'Verified by parent ✓');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontStyle: comment.isNotEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
