import 'package:flutter/material.dart';
import 'package:flutter_and_friends/favorites/favorites.dart';
import 'package:flutter_and_friends/location/location.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';
import 'package:flutter_and_friends/speaker_details/speaker_details.dart';
import 'package:flutter_and_friends/speakers/speakers.dart';
import 'package:intl/intl.dart';

class WorkshopDetailsPage extends StatelessWidget {
  const WorkshopDetailsPage({required this.workshop, super.key});

  static Route<void> route({required Workshop workshop}) {
    return MaterialPageRoute(
      builder: (_) => WorkshopDetailsPage(workshop: workshop),
    );
  }

  final Workshop workshop;

  @override
  Widget build(BuildContext context) => WorkshopDetailsView(workshop: workshop);
}

class WorkshopDetailsView extends StatelessWidget {
  const WorkshopDetailsView({required this.workshop, super.key});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Image.asset('assets/logo.png', height: kToolbarHeight + 8),
        ),
        actions: [FavoriteButton(event: workshop)],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        children: [
          Text(
            workshop.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...workshop.speakers.map((speaker) => SpeakerInfo(speaker: speaker)),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    workshop.startTime.prettyPrint(context),
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${workshop.duration.inMinutes}m',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              LocationDetails(location: workshop.location),
            ],
          ),
          const SizedBox(height: 24),
          Text(workshop.description),
        ],
      ),
    );
  }
}

class SpeakerInfo extends StatelessWidget {
  const SpeakerInfo({required this.speaker, super.key});

  final Speaker speaker;

  @override
  Widget build(BuildContext context) {
    const avatarSize = 192.0;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              InkWell(
                onTap: () => Navigator.of(context).push(
                  SpeakerDetailsPage.route(speaker: speaker),
                ),
                child: Hero(
                  tag: speaker.name,
                  child: CircleAvatar(
                    radius: avatarSize / 2 + 4,
                    backgroundColor: theme.colorScheme.primary.withAlpha(100),
                    child: SpeakerPhoto(
                      speaker: speaker,
                      radius: avatarSize / 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            speaker.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            speaker.title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          SpeakerSocialLinks(speaker: speaker),
        ],
      ),
    );
  }
}

extension on DateTime {
  String prettyPrint(BuildContext context) {
    return '''${DateFormat.MMMd().format(this)}, ${TimeOfDay.fromDateTime(this).format(context)}''';
  }
}
