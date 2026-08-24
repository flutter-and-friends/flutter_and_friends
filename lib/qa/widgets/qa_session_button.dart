import 'package:flutter/material.dart';
import 'package:flutter_and_friends/qa/qa.dart';

/// Entry point to the Q&A from the session's own details page.
class QaSessionButton extends StatelessWidget {
  const QaSessionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => Navigator.of(context).push(QaPage.route()),
      icon: const Icon(Icons.question_answer_outlined),
      label: const Text('Ask the panel a question'),
    );
  }
}
