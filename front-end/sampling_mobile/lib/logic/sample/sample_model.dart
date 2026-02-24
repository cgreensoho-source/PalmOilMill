class SampleModel {
  final int id;
  final String sampleName;
  final String condition;
  final String date;
  final List<String> imageUrls; // Tambahan untuk menyimpan daftar foto

  SampleModel({
    required this.id,
    required this.sampleName,
    required this.condition,
    required this.date,
    this.imageUrls = const [],
  });

  factory SampleModel.fromJson(Map<String, dynamic> json) {
    // Parsing array gambar. Backend Anda mungkin menggunakan key 'images' atau 'image_urls'
    List<String> parsedImages = [];
    if (json['images'] != null && json['images'] is List) {
      parsedImages = List<String>.from(json['images'].map((x) => x.toString()));
    } else if (json['image_urls'] != null && json['image_urls'] is List) {
      parsedImages = List<String>.from(
        json['image_urls'].map((x) => x.toString()),
      );
    }

    return SampleModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      sampleName: json['sample_name']?.toString() ?? 'Tidak Diketahui',
      condition: json['condition']?.toString() ?? '-',
      date: json['created_at']?.toString() ?? '-',
      imageUrls: parsedImages,
    );
  }
}
