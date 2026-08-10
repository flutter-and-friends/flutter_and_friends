import 'package:flutter/material.dart';
import 'package:flutter_and_friends/speakers/speakers.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Row of icon buttons for whichever of a speaker's social links are
/// present. Replaces the old Twitter-only button now that the feed's
/// `social` object carries github/bluesky/linkedin/website instead - a
/// speaker may have any subset of these (or none).
class SpeakerSocialLinks extends StatelessWidget {
  const SpeakerSocialLinks({required this.speaker, super.key});

  final Speaker speaker;

  @override
  Widget build(BuildContext context) {
    final links = <Widget>[
      if (speaker.github != null)
        _SocialIconButton(
          icon: FontAwesomeIcons.github,
          url: speaker.github!,
        ),
      if (speaker.bluesky != null)
        _SocialIconButton(
          icon: FontAwesomeIcons.bluesky,
          url: speaker.bluesky!,
        ),
      if (speaker.linkedin != null)
        _SocialIconButton(
          icon: FontAwesomeIcons.linkedin,
          url: speaker.linkedin!,
        ),
      if (speaker.website != null)
        _SocialIconButton(
          icon: FontAwesomeIcons.globe,
          url: speaker.website!,
        ),
    ];
    if (links.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: links);
  }
}

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({required this.icon, required this.url});

  final FaIconData icon;
  final String url;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: FaIcon(icon, size: 20),
      onPressed: () => launchUrlString(url),
    );
  }
}
