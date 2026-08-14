import 'package:flutter/material.dart';
import 'package:flutter_and_friends/speaker_details/speaker_details.dart';
import 'package:flutter_and_friends/speakers/speakers.dart';

class SpeakerAvatar extends StatelessWidget {
  const SpeakerAvatar({required this.speaker, super.key});

  final Speaker speaker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      spacing: 16,
      children: [
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              SpeakerDetailsPage.route(speaker: speaker),
            ),
            child: Hero(
              tag: speaker.name,
              child: SpeakerPhoto(speaker: speaker, radius: 60),
            ),
          ),
        ),
        Flexible(
          child: Column(
            children: [
              Text(
                speaker.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                speaker.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
