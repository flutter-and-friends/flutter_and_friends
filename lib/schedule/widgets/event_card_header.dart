import 'package:flutter/material.dart';
import 'package:flutter_and_friends/extensions/extensions.dart';
import 'package:flutter_and_friends/favorites/favorites.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';

class EventCardHeader extends StatelessWidget {
  const EventCardHeader({
    required this.event,
    this.showDate = true,
    super.key,
  });

  final Event event;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = showDate
        ? event.startTime.prettyPrint(context, event.duration)
        : event.startTime.prettyPrintTime(context, event.duration);
    return Padding(
      // The favorite IconButton pads its 24px icon by 12px on each side, so
      // 6px here lines the heart up with the 18px card padding on the left.
      padding: const EdgeInsets.only(left: 18, right: 6),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 18,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              time,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FavoriteButton(event: event),
        ],
      ),
    );
  }
}
