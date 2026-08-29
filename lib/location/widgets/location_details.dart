import 'package:flutter/material.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LocationDetails extends StatelessWidget {
  const LocationDetails({required this.location, super.key});

  /// Null when the session has no known venue location - e.g. an activity
  /// where the feed sends `location: null` and no `stage`/`track`. Renders
  /// nothing rather than a fabricated placeholder.
  final Location? location;

  @override
  Widget build(BuildContext context) {
    final location = this.location;
    if (location == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final coordinates = location.coordinates;
    final label = Text(
      location.name,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.secondary,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 18,
          color: theme.colorScheme.secondary,
        ),
        Flexible(
          child: coordinates != null
              ? InkWell(
                  onTap: () => launchUrlString(
                    'https://maps.google.com/?q=${coordinates.$1},${coordinates.$2}',
                  ),
                  child: label,
                )
              : label,
        ),
      ],
    );
  }
}
