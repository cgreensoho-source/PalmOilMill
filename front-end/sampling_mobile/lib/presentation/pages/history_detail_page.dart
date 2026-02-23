import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/sample_model.dart';
import '../../data/repositories/sample_repository.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_state.dart';

class HistoryDetailPage extends StatefulWidget {
  final SampleModel sample;

  const HistoryDetailPage({super.key, required this.sample});

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  // Jalur API sesuai bukti Postman
  final String apiBaseUrl = 'http://103.49.239.94:8082/api/v1';

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
    // Endpoint gambar di dalam /api/v1 sesuai Postman
    final String targetImageUrl = '$apiBaseUrl/images/${widget.sample.id}';

    // Ambil token dari AuthBloc untuk otentikasi
    final authState = context.read<AuthBloc>().state;
    String userToken = "";
    if (authState is AuthAuthenticated) {
      userToken = authState.user.token;
    }

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
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text("Gagal memuat: ${snapshot.error}"));

          final data = snapshot.data ?? {};
          final dt = _formatDateTime(
            data['created_at']?.toString() ?? widget.sample.date,
          );
          final String kondisiStr = data['condition']?.toString() ?? '-';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BOX 1: INFO UTAMA (Waktu & Tanggal)
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
                        const SizedBox(height: 8),
                        _buildRow("Tanggal", dt['date']!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // BOX 2: KONDISI (Box Terpisah sesuai permintaan)
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
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      kondisiStr,
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // BOX 3: GAMBAR (Paling Bawah)
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
                    child: Image.network(
                      targetImageUrl,
                      // WAJIB: Gunakan Token sesuai bukti Postman
                      headers: {"Authorization": "Bearer $userToken"},
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => _buildImageError(),
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

  Widget _buildRow(String label, String val) => Row(
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
      Text(
        val,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ],
  );

  Widget _buildImageError() => Container(
    height: 250,
    width: double.infinity,
    color: Colors.white,
    child: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 50, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            "Foto tidak tersedia (Cek Token/ID)",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}
