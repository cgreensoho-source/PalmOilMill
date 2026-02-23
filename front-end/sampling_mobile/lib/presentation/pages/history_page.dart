import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/history/sample_history_bloc.dart';
import '../../logic/history/sample_history_event.dart';
import '../../logic/history/sample_history_state.dart';
import 'history_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<SampleHistoryBloc>().add(FetchSampleHistory());
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.green.shade700),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      context.read<SampleHistoryBloc>().add(
        FilterSampleHistory("Pilih Tanggal", selectedDate: picked),
      );
    }
  }

  Map<String, String> _parseDateTime(String rawDate) {
    if (rawDate == '-' || rawDate.isEmpty) return {'time': '-', 'date': '-'};
    try {
      final DateTime parsed = DateTime.parse(rawDate).toLocal();
      return {
        'time':
            "${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}",
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
          "Riwayat Sampling",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        actions: [_buildFilterMenu()],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            context.read<SampleHistoryBloc>().add(FetchSampleHistory()),
        child: BlocBuilder<SampleHistoryBloc, SampleHistoryState>(
          builder: (context, state) {
            if (state is SampleHistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SampleHistoryError) {
              return _buildErrorState(context, state.message);
            }

            if (state is SampleHistoryLoaded) {
              if (state.samples.isEmpty) {
                return _buildEmptyState(context, state.currentFilter);
              }

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                itemCount: state.samples.length,
                itemBuilder: (context, index) {
                  final sample = state.samples[index];
                  final dt = _parseDateTime(sample.date);
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: Icon(
                          Icons.science,
                          color: Colors.green.shade800,
                        ),
                      ),
                      title: Text(
                        sample.sampleName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            "Kondisi: ${sample.condition}",
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Waktu: ${dt['time']}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "Tanggal: ${dt['date']}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HistoryDetailPage(sample: sample),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildFilterMenu() {
    return BlocBuilder<SampleHistoryBloc, SampleHistoryState>(
      builder: (context, state) {
        String current = (state is SampleHistoryLoaded)
            ? state.currentFilter
            : "Semua";

        final List<String> opts = [
          "Semua",
          "Hari Ini",
          "7 Hari Terakhir",
          "30 Hari Terakhir",
          "3 Bulan Terakhir",
          "Pilih Tanggal",
        ];

        return PopupMenuButton<String>(
          // PEMBARUAN: Menggunakan Icons.filter_alt sesuai gambar yang Anda berikan
          icon: const Icon(Icons.filter_alt),
          onSelected: (val) => val == "Pilih Tanggal"
              ? _selectDate(context)
              : context.read<SampleHistoryBloc>().add(FilterSampleHistory(val)),
          itemBuilder: (context) => opts
              .map(
                (o) => PopupMenuItem(
                  value: o,
                  child: Text(
                    o,
                    style: TextStyle(
                      fontWeight: o == current
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String filter) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "Tidak ada data untuk filter: $filter\n(Tarik ke bawah untuk muat ulang)",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String msg) {
    String displayMsg = msg;
    // Logika deteksi koneksi tetap ada tetapi tidak mematikan pesan asli server
    if (msg.toLowerCase().contains("failed host lookup") ||
        msg.toLowerCase().contains("connection timed out")) {
      displayMsg = "Tidak ada koneksi internet";
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Color.fromARGB(255, 102, 102, 102),
            ),
            const SizedBox(height: 16),
            Text(
              "Terjadi Kesalahan:\n$displayMsg",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Tarik ke bawah untuk mencoba lagi",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
