import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Tracks only the currently-selected schedule tab index. The number of
/// tabs is no longer fixed (see `Schedule.days`) so this just stores a raw
/// index rather than a fixed day1/day2/day3 enum - out-of-range values
/// (e.g. the cached index from a previous, longer schedule) are clamped by
/// callers against the current day count.
class ScheduleCubit extends HydratedCubit<int> {
  ScheduleCubit() : super(0);

  void toggleTab(int index) => emit(index);

  @override
  int? fromJson(Map<String, dynamic> json) => json['index'] as int?;

  @override
  Map<String, dynamic>? toJson(int state) => {'index': state};
}
