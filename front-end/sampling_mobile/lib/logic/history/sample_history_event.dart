import 'package:equatable/equatable.dart';

abstract class SampleHistoryEvent extends Equatable {
  const SampleHistoryEvent();

  @override
  List<Object> get props => [];
}

class FetchSampleHistory extends SampleHistoryEvent {}
