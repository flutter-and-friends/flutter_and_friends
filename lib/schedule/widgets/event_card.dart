import 'package:flutter/material.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';

class EventCard extends StatelessWidget {
  const EventCard({required this.event, this.showDate = true, super.key});

  final Event event;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final event = this.event;
    if (event is Talk) return TalkCard(talk: event, showDate: showDate);
    if (event is Activity) {
      return ActivityCard(activity: event, showDate: showDate);
    }
    if (event is Workshop) {
      return WorkshopCard(workshop: event, showDate: showDate);
    }
    return const SizedBox();
  }
}
