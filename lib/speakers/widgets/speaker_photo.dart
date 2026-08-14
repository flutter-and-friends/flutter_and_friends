import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_and_friends/speakers/speakers.dart';

/// Renders a speaker's photo as a circular avatar, loaded over the network
/// and cached locally (so it survives going offline after first view).
///
/// `photoUrl` is nullable and load can fail independently of that (a stale
/// URL, no connectivity) - both cases fall back to the same initials
/// avatar, so this never renders a broken-image icon.
class SpeakerPhoto extends StatelessWidget {
  const SpeakerPhoto({required this.speaker, required this.radius, super.key});

  final Speaker speaker;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = speaker.photoUrl;
    if (url == null || url.isEmpty) {
      return _InitialsAvatar(speaker: speaker, radius: radius);
    }
    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        child: SizedBox(
          width: radius,
          height: radius,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) =>
          _InitialsAvatar(speaker: speaker, radius: radius),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.speaker, required this.radius});

  final Speaker speaker;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        _initialsFor(speaker.name),
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.6,
        ),
      ),
    );
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return initials.isEmpty ? '?' : initials;
  }
}
