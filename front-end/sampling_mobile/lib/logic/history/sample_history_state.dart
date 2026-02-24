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
  final List<SampleModel>
  samples; // Data yang sudah difilter (ditampilkan di UI)
  final List<SampleModel> allSamples; // Data mentah dari API (cache lokal)
  final String currentFilter; // Menyimpan status filter aktif

  const SampleHistoryLoaded({
    required this.samples,
    required this.allSamples,
    this.currentFilter = "Semua",
  });

  @override
  List<Object> get props => [samples, allSamples, currentFilter];
}

class SampleHistoryError extends SampleHistoryState {
  final String message;

  const SampleHistoryError(this.message);

  @override
  List<Object> get props => [message];
}
