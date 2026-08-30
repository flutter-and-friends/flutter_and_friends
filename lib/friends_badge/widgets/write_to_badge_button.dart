import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_and_friends/collected_people/collected_people.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:friends_badge/friends_badge.dart';
import 'package:nfc_manager/nfc_manager.dart';

class WriteToBadgeButton extends StatelessWidget {
  const WriteToBadgeButton(
    this.badge, {
    this.ndef,
    this.onWritten,
    this.rearmsListener = true,
    super.key,
  });

  final FriendsBadge badge;

  /// The NDEF message written after the image, or `null` for an image-only
  /// write.
  final NdefMessage? ndef;

  /// Called once the badge has been written successfully.
  final VoidCallback? onWritten;

  /// Whether to restart the app-wide badge listener after the write. The
  /// speed writer keeps the listener stopped for its whole session, so it
  /// passes `false`.
  final bool rearmsListener;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'WriteToBadgeButton',
      tooltip: 'Write to badge',
      onPressed: () async {
        try {
          await _writeToBadge(context: context, badge: badge, ndef: ndef);
          onWritten?.call();
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
        } finally {
          // The write session replaced the app-wide badge listener's NFC
          // session; bring it back so the badge still on the phone is
          // handled by the app rather than the system.
          if (rearmsListener && context.mounted) {
            unawaited(context.read<BadgeListenerCubit?>()?.rearm());
          }
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
