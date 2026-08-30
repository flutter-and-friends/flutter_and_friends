import 'package:flutter/material.dart';
import 'package:flutter_and_friends/pub_quiz/cubit/pub_quiz_cubit.dart';

/// A strip across the top of the quiz while it is not being served live:
/// a running progress bar and a line saying whether the app is still
/// connecting or has lost the connection. Nothing while connected.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({required this.connection, super.key});

  final PubQuizConnection connection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (
      String message,
      Color background,
      Color foreground,
    ) = switch (connection) {
      PubQuizConnection.connected => (
        '',
        Colors.transparent,
        Colors.transparent,
      ),
      PubQuizConnection.connecting => (
        'Connecting to the quiz…',
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
      ),
      PubQuizConnection.reconnecting => (
        'Connection lost. Reconnecting…',
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
      ),
    };
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: connection == PubQuizConnection.connected
          ? const SizedBox(width: double.infinity)
          : Material(
              color: background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    minHeight: 3,
                    color: foreground,
                    backgroundColor: background,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          connection == PubQuizConnection.reconnecting
                              ? Icons.wifi_off
                              : Icons.wifi,
                          size: 16,
                          color: foreground,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
