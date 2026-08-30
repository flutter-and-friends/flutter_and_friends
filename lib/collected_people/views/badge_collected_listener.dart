import 'package:flutter/material.dart';
import 'package:flutter_and_friends/collected_people/cubit/badge_listener_cubit.dart';
import 'package:flutter_and_friends/collected_people/views/collected_people_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reacts to badges collected by the app-wide [BadgeListenerCubit], wherever
/// the user is: announces the tap with a snackbar and opens Collected People
/// unless it is already the current page. Mount it inside the `MaterialApp`
/// builder so the snackbar reaches the app's `ScaffoldMessenger`, and hand
/// it the app's [navigatorKey] since the builder sits above the navigator.
class BadgeCollectedListener extends StatelessWidget {
  const BadgeCollectedListener({
    required this.navigatorKey,
    required this.child,
    super.key,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<BadgeListenerCubit, BadgeListenerState>(
      listenWhen: (previous, current) =>
          current.lastCollected != null &&
          previous.lastCollected != current.lastCollected,
      listener: (context, state) {
        final collected = state.lastCollected!;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                collected.isOwn
                    ? "That's your own badge"
                    : collected.isNew
                    ? 'Collected ${collected.person.name} ✓'
                    : 'Updated ${collected.person.name} ✓',
              ),
            ),
          );
        if (collected.isOwn) return;
        final navigator = navigatorKey.currentState;
        if (navigator == null || isOnCollectedPeoplePage(navigator)) return;
        navigator.push(CollectedPeoplePage.route());
      },
      child: child,
    );
  }

  /// Whether the navigator's top route is the Collected People page.
  @visibleForTesting
  static bool isOnCollectedPeoplePage(NavigatorState navigator) {
    Route<dynamic>? top;
    navigator.popUntil((route) {
      top = route;
      return true;
    });
    return top?.settings.name == CollectedPeoplePage.routeName;
  }
}
