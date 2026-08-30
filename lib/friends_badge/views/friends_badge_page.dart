import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:friends_badge/friends_badge.dart';

class FriendsBadgePage extends StatelessWidget {
  const FriendsBadgePage({super.key});

  static Route<void> route() => MaterialPageRoute(
    builder: (_) => const FriendsBadgePage(),
  );

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => BadgeIdentityCubit()),
      BlocProvider(
        create: (context) => FriendsBadgeCubit(
          identity: context.read<BadgeIdentityCubit>(),
        ),
      ),
    ],
    child: const FriendsBadgeView(),
  );
}

class FriendsBadgeView extends StatelessWidget {
  const FriendsBadgeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<FriendsBadgeCubit>().state;
    final badge = state.badge;
    final body = badge == null
        ? const _BadgeSourcePicker()
        : _BadgeEditor(badge: badge, state: state);

    return BlocListener<FriendsBadgeCubit, FriendsBadgeState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == FriendsBadgeStatus.failed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to decode image. Please try again.'),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Friends Badge'),
          bottom: badge == null ? null : const TemplateTabBar(),
        ),
        floatingActionButton: Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (badge != null) WriteToBadgeButton(badge),
            if (state.status == FriendsBadgeStatus.loading)
              const FloatingActionButton(
                heroTag: 'ImageLoading',
                tooltip: 'Image loading',
                onPressed: null,
                child: CircularProgressIndicator(),
              )
            else
              const PickImageButton(),
          ],
        ),
        body: badge == null
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    Text(
                      'Pick a capybara, or use the gallery button below',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    Expanded(child: body),
                  ],
                ),
              )
            : body,
      ),
    );
  }
}

/// Grid of bundled capybara templates shown when no image has been picked.
class _BadgeSourcePicker extends StatelessWidget {
  const _BadgeSourcePicker();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: kCapybaraAssets.length,
      itemBuilder: (context, index) {
        final asset = kCapybaraAssets[index];
        return InkWell(
          onTap: () =>
              context.read<FriendsBadgeCubit>().updateImageFromAsset(asset),
          child: Image.asset(asset, fit: BoxFit.cover),
        );
      },
    );
  }
}

class _BadgeEditor extends StatelessWidget {
  const _BadgeEditor({required this.badge, required this.state});

  final FriendsBadge badge;
  final FriendsBadgeState state;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.all(16);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight - padding.vertical;
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                if (state.template.usesText) ...[
                  _NameRoleFields(state: state),
                  const _FontPicker(),
                ],
                SizedBox(
                  height: height * 1 / 6,
                  child: Center(
                    child: _BadgeDitherKernelCarousel(badge: badge),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: height * 4 / 6),
                  child: Center(child: _BadgePreview(badge: badge)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Template picker as app bar tabs, one per [BadgeTemplate] in declaration
/// order. Keeps its tab controller in sync with the cubit's template so the
/// persisted choice is selected when the editor opens.
class TemplateTabBar extends StatefulWidget implements PreferredSizeWidget {
  const TemplateTabBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  State<TemplateTabBar> createState() => _TemplateTabBarState();
}

class _TemplateTabBarState extends State<TemplateTabBar>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: BadgeTemplate.values.length,
      initialIndex: context.read<FriendsBadgeCubit>().state.template.index,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = context.select(
      (FriendsBadgeCubit c) => c.state.template,
    );
    if (_controller.index != selected.index) {
      _controller.animateTo(selected.index);
    }
    return TabBar(
      controller: _controller,
      onTap: (index) => context.read<FriendsBadgeCubit>().updateTemplate(
        BadgeTemplate.values[index],
      ),
      tabs: [
        for (final template in BadgeTemplate.values) Tab(text: template.label),
      ],
    );
  }
}

class _FontPicker extends StatelessWidget {
  const _FontPicker();

  @override
  Widget build(BuildContext context) {
    final selected = context.select(
      (FriendsBadgeCubit c) => c.state.font,
    );
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final font in BadgeFont.values)
          ChoiceChip(
            label: Text(font.label),
            selected: font == selected,
            onSelected: (_) =>
                context.read<FriendsBadgeCubit>().updateFont(font),
          ),
      ],
    );
  }
}

class _NameRoleFields extends StatefulWidget {
  const _NameRoleFields({required this.state});

  final FriendsBadgeState state;

  @override
  State<_NameRoleFields> createState() => _NameRoleFieldsState();
}

class _NameRoleFieldsState extends State<_NameRoleFields> {
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.name);
    _roleController = TextEditingController(text: widget.state.role);
    _urlController = TextEditingController(text: widget.state.url);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FriendsBadgeCubit>();
    return Column(
      spacing: 12,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Your Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: cubit.updateName,
        ),
        TextField(
          controller: _roleController,
          decoration: const InputDecoration(
            labelText: 'Role',
            hintText: 'Flutter Friend',
            border: OutlineInputBorder(),
          ),
          onChanged: cubit.updateRole,
        ),
        TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: 'Link (optional)',
            hintText:
                'x.com/FlutterNFriends or linkedin.com/company/flutter-friends',
            helperText: 'Written to the badge as an NFC link.',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
          onChanged: cubit.updateUrl,
        ),
      ],
    );
  }
}

class _BadgePreview extends StatelessWidget {
  const _BadgePreview({required this.badge});

  final FriendsBadge badge;

  @override
  Widget build(BuildContext context) {
    return Image.memory(badge.previewPng, gaplessPlayback: true);
  }
}

class _BadgeDitherKernelCarousel extends StatelessWidget {
  const _BadgeDitherKernelCarousel({required this.badge});

  final FriendsBadge badge;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemCount: BadgeImage.allSupportedKernels.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final kernel = [...BadgeImage.allSupportedKernels.reversed][index];
        final primary = Theme.of(context).colorScheme.primary;
        final decoration = kernel == badge.ditherKernel
            ? BoxDecoration(
                color: primary.withValues(alpha: 0.4),
                border: Border.all(width: 3, color: primary),
              )
            : const BoxDecoration();
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: decoration,
          child: InkWell(
            onTap: () => unawaited(
              context.read<FriendsBadgeCubit>().updateDitherKernel(kernel),
            ),
            child: Image.memory(
              badge.peekPngs[kernel] ?? badge.previewPng,
              gaplessPlayback: true,
            ),
          ),
        );
      },
    );
  }
}
