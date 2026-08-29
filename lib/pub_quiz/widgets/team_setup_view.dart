import 'package:flutter/material.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_and_friends/pub_quiz/cubit/pub_quiz_cubit.dart';
import 'package:flutter_and_friends/pub_quiz/widgets/team_name_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The first screen: pick a team name and join. One phone plays for the
/// whole team, so this is also the only thing a player has to set up.
class TeamSetupView extends StatefulWidget {
  const TeamSetupView({super.key});

  @override
  State<TeamSetupView> createState() => _TeamSetupViewState();
}

class _TeamSetupViewState extends State<TeamSetupView> {
  // The badge creator remembers the attendee's name; suggesting it saves a
  // few taps for the common "team of one" and is easy to overwrite.
  late final String _suggestedName;

  @override
  void initState() {
    super.initState();
    final identity = BadgeIdentityCubit();
    _suggestedName = identity.state.name.trim();
    identity.close();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.quiz, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Join the pub quiz',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'One phone answers for the whole team. Give your team a name and '
          'gather around it.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TeamNameField(
          initialName: _suggestedName,
          buttonLabel: 'Join',
          onSubmit: context.read<PubQuizCubit>().createTeam,
        ),
      ],
    );
  }
}
