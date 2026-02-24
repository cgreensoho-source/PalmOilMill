import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/sample_model.dart';
import '../../data/repositories/sample_repository.dart';

class HistoryDetailPage extends StatefulWidget {
  final SampleModel sample;

  const HistoryDetailPage({super.key, required this.sample});

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  // Base URL Server untuk akses file statis publik
  final String serverBaseUrl = 'http://103.49.239.94:8082';

  late Future<Map<String, dynamic>> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = context.read<SampleRepository>().getSampleDetail(
      widget.sample.id,
    );
  }

  Map<String, String> _formatDateTime(String rawDate) {
    if (rawDate == '-' || rawDate.isEmpty) return {'time': '-', 'date': '-'};
    try {
      final DateTime parsed = DateTime.parse(rawDate).toLocal();
      return {
        'time':
            "${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}:${parsed.second.toString().padLeft(2, '0')}",
        'date':
            "${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.year}",
      };
    } catch (e) {
      return {'time': '-', 'date': rawDate};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Detail Sampling",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Gagal memuat: ${snapshot.error}"));
          }

          // Ekstraksi Root Data
          final rawData = snapshot.data ?? {};
          final data = rawData.containsKey('data') && rawData['data'] is Map
              ? rawData['data']
              : rawData;

          // LOGIKA EKSTRAKSI ARRAY GAMBAR
          String? imagePath;
          if (data['images'] != null &&
              data['images'] is List &&
              (data['images'] as List).isNotEmpty) {
            imagePath = data['images'][0]['image_path'];
          }

          String fullImageUrl = "";
          if (imagePath != null && imagePath.isNotEmpty) {
            String cleanPath = imagePath.replaceAll('\\', '/').trim();
            fullImageUrl = cleanPath.startsWith('/')
                ? '$serverBaseUrl$cleanPath'
                : '$serverBaseUrl/$cleanPath';
          }

          // EKSTRAKSI WAKTU & KONDISI
          final dt = _formatDateTime(
            data['created_at']?.toString() ?? widget.sample.date,
          );
          final String kondisiStr = data['condition']?.toString() ?? '-';

          // EKSTRAKSI LOKASI TARGET
          String lokasiTarget = "Tidak tersedia";
          if (data['station'] != null &&
              data['station']['coordinate'] != null) {
            lokasiTarget = data['station']['coordinate'].toString();
          }

          // EKSTRAKSI LOKASI AKTUAL/USER
          String lokasiUser = "Tidak direkam";
          if (data['latitude'] != null && data['longitude'] != null) {
            lokasiUser = "${data['latitude']}, ${data['longitude']}";
          } else if (data['user_coordinate'] != null) {
            lokasiUser = data['user_coordinate'].toString();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BOX 1: INFO UTAMA DENGAN LOKASI
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.science, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.sample.sampleName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildRow("Waktu", dt['time']!),
                        _buildRow("Tanggal", dt['date']!),
                        // SizedBox dihapus di sini agar jaraknya sama dengan baris lain
                        _buildRow("Lok. Target", lokasiTarget),
                        _buildRow("Lok. Aktual", lokasiUser),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // BOX 2: KONDISI (Inset style)
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    "Catatan Kondisi",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: Text(
                    kondisiStr,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // BOX 3: GAMBAR
                const Text(
                  "Foto Lampiran",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.white,
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 200),
                    child: fullImageUrl.isEmpty
                        ? _buildImageError(
                            "Data gambar tidak ditemukan pada sampel ini.",
                          )
                        : Image.network(
                            fullImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) {
                              return _buildImageError(
                                "Gagal memuat: $fullImageUrl",
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const Text(": ", style: TextStyle(color: Colors.grey)),
        Expanded(
          child: Text(
            val,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    ),
  );

  Widget _buildImageError(String msg) => Container(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        const SizedBox(height: 8),
        Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    ),
  );
}
