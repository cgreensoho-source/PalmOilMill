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
    // 1. Ekstraksi Agresif untuk menangkap ID dari berbagai variasi key backend Go
    final rawId =
        json['id'] ?? json['sample_id'] ?? json['ID'] ?? json['sampleId'] ?? 0;
    final int parsedId = rawId is int
        ? rawId
        : int.tryParse(rawId.toString()) ?? 0;

    // 2. Debugger Logika: Memaksa terminal menampilkan ID yang berhasil ditangkap
    print(
      "--- DEBUG MODEL: Raw ID dari JSON = $rawId | Parsed ID = $parsedId ---",
    );

    return SampleModel(
      id: parsedId,
      sampleName:
          json['sample_name']?.toString() ??
          json['nama_sampel']?.toString() ??
          'Tidak Diketahui',
      condition:
          json['condition']?.toString() ?? json['kondisi']?.toString() ?? '-',
      date:
          json['created_at']?.toString() ?? json['tanggal']?.toString() ?? '-',
    );
  }
}
