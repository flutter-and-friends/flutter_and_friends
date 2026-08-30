import 'package:flutter/material.dart';
import 'package:flutter_and_friends/highscore/models/models.dart';

/// A name input with its save button, shown on the highscore while the
/// badge has no name yet. Only hands a trimmed, non-empty name to
/// [onSubmit].
class HighscoreNameField extends StatefulWidget {
  const HighscoreNameField({required this.onSubmit, super.key});

  final ValueChanged<String> onSubmit;

  @override
  State<HighscoreNameField> createState() => _HighscoreNameFieldState();
}

class _HighscoreNameFieldState extends State<HighscoreNameField> {
  final _controller = TextEditingController();

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            maxLength: maxHighscoreNameLength,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Your name',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, value, _) => FilledButton(
              onPressed: value.text.trim().isEmpty ? null : _submit,
              child: const Text('Save'),
            ),
          ),
        ),
      ],
    );
  }
}
