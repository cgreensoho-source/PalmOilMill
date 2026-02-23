import 'package:equatable/equatable.dart';

abstract class SampleHistoryEvent extends Equatable {
  const SampleHistoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchSampleHistory extends SampleHistoryEvent {}

class FilterSampleHistory extends SampleHistoryEvent {
  final String filterRange;
  final DateTime? selectedDate;

  const FilterSampleHistory(this.filterRange, {this.selectedDate});

  @override
  List<Object?> get props => [filterRange, selectedDate];
}
