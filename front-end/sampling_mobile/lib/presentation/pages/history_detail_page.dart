import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
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

          // LOGIKA EKSTRAKSI MULTI-GAMBAR (ARRAY)
          List<String> fullImageUrls = [];
          if (data['images'] != null && data['images'] is List) {
            for (var imgObj in data['images']) {
              if (imgObj is Map && imgObj['image_path'] != null) {
                String path = imgObj['image_path'].toString();
                if (path.isNotEmpty) {
                  String cleanPath = path.replaceAll('\\', '/').trim();
                  String fullUrl = cleanPath.startsWith('/')
                      ? '$serverBaseUrl$cleanPath'
                      : '$serverBaseUrl/$cleanPath';
                  fullImageUrls.add(fullUrl);
                }
              }
            }
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

          // KALKULASI JARAK HISTORIS
          double distance = 0.0;
          bool isInRange = false;
          bool hasValidCoordinates = false;

          try {
            if (lokasiTarget != "Tidak tersedia" &&
                lokasiUser != "Tidak direkam") {
              final targetParts = lokasiTarget.split(',');
              final userParts = lokasiUser.split(',');

              if (targetParts.length >= 2 && userParts.length >= 2) {
                final tLat = double.parse(targetParts[0].trim());
                final tLng = double.parse(targetParts[1].trim());
                final uLat = double.parse(userParts[0].trim());
                final uLng = double.parse(userParts[1].trim());

                distance = Geolocator.distanceBetween(tLat, tLng, uLat, uLng);
                isInRange = distance <= 50.0;
                hasValidCoordinates = true;
              }
            }
          } catch (e) {
            hasValidCoordinates = false;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BOX 1: INFO UTAMA DENGAN LOKASI & VALIDASI
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        _buildRow("Lok. Target", lokasiTarget),
                        _buildRow("Lok. Aktual", lokasiUser),

                        // INDIKATOR VALIDASI RADIUS HISTORIS
                        if (hasValidCoordinates) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isInRange
                                          ? Colors.green.shade700
                                          : Colors.red.shade700)
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    (isInRange
                                            ? Colors.green.shade700
                                            : Colors.red.shade700)
                                        .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isInRange ? Icons.check_circle : Icons.cancel,
                                  color: isInRange
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isInRange
                                        ? "Dalam radius stasiun (${distance.toStringAsFixed(1)} meter)"
                                        : "Di luar radius stasiun (${distance.toStringAsFixed(1)} meter)",
                                    style: TextStyle(
                                      color: isInRange
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

                // BOX 3: GAMBAR (RENDER CAROUSEL HORIZONTAL)
                const Text(
                  "Foto Lampiran",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                fullImageUrls.isEmpty
                    ? _buildImageError(
                        "Data gambar tidak ditemukan pada sampel ini.",
                      )
                    : SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: fullImageUrls.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                                color: Colors.white,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.network(
                                  fullImageUrls[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) {
                                    return _buildImageError(
                                      "Gagal memuat gambar.",
                                    );
                                  },
                                ),
                              ),
                            );
                          },
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
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.broken_image, size: 40, color: Colors.grey),
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
