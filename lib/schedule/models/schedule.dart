import 'package:equatable/equatable.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';

class Schedule extends Equatable {
  const Schedule({required this.events});

  static const empty = Schedule(events: []);

  final List<Event> events;

  /// Events grouped by local calendar day, ordered chronologically both
  /// across days and within each day. Replaces the old hard-coded
  /// day1/day2/day3 lists - a remote schedule can have any number of days.
  List<ScheduleDay> get days {
    final byDate = <DateTime, List<Event>>{};
    for (final event in events) {
      final date = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      byDate.putIfAbsent(date, () => []).add(event);
    }
    final sortedDates = byDate.keys.toList()..sort();
    return [
      for (final date in sortedDates)
        ScheduleDay(
          date: date,
          events: byDate[date]!
            ..sort(
              (a, b) => a.startTime.compareTo(b.startTime),
            ),
        ),
    ];
  }

  @override
  List<Object> get props => [events];
}

class ScheduleDay extends Equatable {
  const ScheduleDay({required this.date, required this.events});

  final DateTime date;
  final List<Event> events;

  @override
  List<Object> get props => [date, events];
}
