import 'package:flutter/material.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    required this.activity,
    this.showDate = true,
    super.key,
  });

  final Activity activity;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventCardHeader(event: activity, showDate: showDate),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (activity.image != null) ...[
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: AssetImage(activity.image!),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Text(
                        activity.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (activity.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      activity.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  EventCardFooter(
                    location: activity.location,
                    label: 'Activity',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
