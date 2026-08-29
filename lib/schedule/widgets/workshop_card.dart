import 'package:flutter/material.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';
import 'package:flutter_and_friends/speakers/speakers.dart';
import 'package:flutter_and_friends/workshop_details/workshop_details.dart';

class WorkshopCard extends StatelessWidget {
  const WorkshopCard({
    required this.workshop,
    this.showDate = true,
    super.key,
  });

  final Workshop workshop;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(WorkshopDetailsPage.route(workshop: workshop)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventCardHeader(event: workshop, showDate: showDate),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workshop.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...workshop.speakers.map(
                    (speaker) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Hero(
                            tag: speaker.name,
                            child: SpeakerPhoto(speaker: speaker, radius: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  speaker.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  speaker.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  EventCardFooter(
                    location: workshop.location,
                    label: 'Workshop',
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
