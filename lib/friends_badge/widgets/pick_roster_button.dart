import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lets the organizer pick the speed writer's CSV from the phone's files.
///
/// Picks any file type on purpose: Android's document picker filters by
/// MIME type and CSV files are tagged inconsistently (`text/csv` versus
/// `text/comma-separated-values`), which would grey out valid files. A
/// wrong pick surfaces as a parse error instead.
class PickRosterButton extends StatelessWidget {
  const PickRosterButton({this.compact = false, super.key});

  /// Renders as an app bar icon instead of a filled button.
  final bool compact;

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<SpeedWriterCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.firstOrNull;
    if (file == null) return;
    var bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not read ${file.name}')),
      );
      return;
    }
    await cubit.loadRoster(utf8.decode(bytes, allowMalformed: true));
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: 'Pick another CSV',
        icon: const Icon(Icons.upload_file),
        onPressed: () => _pick(context),
      );
    }
    return FilledButton.icon(
      icon: const Icon(Icons.upload_file),
      label: const Text('Pick CSV'),
      onPressed: () => _pick(context),
    );
  }
}
