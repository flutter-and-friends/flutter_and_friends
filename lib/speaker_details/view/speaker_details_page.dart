import 'package:flutter/material.dart';
import 'package:flutter_and_friends/speakers/speakers.dart';

class SpeakerDetailsPage extends StatelessWidget {
  const SpeakerDetailsPage({required this.speaker, super.key});

  static Route<void> route({required Speaker speaker}) {
    return MaterialPageRoute(
      builder: (_) => SpeakerDetailsPage(speaker: speaker),
    );
  }

  final Speaker speaker;

  @override
  Widget build(BuildContext context) => SpeakerDetailsView(speaker: speaker);
}

class SpeakerDetailsView extends StatelessWidget {
  const SpeakerDetailsView({required this.speaker, super.key});

  final Speaker speaker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Image.asset('assets/logo.png', height: kToolbarHeight + 8),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        children: [
          SpeakerInfo(speaker: speaker),
          const SizedBox(height: 32),
          Text(speaker.bio),
        ],
      ),
    );
  }
}

class SpeakerInfo extends StatelessWidget {
  const SpeakerInfo({required this.speaker, super.key});

  final Speaker speaker;

  @override
  Widget build(BuildContext context) {
    const avatarSize = 192.0;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Hero(
                tag: speaker.name,
                child: CircleAvatar(
                  radius: avatarSize / 2 + 4,
                  backgroundColor: theme.colorScheme.primary.withAlpha(100),
                  child: SpeakerPhoto(speaker: speaker, radius: avatarSize / 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            speaker.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            speaker.title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          SpeakerSocialLinks(speaker: speaker),
        ],
      ),
    );
  }
}
