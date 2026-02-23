import 'package:equatable/equatable.dart';
import '../../data/models/sample_model.dart';

abstract class SampleHistoryState extends Equatable {
  const SampleHistoryState();

  @override
  List<Object> get props => [];
}

class SampleHistoryInitial extends SampleHistoryState {}

class SampleHistoryLoading extends SampleHistoryState {}

class SampleHistoryLoaded extends SampleHistoryState {
  final List<SampleModel> samples;

  const SampleHistoryLoaded(this.samples);

  @override
  List<Object> get props => [samples];
}

class SampleHistoryError extends SampleHistoryState {
  final String message;

  const SampleHistoryError(this.message);

  @override
  List<Object> get props => [message];
}
