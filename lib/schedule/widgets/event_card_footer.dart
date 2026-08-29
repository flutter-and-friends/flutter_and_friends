import 'package:flutter/material.dart';
import 'package:flutter_and_friends/location/location.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';

class EventCardFooter extends StatelessWidget {
  const EventCardFooter({
    required this.location,
    required this.label,
    super.key,
  });

  final Location? location;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: LocationDetails(location: location)),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
