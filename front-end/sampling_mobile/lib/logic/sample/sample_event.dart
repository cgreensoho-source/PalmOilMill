import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class SampleEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class ScanQRCodeTriggered extends SampleEvent {
  final String qrData;
  ScanQRCodeTriggered(this.qrData);
}

class PhotoTaken extends SampleEvent {
  final File image;
  PhotoTaken(this.image);
}

class PhotoRemoved extends SampleEvent {
  final int index;
  PhotoRemoved(this.index);
}

class SampleSubmitted extends SampleEvent {
  final int userId;
  final int stationId;
  final String sampleName;
  final String condition;
  final String userCoordinate; // ATRIBUT BARU WAJIB
  final bool isOnline;

  SampleSubmitted({
    required this.userId,
    required this.stationId,
    required this.sampleName,
    required this.condition,
    required this.userCoordinate, // ATRIBUT BARU WAJIB
    required this.isOnline,
  });

  @override
  List<Object> get props => [
    userId,
    stationId,
    sampleName,
    condition,
    userCoordinate,
    isOnline,
  ];
}

class FetchSampleHistoryTriggered extends SampleEvent {}
