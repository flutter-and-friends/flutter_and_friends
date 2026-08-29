import 'package:equatable/equatable.dart';

/// This device's answer to one question.
class PubQuizAnswer extends Equatable {
  const PubQuizAnswer({required this.questionId, required this.choice});

  final String questionId;
  final int choice;

  @override
  List<Object> get props => [questionId, choice];
}
