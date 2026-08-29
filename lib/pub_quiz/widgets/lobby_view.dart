import 'package:flutter/material.dart';
import 'package:flutter_and_friends/pub_quiz/cubit/pub_quiz_cubit.dart';
import 'package:flutter_and_friends/pub_quiz/widgets/team_name_field.dart';
import 'package:flutter_and_friends/pub_quiz/widgets/waiting_hourglass.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Waiting for the host to start: the team's own name (still editable) and
/// who else is in.
class LobbyView extends StatelessWidget {
  const LobbyView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<PubQuizCubit>().state;
    final myTeam = state.myTeam;
    final others = [
      for (final team in state.teams)
        if (!team.isMine) team.name,
    ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.groups),
            title: Text(
              myTeam?.name ?? '',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: const Text('Your team'),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Rename team',
              onPressed: () => RenameTeamDialog.show(context),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const WaitingHourglass(),
        const SizedBox(height: 12),
        Text(
          'Waiting for the host to start',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'The first question shows up here as soon as the quiz begins.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Text(
          '${state.teams.length} ${state.teams.length == 1 ? 'team' : 'teams'}'
          ' in the game',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (myTeam != null)
              Chip(
                label: Text(myTeam.name),
                backgroundColor: theme.colorScheme.primaryContainer,
                side: BorderSide.none,
              ),
            for (final name in others) Chip(label: Text(name)),
          ],
        ),
      ],
    );
  }
}

class RenameTeamDialog extends StatelessWidget {
  const RenameTeamDialog({required this.initialName, super.key});

  final String initialName;

  static Future<void> show(BuildContext context) {
    final cubit = context.read<PubQuizCubit>();
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: RenameTeamDialog(initialName: cubit.state.myTeam?.name ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename team'),
      content: TeamNameField(
        initialName: initialName,
        buttonLabel: 'Save',
        onSubmit: (name) {
          context.read<PubQuizCubit>().renameTeam(name);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
