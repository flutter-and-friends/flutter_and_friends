import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  String prettyPrint(BuildContext context, Duration duration) {
    final date = DateFormat.MMMMd().format(this);
    return '$date, ${prettyPrintTime(context, duration)}';
  }

  String prettyPrintTime(BuildContext context, Duration duration) {
    final start = TimeOfDay.fromDateTime(this).format(context);
    final end = TimeOfDay.fromDateTime(add(duration)).format(context);
    return '$start - $end';
  }
}
