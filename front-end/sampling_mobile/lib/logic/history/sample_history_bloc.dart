import 'package:flutter_bloc/flutter_bloc.dart';
import 'sample_history_event.dart';
import 'sample_history_state.dart';
import '../../data/repositories/sample_repository.dart';

class SampleHistoryBloc extends Bloc<SampleHistoryEvent, SampleHistoryState> {
  final SampleRepository sampleRepository;

  SampleHistoryBloc({required this.sampleRepository})
    : super(SampleHistoryInitial()) {
    on<FetchSampleHistory>(_onFetchSampleHistory);
  }

  Future<void> _onFetchSampleHistory(
    FetchSampleHistory event,
    Emitter<SampleHistoryState> emit,
  ) async {
    emit(SampleHistoryLoading());
    try {
      final samples = await sampleRepository.getHistory();
      emit(SampleHistoryLoaded(samples));
    } catch (e) {
      // Membersihkan prefix "Exception:" dari DioHandler jika ada
      emit(SampleHistoryError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
