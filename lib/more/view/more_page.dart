import 'package:flutter/material.dart';
import 'package:flutter_and_friends/collected_people/collected_people.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_and_friends/pub_quiz/pub_quiz.dart';
import 'package:flutter_and_friends/qa/qa.dart';
import 'package:flutter_and_friends/theme/theme.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) => const MoreView();
}

class MoreView extends StatelessWidget {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FFAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          MoreItem(
            icon: Icons.question_answer,
            title: 'Q&A',
            subtitle: 'Ask the panel a question',
            onTap: () => Navigator.of(context).push(QaPage.route()),
          ),
          MoreItem(
            icon: Icons.quiz,
            title: 'Pub Quiz',
            subtitle: 'Play the Flutter & Fun Pub Quiz',
            onTap: () => Navigator.of(context).push(PubQuizPage.route()),
          ),
          MoreItem(
            icon: Icons.badge_outlined,
            title: 'Friends Badge',
            subtitle: 'Customize your badge',
            onTap: () => Navigator.of(context).push(FriendsBadgePage.route()),
          ),
          MoreItem(
            icon: Icons.contact_page,
            title: 'Collected People',
            subtitle: 'People you met, tap a badge to collect',
            onTap: () =>
                Navigator.of(context).push(CollectedPeoplePage.route()),
          ),
        ],
      ),
    );
  }
}

/// One entry on the More page: a card with an icon, a title, a short
/// description and a chevron, styled like the schedule cards.
class MoreItem extends StatelessWidget {
  const MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
