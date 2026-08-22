part of 'qa_cubit.dart';

enum QaStatus { initial, loading, loaded, error }

enum QaSubmissionStatus { idle, submitting, success, failure }

class QaState extends Equatable {
  const QaState({
    this.status = QaStatus.initial,
    this.questions = const [],
    this.submissionStatus = QaSubmissionStatus.idle,
    this.errorMessage,
  });

  final QaStatus status;

  /// Sorted by votes, most upvoted first.
  final List<Question> questions;

  /// Progress of the question currently being submitted from the ask form.
  final QaSubmissionStatus submissionStatus;

  /// The most recent failure, if any. Shown as a full error screen when
  /// there is nothing else to show, and as a passing notice otherwise.
  final String? errorMessage;

  /// The name the user attached to their latest question, to prefill the
  /// ask form so they do not have to type it every time.
  String? get lastAuthorName {
    Question? latest;
    for (final question in questions) {
      if (!question.isMine) continue;
      if (latest == null || question.createdAt.isAfter(latest.createdAt)) {
        latest = question;
      }
    }
    return latest?.authorName;
  }

  QaState copyWith({
    QaStatus? status,
    List<Question>? questions,
    QaSubmissionStatus? submissionStatus,
    String? errorMessage,
  }) {
    return QaState(
      status: status ?? this.status,
      questions: questions ?? this.questions,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    questions,
    submissionStatus,
    errorMessage,
  ];
}
