import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_and_friends/collected_people/collected_people.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart'
    show kCapybaraAssets;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:friends_badge/friends_badge.dart' show BadgePerson;
import 'package:nfc_manager/nfc_manager.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// The asset path for a collected person's capybara avatar, or `null` when
/// there is nothing to show (no capybaraId, or an id that doesn't match a
/// bundled capybara — defensive against hand-edited / future badges).
String? capybaraAssetFor(String? capybaraId) {
  if (capybaraId == null || capybaraId.isEmpty) return null;
  const folder = 'assets/badge_templates/capybaras';
  final path = '$folder/$capybaraId.jpeg';
  return kCapybaraAssets.contains(path) ? path : null;
}

class CollectedPeoplePage extends StatelessWidget {
  const CollectedPeoplePage({super.key});

  static Route<void> route() => MaterialPageRoute(
    builder: (_) => const CollectedPeoplePage(),
  );

  @override
  Widget build(BuildContext context) => const CollectedPeopleView();
}

class CollectedPeopleView extends StatelessWidget {
  const CollectedPeopleView({
    this.collector = const BadgeCollector(),
    super.key,
  });

  final BadgeCollector collector;

  @override
  Widget build(BuildContext context) {
    final people = context.select(
      (CollectedPeopleCubit cubit) => cubit.state.people,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Collected People')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'CollectBadgeButton',
        tooltip: 'Collect a badge',
        onPressed: () => _collect(context),
        child: const Icon(Icons.nfc),
      ),
      body: people.isEmpty
          ? const EmptyCollectedPeople()
          : CollectedPeopleListView(people: people),
    );
  }

  /// Foreground dispatch: while the session is held, tapping a badge
  /// collects the person in place (the app wins over the browser).
  ///
  /// The session only ends on a tap, a cancel, or a platform error, so a
  /// [CollectBadgeDialog] is shown for as long as it runs. It doubles as the
  /// prompt on Android, which has no system NFC sheet, and as the only way
  /// to stop reader mode there.
  Future<void> _collect(BuildContext context) async {
    final cubit = context.read<CollectedPeopleCubit>();
    final messenger = ScaffoldMessenger.of(context);

    void onCollected(BadgePerson badgePerson, String? badgeId) {
      final existing = cubit.state.people.length;
      final person = cubit.collect(
        toCollectedPerson(badgePerson, badgeId: badgeId),
      );
      final isNew = cubit.state.people.length > existing;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              isNew ? 'Collected ${person.name} ✓' : 'Updated ${person.name} ✓',
            ),
          ),
        );
    }

    final BadgeCollectSession session;
    try {
      session = await _startSession(onCollected);
    } on PlatformException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not collect badge: $e')),
      );
      return;
      // NFC unavailable surfaces as a StateError from BadgeCollector.
      // ignore: avoid_catching_errors
    } on StateError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    if (!context.mounted) {
      await session.cancel();
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => CollectBadgeDialog(session: session),
    );
    await session.cancel();

    switch (await session.result) {
      case BadgeCollectResult.collected:
      case BadgeCollectResult.cancelled:
        break;
      case BadgeCollectResult.notABadge:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('That was not a Friends badge, try again'),
          ),
        );
    }
  }

  /// Starts the collect session, retrying once after stopping a leftover
  /// session. iOS does not always clean up the previous session (for
  /// example from the badge write flow), mirroring WriteToBadgeButton.
  Future<BadgeCollectSession> _startSession(
    void Function(BadgePerson person, String? badgeId) onCollected,
  ) async {
    try {
      return await collector.start(onCollected: onCollected);
    } on PlatformException catch (e) {
      if (e.code != 'session_already_exists') rethrow;
      await NfcManager.instance.stopSession();
      return collector.start(onCollected: onCollected);
    }
  }
}

/// Shown while a [BadgeCollectSession] is listening for a tap. Pops itself
/// once the session ends, or ends the session when dismissed.
class CollectBadgeDialog extends StatefulWidget {
  const CollectBadgeDialog({required this.session, super.key});

  final BadgeCollectSession session;

  @override
  State<CollectBadgeDialog> createState() => _CollectBadgeDialogState();
}

class _CollectBadgeDialogState extends State<CollectBadgeDialog> {
  @override
  void initState() {
    super.initState();
    unawaited(
      widget.session.result.then((_) {
        if (mounted) Navigator.of(context).pop();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.nfc, size: 48),
      title: const Text('Ready to collect'),
      content: const Text(
        "Hold your phone near someone's badge to collect them",
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class EmptyCollectedPeople extends StatelessWidget {
  const EmptyCollectedPeople({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.contact_page,
              color: Colors.redAccent,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'No one collected yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Tap the NFC button and hold your phone near someone's "
              'badge to collect them',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class CollectedPeopleListView extends StatelessWidget {
  const CollectedPeopleListView({required this.people, super.key});

  final List<CollectedPerson> people;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: people.length,
      itemBuilder: (context, index) {
        final person = people[index];
        final capybaraAsset = capybaraAssetFor(person.capybaraId);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: capybaraAsset == null
                ? null
                : AssetImage(capybaraAsset),
            child: capybaraAsset == null
                ? Text(
                    person.name.isEmpty ? '?' : person.name[0].toUpperCase(),
                  )
                : null,
          ),
          title: Text(person.name.isEmpty ? 'Unknown' : person.name),
          subtitle: person.role.isEmpty ? null : Text(person.role),
          trailing: const Icon(Icons.chevron_right),
          onTap: person.urls.isEmpty
              ? null
              : () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => CollectedPersonLinksSheet(person: person),
                ),
          onLongPress: () => _confirmRemove(context, person),
        );
      },
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    CollectedPerson person,
  ) async {
    final cubit = context.read<CollectedPeopleCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${person.name}?'),
        content: const Text('This removes them from your dex.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove ?? false) {
      cubit.remove(person);
      messenger.showSnackBar(SnackBar(content: Text('Removed ${person.name}')));
    }
  }
}

/// Bottom sheet listing a collected person's links; tapping one opens it.
class CollectedPersonLinksSheet extends StatelessWidget {
  const CollectedPersonLinksSheet({required this.person, super.key});

  final CollectedPerson person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              person.name.isEmpty ? 'Unknown' : person.name,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (person.role.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                person.role,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            for (final url in person.urls)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link),
                title: Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => launchUrlString(
                  url,
                  mode: LaunchMode.externalApplication,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
