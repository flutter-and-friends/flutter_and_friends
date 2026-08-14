import 'package:flutter/material.dart';
import 'package:flutter_and_friends/sponsors/sponsors.dart';
import 'package:flutter_and_friends/theme/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SponsorsPage extends StatelessWidget {
  const SponsorsPage({super.key});

  @override
  Widget build(BuildContext context) => const SponsorsView();
}

class SponsorsView extends StatelessWidget {
  const SponsorsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: FFAppBar(), body: const SponsorsListView());
  }
}

/// Data-driven by design: tiers and their display names come entirely from
/// the bundled feed (see [SponsorsCubit]) rather than being hardcoded per
/// category here, so a tier added or renamed on the website side shows up
/// without an app code change - only a re-run of `tool/sync_sponsors.dart`.
class SponsorsListView extends StatelessWidget {
  const SponsorsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SponsorsCubit, SponsorsState>(
      builder: (context, state) {
        if (state.status == SponsorsStatus.loading ||
            state.status == SponsorsStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == SponsorsStatus.error && state.tiers.isEmpty) {
          return Center(
            child: Text(state.errorMessage ?? 'Could not load sponsors'),
          );
        }
        final theme = Theme.of(context);
        final headingStyle = theme.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w300,
        );
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final tier in state.tiers) ...[
              Text(
                tier.displayName,
                style: headingStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...tier.sponsors.map((sponsor) => SponsorItem(sponsor: sponsor)),
              const SizedBox(height: 32),
            ],
          ],
        );
      },
    );
  }
}

class SponsorItem extends StatelessWidget {
  const SponsorItem({required this.sponsor, super.key});

  final Sponsor sponsor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        color: lightTheme.colorScheme.surface,
        elevation: 0,
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () => launchUrlString(sponsor.url),
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: SponsorLogo(sponsor: sponsor),
            ),
          ),
        ),
      ),
    );
  }
}

/// Picks the right image widget for a bundled sponsor logo. The synced set
/// mixes SVG (the majority), PNG, and WEBP - PNG/WEBP are natively handled
/// by [Image.asset], SVG needs `flutter_svg`.
class SponsorLogo extends StatelessWidget {
  const SponsorLogo({required this.sponsor, super.key});

  final Sponsor sponsor;

  @override
  Widget build(BuildContext context) {
    if (sponsor.isSvg) {
      return SvgPicture.asset(sponsor.logo);
    }
    return Image.asset(sponsor.logo);
  }
}
