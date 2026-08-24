import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:friends_badge/friends_badge.dart';
import 'package:nfc_manager/nfc_manager.dart';

class WriteToBadgeButton extends StatelessWidget {
  const WriteToBadgeButton(this.badge, {super.key});

  final FriendsBadge badge;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'WriteToBadgeButton',
      tooltip: 'Write to badge',
      onPressed: () async {
        final state = context.read<FriendsBadgeCubit>().state;
        final ndef = buildBadgeNdefMessage(
          name: state.name,
          role: state.role,
          url: state.url,
        );
        try {
          await _writeToBadge(context: context, badge: badge, ndef: ndef);
        } on PlatformException catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '''
Error writing to badge, please restart the app and try again.
Error: $e''',
              ),
            ),
          );
        }
      },
      child: const Icon(Icons.nfc),
    );
  }
}

Future<void> _writeToBadge({
  required BuildContext context,
  required FriendsBadge badge,
  NdefMessage? ndef,
}) async {
  try {
    await WaitingForNfcTap.showLoading(
      context: context,
      job: badge.image.writeToBadge(kernel: badge.ditherKernel, ndef: ndef),
    );
  } on PlatformException catch (e) {
    // On iOS for some reason previous nfc sessions aren't automatically
    // cancelled. If we encounter this error, we explicitly try to manually
    // stop any existing sessions and automatically retry.
    if (e.code == 'session_already_exists') {
      await NfcManager.instance.stopSession();
      if (!context.mounted) return;
      await WaitingForNfcTap.showLoading(
        context: context,
        job: badge.image.writeToBadge(kernel: badge.ditherKernel, ndef: ndef),
      );
      return;
    }
    rethrow;
  }
}
