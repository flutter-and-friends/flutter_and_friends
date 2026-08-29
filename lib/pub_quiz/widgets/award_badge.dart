import 'package:flutter/material.dart';
import 'package:flutter_and_friends/pub_quiz/models/models.dart';

/// "+2", or "+3" with a lightning bolt for a fastest-correct bonus.
class AwardBadge extends StatelessWidget {
  const AwardBadge({required this.award, this.large = false, super.key});

  final PubQuizAward award;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fast = award.fastRank != null;
    final color = fast ? const Color(0xFFD89E00) : const Color(0xFF26890C);
    return Semantics(
      label: '${award.points} points${fast ? ', fastest bonus' : ''}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 14 : 10,
          vertical: large ? 8 : 4,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fast) ...[
              Icon(Icons.bolt, color: Colors.white, size: large ? 22 : 16),
              const SizedBox(width: 2),
            ],
            Text(
              '+${award.points}',
              style:
                  (large
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.titleSmall)
                      ?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
