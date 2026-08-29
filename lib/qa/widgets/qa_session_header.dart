import 'package:flutter/material.dart';
import 'package:flutter_and_friends/extensions/extensions.dart';
import 'package:flutter_and_friends/qa/qa.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';
import 'package:flutter_and_friends/talk_details/talk_details.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Introduces the session the questions are for, with a link to its entry
/// in the schedule when the feed knows about it.
class QaSessionHeader extends StatelessWidget {
  const QaSessionHeader({required this.session, super.key});

  final QaSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final talk = context.select((ScheduleDataCubit cubit) {
      for (final event in cubit.state.schedule.events) {
        if (event.id == session.id && event is Talk) return event;
      }
      return null;
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          session.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Featuring ${session.panelistsLabel}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (talk != null) ...[
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.of(context).push(
              TalkDetailsPage.route(talk: talk),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      talk.startTime.prettyPrint(context, talk.duration),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.secondary,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Ask the panel anything and upvote the questions you want answered. '
          'The most upvoted questions are asked first.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
