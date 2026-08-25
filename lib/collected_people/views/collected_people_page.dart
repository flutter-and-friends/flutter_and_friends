import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_and_friends/collected_people/collected_people.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart'
    show kCapybaraAssets;
import 'package:flutter_bloc/flutter_bloc.dart';
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
  const CollectedPeopleView({super.key});

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

  /// Foreground dispatch: while the returned session is held, tapping a
  /// badge collects the person in place (the app wins over the browser).
  ///
  /// ⚠️ This NFC wiring cannot be exercised in CI — confirm on device.
  Future<void> _collect(BuildContext context) async {
    final cubit = context.read<CollectedPeopleCubit>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final collected = await const BadgeCollector().collectTaps(
        onCollected: (badgePerson) {
          final existing = cubit.state.people.length;
          final person = cubit.collect(
            toCollectedPerson(badgePerson),
          );
          final isNew = cubit.state.people.length > existing;
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  isNew
                      ? 'Collected ${person.name} ✓'
                      : '${person.name} is already in your dex',
                ),
              ),
            );
        },
      );
      if (!collected) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No badge tapped')),
        );
      }
    } on PlatformException catch (e) {
      // iOS can report a leftover session from a previous (e.g. badge-write)
      // flow — stop it and let the user retry, mirroring WriteToBadgeButton.
      if (e.code == 'session_already_exists') {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('NFC session busy — please try again'),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not collect badge: $e')),
        );
      }
      // NFC unavailable surfaces as a StateError from BadgeCollector.
      // ignore: avoid_catching_errors
    } on StateError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
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
