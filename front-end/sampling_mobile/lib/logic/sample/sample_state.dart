import 'dart:io';
import 'package:equatable/equatable.dart';

// Tambahkan model data di file terpisah nanti (lib/data/models/sample_model.dart)
class SampleModel {
  final int id;
  final String sampleName;
  final String condition;
  final String date;

  SampleModel({
    required this.id,
    required this.sampleName,
    required this.condition,
    required this.date,
  });

  factory SampleModel.fromJson(Map<String, dynamic> json) {
    return SampleModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      sampleName: json['sample_name']?.toString() ?? 'Unknown',
      condition: json['condition']?.toString() ?? '-',
      date: json['created_at']?.toString() ?? '-',
    );
  }
}

class SampleState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final List<File> capturedImages;
  final int? validatedStationId;
  final String? stationName;
  final String? coordinates;
  final bool isValidatingStation;

  // PROPERTI BARU UNTUK HISTORY
  final bool isFetchingHistory;
  final List<SampleModel> historyList;

  const SampleState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.capturedImages = const [],
    this.validatedStationId,
    this.stationName,
    this.coordinates,
    this.isValidatingStation = false,
    this.isFetchingHistory = false, // Default false
    this.historyList = const [], // Default kosong
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
    bool? isFetchingHistory,
    List<SampleModel>? historyList,
  }) {
    return SampleState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Boleh null untuk reset
      successMessage: successMessage, // Boleh null untuk reset
      capturedImages: capturedImages ?? this.capturedImages,
      validatedStationId: validatedStationId ?? this.validatedStationId,
      stationName: stationName ?? this.stationName,
      coordinates: coordinates ?? this.coordinates,
      isValidatingStation: isValidatingStation ?? this.isValidatingStation,
      isFetchingHistory: isFetchingHistory ?? this.isFetchingHistory,
      historyList: historyList ?? this.historyList,
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
    isFetchingHistory,
    historyList,
  ];
}
