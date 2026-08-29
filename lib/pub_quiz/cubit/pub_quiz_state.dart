part of 'pub_quiz_cubit.dart';

enum PubQuizStatus { initial, loading, loaded, error }

/// Progress of the answer this device is submitting for the current
/// question. [tooLate] means the server refused it because the question
/// had already closed.
enum PubQuizSubmission { idle, submitting, submitted, tooLate, failure }

/// Which screen to show, derived from the phase and whether this device has
/// a team yet.
enum PubQuizScreen {
  notReady,
  setup,
  lobby,
  question,
  reveal,
  scoreboard,
  finished,
}

class PubQuizState extends Equatable {
  const PubQuizState({
    this.status = PubQuizStatus.initial,
    this.quiz,
    this.teams = const [],
    this.myAnswer,
    this.submission = PubQuizSubmission.idle,
    this.errorMessage,
  });

  final PubQuizStatus status;

  /// Null until the first snapshot arrives, and when the organizers have not
  /// created the quiz yet.
  final PubQuiz? quiz;

  /// Every team in the quiz, sorted by score.
  final List<PubQuizTeam> teams;

  /// This device's answer to the current question, if any.
  final PubQuizAnswer? myAnswer;
  final PubQuizSubmission submission;

  /// The most recent failure, if any.
  final String? errorMessage;

  PubQuizTeam? get myTeam {
    for (final team in teams) {
      if (team.isMine) return team;
    }
    return null;
  }

  PubQuizScreen get screen {
    final quiz = this.quiz;
    if (quiz == null) return PubQuizScreen.notReady;
    if (myTeam == null) return PubQuizScreen.setup;
    return switch (quiz.phase) {
      PubQuizPhase.lobby => PubQuizScreen.lobby,
      PubQuizPhase.answering || PubQuizPhase.closed => PubQuizScreen.question,
      PubQuizPhase.revealed => PubQuizScreen.reveal,
      PubQuizPhase.scoreboard => PubQuizScreen.scoreboard,
      PubQuizPhase.finished => PubQuizScreen.finished,
    };
  }

  /// Identifies the reveal being shown, so the scoreboard animation runs
  /// once per revealed question. Null while no answer is out.
  String? get revealKey {
    final quiz = this.quiz;
    if (quiz == null || !quiz.phase.isRevealed) return null;
    return quiz.question?.id;
  }

  /// The standings with, for each team, the score before and after the
  /// question that was just revealed. When nothing has been revealed the
  /// two are equal and the board simply shows the current scores.
  List<ScoreboardEntry> get scoreboard {
    final currentQuestionId = revealKey;
    return rankScoreboard(
      [
        for (final team in teams)
          ScoreboardEntry.fromTeam(
            team,
            currentQuestionId: currentQuestionId,
          ),
      ],
      (entry) => entry.to,
    );
  }

  /// This device's points on the question that was just revealed, if the
  /// team was part of it.
  PubQuizAward? get myAward {
    final award = myTeam?.lastAward;
    final currentQuestionId = revealKey;
    if (award == null || currentQuestionId == null) return null;
    return award.questionId == currentQuestionId ? award : null;
  }

  PubQuizState copyWith({
    PubQuizStatus? status,
    PubQuiz? Function()? quiz,
    List<PubQuizTeam>? teams,
    PubQuizAnswer? Function()? myAnswer,
    PubQuizSubmission? submission,
    String? errorMessage,
  }) {
    return PubQuizState(
      status: status ?? this.status,
      quiz: quiz != null ? quiz() : this.quiz,
      teams: teams ?? this.teams,
      myAnswer: myAnswer != null ? myAnswer() : this.myAnswer,
      submission: submission ?? this.submission,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    quiz,
    teams,
    myAnswer,
    submission,
    errorMessage,
  ];
}
