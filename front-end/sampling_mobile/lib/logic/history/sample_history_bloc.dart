import 'package:flutter_bloc/flutter_bloc.dart';
import 'sample_history_event.dart';
import 'sample_history_state.dart';
import '../../data/repositories/sample_repository.dart';
import '../../data/models/sample_model.dart';

class SampleHistoryBloc extends Bloc<SampleHistoryEvent, SampleHistoryState> {
  final SampleRepository sampleRepository;

  SampleHistoryBloc({required this.sampleRepository})
    : super(SampleHistoryInitial()) {
    on<FetchSampleHistory>(_onFetchSampleHistory);
    on<FilterSampleHistory>(_onFilterSampleHistory);
  }

  Future<void> _onFetchSampleHistory(
    FetchSampleHistory event,
    Emitter<SampleHistoryState> emit,
  ) async {
    emit(SampleHistoryLoading());
    try {
      final rawSamples = await sampleRepository.getHistory();
      rawSamples.sort((a, b) => b.date.compareTo(a.date));
      emit(
        SampleHistoryLoaded(
          samples: rawSamples,
          allSamples: rawSamples,
          currentFilter: "Semua",
        ),
      );
    } catch (e) {
      emit(SampleHistoryError(e.toString()));
    }
  }

  void _onFilterSampleHistory(
    FilterSampleHistory event,
    Emitter<SampleHistoryState> emit,
  ) {
    if (state is SampleHistoryLoaded) {
      final currentState = state as SampleHistoryLoaded;
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);

      List<SampleModel> filtered = currentState.allSamples.where((sample) {
        if (sample.date == '-' || sample.date.isEmpty) return false;
        try {
          DateTime sDate = DateTime.parse(sample.date).toLocal();
          DateTime sDateOnly = DateTime(sDate.year, sDate.month, sDate.day);

          switch (event.filterRange) {
            case "Hari Ini":
              return sDateOnly.isAtSameMomentAs(today);
            case "7 Hari Terakhir":
              return sDate.isAfter(now.subtract(const Duration(days: 7)));
            case "30 Hari Terakhir":
              return sDate.isAfter(now.subtract(const Duration(days: 30)));
            case "3 Bulan Terakhir":
              return sDate.isAfter(now.subtract(const Duration(days: 90)));
            case "Pilih Tanggal":
              if (event.selectedDate == null) return true;
              final sel = event.selectedDate!;
              return sDateOnly.isAtSameMomentAs(
                DateTime(sel.year, sel.month, sel.day),
              );
            default:
              return true;
          }
        } catch (_) {
          return false;
        }
      }).toList();

      String filterLabel = event.filterRange;
      if (event.filterRange == "Pilih Tanggal" && event.selectedDate != null) {
        filterLabel =
            "${event.selectedDate!.day}/${event.selectedDate!.month}/${event.selectedDate!.year}";
      }

      emit(
        SampleHistoryLoaded(
          samples: filtered,
          allSamples: currentState.allSamples,
          currentFilter: filterLabel,
        ),
      );
    }
  }
}
