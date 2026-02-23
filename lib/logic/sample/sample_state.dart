import 'dart:io';
import 'package:equatable/equatable.dart';

class SampleState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final List<File> capturedImages;
  final int? validatedStationId;
  final String? stationName;
  final String? coordinates;
  final bool isValidatingStation;

  const SampleState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.capturedImages = const [],
    this.validatedStationId,
    this.stationName,
    this.coordinates,
    this.isValidatingStation = false,
  });

  SampleState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    List<File>? capturedImages,
    int? validatedStationId,
    String? stationName,
    String? coordinates,
    bool? isValidatingStation,
  }) {
    return SampleState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      capturedImages: capturedImages ?? this.capturedImages,
      validatedStationId: validatedStationId ?? this.validatedStationId,
      stationName: stationName ?? this.stationName,
      coordinates: coordinates ?? this.coordinates,
      isValidatingStation: isValidatingStation ?? this.isValidatingStation,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    successMessage,
    capturedImages,
    validatedStationId,
    stationName,
    coordinates,
    isValidatingStation,
  ];
}
