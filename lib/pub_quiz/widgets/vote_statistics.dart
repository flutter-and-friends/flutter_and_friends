import 'package:flutter/material.dart';
import 'package:flutter_and_friends/pub_quiz/models/models.dart';
import 'package:flutter_and_friends/pub_quiz/widgets/quiz_option_button.dart';

/// How the teams voted on the question that was just revealed, played as a
/// short sequence: the bars grow in one option after another with the
/// counts ticking up, and once the last bar has landed the correct answer
/// lights up and [result] fades in. With [animate] false everything is
/// drawn in its final state.
///
/// Give it a key that changes per reveal (see `PubQuizState.revealKey`) so
/// the sequence starts over for each question and only for each question.
class VoteStatistics extends StatefulWidget {
  const VoteStatistics({
    required this.question,
    required this.result,
    this.myChoice,
    this.animate = true,
    super.key,
  });

  final PubQuizQuestion question;

  /// What this device picked, if it answered.
  final int? myChoice;

  /// Shown below the options once the correct answer is out.
  final Widget result;

  final bool animate;

  @override
  State<VoteStatistics> createState() => _VoteStatisticsState();
}

class _VoteStatisticsState extends State<VoteStatistics>
    with SingleTickerProviderStateMixin {
  /// Each bar starts this much later than the one above it.
  static const _stagger = 0.12;

  /// How long one bar takes to grow, as a share of the whole sequence.
  static const _barLength = 0.34;

  /// The last of four bars has landed here; the answer is shown from then on.
  static const _answerAt = 3 * _stagger + _barLength;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );
  late final Animation<double> _result = CurvedAnimation(
    parent: _controller,
    curve: const Interval(_answerAt, _answerAt + 0.2, curve: Curves.easeOut),
  );
  late final List<Animation<double>> _bars = [
    for (var i = 0; i < widget.question.options.length; i++)
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          (i * _stagger).clamp(0, 1 - _barLength),
          (i * _stagger + _barLength).clamp(0, 1),
          curve: Curves.easeOutCubic,
        ),
      ),
  ];
  bool _answerOut = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller
        ..addListener(_maybeShowAnswer)
        ..forward();
    } else {
      _controller.value = 1;
      _answerOut = true;
    }
  }

  void _maybeShowAnswer() {
    if (!_answerOut && _controller.value >= _answerAt) {
      setState(() => _answerOut = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final counts = question.answerCounts ?? const <int>[];
    final total = counts.fold<int>(0, (sum, count) => sum + count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < question.options.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: _bars[i],
                        builder: (context, _) {
                          final count = i < counts.length ? counts[i] : 0;
                          final share = total == 0 ? 0.0 : count / total;
                          final progress = _bars[i].value;
                          return QuizOptionButton(
                            index: i,
                            label: question.options[i],
                            style: _styleOf(i),
                            count: (count * progress).round(),
                            share: share * progress,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeTransition(opacity: _result, child: widget.result),
      ],
    );
  }

  QuizOptionStyle _styleOf(int index) {
    final myChoice = widget.myChoice;
    if (!_answerOut) {
      return index == myChoice
          ? QuizOptionStyle.selected
          : QuizOptionStyle.normal;
    }
    if (index == widget.question.correctIndex) return QuizOptionStyle.correct;
    if (index == myChoice) return QuizOptionStyle.wrong;
    return QuizOptionStyle.dimmed;
  }
}
