import 'package:flutter/material.dart';
import 'package:flutter_and_friends/collected_people/collected_people.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_and_friends/qa/qa.dart';
import 'package:flutter_and_friends/theme/theme.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          ListTile(
            leading: const Icon(Icons.question_answer),
            title: const Text('Q&A'),
            subtitle: const Text('Ask the panel a question'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(QaPage.route()),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Friends Badge'),
            subtitle: const Text('Customize your badge'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(FriendsBadgePage.route()),
          ),
          ListTile(
            leading: const Icon(Icons.contact_page),
            title: const Text('Collected People'),
            subtitle: const Text('People you met, tap a badge to collect'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.of(context).push(CollectedPeoplePage.route()),
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Activity Map'),
            subtitle: const Text('View the locations of all activities'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => launchUrlString(
              'https://www.google.com/maps/d/u/0/viewer?mid=102KWzlh5enCfJXbgTu8wN8FSfeOzsMw&femb=1&ll=59.32440113540593%2C18.059913600000016&z=13',
            ),
          ),
        ],
      ),
    );
  }
}
