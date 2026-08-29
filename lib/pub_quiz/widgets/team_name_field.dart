import 'package:flutter/material.dart';

/// Must match the limit in `firestore.rules`.
const maxTeamNameLength = 30;

/// A team name input with its submit button, shared by the join screen and
/// the rename dialog. Only hands a trimmed, non-empty name to [onSubmit].
class TeamNameField extends StatefulWidget {
  const TeamNameField({
    required this.onSubmit,
    required this.buttonLabel,
    this.initialName = '',
    super.key,
  });

  final ValueChanged<String> onSubmit;
  final String buttonLabel;
  final String initialName;

  @override
  State<TeamNameField> createState() => _TeamNameFieldState();
}

class _TeamNameFieldState extends State<TeamNameField> {
  late final _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    widget.onSubmit(name);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          maxLength: maxTeamNameLength,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Team name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty ? null : _submit,
            child: Text(widget.buttonLabel),
          ),
        ),
      ],
    );
  }
}
