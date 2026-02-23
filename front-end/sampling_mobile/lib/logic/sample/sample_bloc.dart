import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'sample_event.dart';
import 'sample_state.dart';
import '../../data/repositories/sample_repository.dart';
import '../../data/repositories/station_repository.dart';

class SampleBloc extends Bloc<SampleEvent, SampleState> {
  final SampleRepository sampleRepository;
  final StationRepository stationRepository;

  SampleBloc({required this.sampleRepository, required this.stationRepository})
    : super(const SampleState()) {
    // 1. Logic Tambah Foto (Multiple Camera)
    on<PhotoTaken>((event, emit) {
      final updatedList = List<File>.from(state.capturedImages)
        ..add(event.image);
      emit(state.copyWith(capturedImages: updatedList));
    });

    // 2. Logic Hapus Foto
    on<PhotoRemoved>((event, emit) {
      final updatedList = List<File>.from(state.capturedImages)
        ..removeAt(event.index);
      emit(state.copyWith(capturedImages: updatedList));
    });

    // 3. Logic Submit Sample (Handle Online/Offline Sync)
    on<SampleSubmitted>((event, emit) async {
      if (state.capturedImages.isEmpty) {
        emit(state.copyWith(errorMessage: "Minimal harus ada 1 foto petugas!"));
        return;
      }

      emit(
        state.copyWith(
          isLoading: true,
          errorMessage: null,
          successMessage: null,
        ),
      );
      try {
        final message = await sampleRepository.saveSample(
          userId: event.userId,
          stationId: event.stationId,
          sampleName: event.sampleName,
          condition: event.condition,
          images: state.capturedImages,
          isOnline: event.isOnline,
        );

        // Reset state setelah sukses agar form bersih kembali
        emit(
          state.copyWith(
            isLoading: false,
            successMessage: message,
            capturedImages: [],
            validatedStationId: null,
          ),
        );
      } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    });

    // 4. Logic Scan QR - UPGRADED FULL
    // Mampu membaca format: STATION:2|Station B|-6.2146,106.8451|...
    on<ScanQRCodeTriggered>((event, emit) async {
      emit(state.copyWith(isValidatingStation: true, errorMessage: null));

      try {
        // Pecah string berdasarkan pipe (|)
        final parts = event.qrData.split('|');

        if (parts.isNotEmpty && parts[0].contains('STATION:')) {
          // Ambil bagian pertama "STATION:2", lalu ambil angka setelah ":"
          final stationPart = parts[0];
          final idString = stationPart.split(':')[1];
          final id = int.tryParse(idString);

          if (id != null && parts.length >= 3) {
            final stationName = parts[1];
            final coordinates = parts[2];

            // Validasi dengan API atau local DB
            try {
              final stations = await stationRepository.getAllStations(true);
              final station = stations.firstWhere(
                (s) => s.stationId == id,
                orElse: () => throw Exception('Station not found'),
              );

              emit(
                state.copyWith(
                  validatedStationId: id,
                  stationName: station.stationName,
                  coordinates: station.coordinate,
                  isValidatingStation: false,
                  errorMessage: null,
                ),
              );
              print(
                "LOG: Berhasil validasi QR. Station ID: $id, Name: ${station.stationName}, Coords: ${station.coordinate}",
              );
            } catch (e) {
              // Jika gagal validasi, gunakan data dari QR tapi beri warning
              emit(
                state.copyWith(
                  validatedStationId: id,
                  stationName: stationName,
                  coordinates: coordinates,
                  isValidatingStation: false,
                  errorMessage:
                      "Data stasiun dari QR, tapi gagal validasi dengan server. Pastikan koneksi internet.",
                ),
              );
              print(
                "LOG: QR parsed tapi validasi gagal. Menggunakan data QR. Station ID: $id, Name: $stationName, Coords: $coordinates",
              );
            }
          } else {
            emit(
              state.copyWith(
                isValidatingStation: false,
                errorMessage: "ID Stasiun pada QR tidak valid!",
              ),
            );
          }
        } else {
          // Jika format string tidak sesuai (bukan diawali STATION:)
          emit(
            state.copyWith(
              isValidatingStation: false,
              errorMessage: "Ini bukan QR Code Stasiun resmi!",
            ),
          );
        }
      } catch (e) {
        emit(
          state.copyWith(
            isValidatingStation: false,
            errorMessage: "Gagal membaca data QR: Format salah.",
          ),
        );
      }
    });
  }
}
