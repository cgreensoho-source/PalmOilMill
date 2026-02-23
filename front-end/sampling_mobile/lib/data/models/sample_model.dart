class SampleModel {
  final int? userId;
  final int? stationId;
  final String sampleName;
  final String condition;
  final List<String> imagePaths; // List path file dari kamera

  SampleModel({
    this.userId,
    this.stationId,
    required this.sampleName,
    required this.condition,
    required this.imagePaths,
  });

  // Karena upload sample pakai Multipart (Form Data),
  // kita tidak butuh toJson standar, tapi butuh Map untuk FormData.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'station_id': stationId,
      'sample_name': sampleName,
      'condition': condition,
    };
  }
}
