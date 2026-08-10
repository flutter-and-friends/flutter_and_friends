import 'package:flutter/material.dart';
import 'package:flutter_and_friends/organizers/organizers.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OrganizerAvatar extends StatelessWidget {
  const OrganizerAvatar({required this.organizer, super.key});

  final Organizer organizer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: organizer.handle != null
                ? () => launchUrlString(
                    'https://twitter.com/${organizer.handle}',
                  )
                : null,
            child: Hero(
              tag: organizer.name,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: organizer.avatar != null
                    ? AssetImage(organizer.avatar!)
                    : null,
                child: organizer.avatar == null
                    ? const Icon(Icons.person, size: 48)
                    : null,
              ),
            ),
          ),
        ),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                organizer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (organizer.handle != null)
                Text(
                  '@${organizer.handle}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
