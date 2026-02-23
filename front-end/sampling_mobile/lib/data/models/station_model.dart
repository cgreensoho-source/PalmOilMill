class StationModel {
  final int stationId;
  final String stationName;
  final String coordinate;

  StationModel({
    required this.stationId,
    required this.stationName,
    required this.coordinate,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      stationId: json['station_id'],
      stationName: json['station_name'],
      coordinate: json['coordinate'],
    );
  }

  // Method untuk convert ke Map agar bisa disimpan ke SQFlite (Tabel stations)
  Map<String, dynamic> toMap() {
    return {
      'station_id': stationId,
      'station_name': stationName,
      'coordinate': coordinate,
    };
  }
}
