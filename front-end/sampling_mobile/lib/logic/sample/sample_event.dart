import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class SampleEvent extends Equatable {
  @override
  List<Object> get props => [];
}

// Saat user scan QR Code
class ScanQRCodeTriggered extends SampleEvent {
  final String qrData;
  ScanQRCodeTriggered(this.qrData);
}

// Saat user mengambil foto petugas (Bisa dipanggil berkali-kali)
class PhotoTaken extends SampleEvent {
  final File image;
  PhotoTaken(this.image);
}

// Menghapus foto yang salah sebelum submit
class PhotoRemoved extends SampleEvent {
  final int index;
  PhotoRemoved(this.index);
}

// Saat user menekan tombol simpan/kirim
class SampleSubmitted extends SampleEvent {
  final int userId;
  final int stationId;
  final String sampleName;
  final String condition;
  final bool isOnline;

  SampleSubmitted({
    required this.userId,
    required this.stationId,
    required this.sampleName,
    required this.condition,
    required this.isOnline,
  });
}
