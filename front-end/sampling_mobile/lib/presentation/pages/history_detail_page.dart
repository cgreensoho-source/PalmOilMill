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
  // WAJIB UBAH: URL Backend Go Anda (contoh: http://192.168.1.5:8080)
  final String apiBaseUrl = 'https://api.domainanda.com';

  late Future<Map<String, dynamic>> _detailFuture;

  @override
  void initState() {
    super.initState();
    // Menembak API detail GET /samples/{id} saat halaman dibuka
    _detailFuture = context.read<SampleRepository>().getSampleDetail(
      widget.sample.id,
    );
  }

  Map<String, String> _parseDateTime(String rawDate) {
    if (rawDate == '-' || rawDate.isEmpty) return {'time': '-', 'date': '-'};

    try {
      final DateTime parsed = DateTime.parse(rawDate).toLocal();

      final String time =
          "${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}:${parsed.second.toString().padLeft(2, '0')}";
      final String date =
          "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}";

      return {'time': time, 'date': date};
    } catch (e) {
      if (rawDate.contains('T')) {
        final parts = rawDate.split('T');
        final datePart = parts[0];
        final timePart = parts[1].split('.')[0].split('Z')[0];
        return {'time': timePart, 'date': datePart};
      }
      return {'time': '-', 'date': rawDate};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Foto langsung ditembak ke endpoint GET /samples/images/{id}
    final String targetImageUrl =
        '$apiBaseUrl/samples/images/${widget.sample.id}';

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
            return Center(
              child: Text(
                "Gagal memuat detail data dari server.\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // Ekstraksi data dari respons API GET /samples/{id}
          final detailData = snapshot.data ?? {};

          // Asumsi key dari API Anda adalah 'condition' atau 'kondisi'
          final String condition =
              detailData['condition']?.toString() ??
              detailData['kondisi']?.toString() ??
              '-';
          final String rawDate =
              detailData['created_at']?.toString() ?? widget.sample.date;

          final dateTimeMap = _parseDateTime(rawDate);
          final String displayTime = dateTimeMap['time'] ?? '-';
          final String displayDate = dateTimeMap['date'] ?? '-';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.science,
                              color: Colors.green.shade700,
                              size: 30,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.sample.sampleName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30, thickness: 1),
                        _buildDetailRow("Kondisi", condition),
                        const SizedBox(height: 12),
                        _buildDetailRow("Waktu", displayTime),
                        const SizedBox(height: 12),
                        _buildDetailRow("Tanggal", displayDate),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                    height: 300,
                    child: Image.network(
                      targetImageUrl,
                      fit: BoxFit.cover,
                      // Meneruskan token jika API gambar dilindungi. Jika tidak, header ini diabaikan.
                      headers: const {"Accept": "application/json"},
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print("--- ERROR NETWORK IMAGE ---");
                        print("URL: $targetImageUrl");
                        print("Pesan: $error");
                        return Container(
                          padding: const EdgeInsets.all(32),
                          color: Colors.white,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Foto tidak tersedia atau akses ditolak oleh server.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Text(": "),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
