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
      ),
      body: BlocBuilder<SampleHistoryBloc, SampleHistoryState>(
        builder: (context, state) {
          if (state is SampleHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SampleHistoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.read<SampleHistoryBloc>().add(
                      FetchSampleHistory(),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Coba Lagi"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is SampleHistoryLoaded) {
            if (state.samples.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<SampleHistoryBloc>().add(FetchSampleHistory());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: state.samples.length,
                itemBuilder: (context, index) {
                  final sample = state.samples[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
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
                          const SizedBox(height: 4),
                          Text("Kondisi: ${sample.condition}"),
                          Text(
                            "Tanggal: ${sample.date}",
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HistoryDetailPage(sample: sample),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Belum ada riwayat",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () =>
                context.read<SampleHistoryBloc>().add(FetchSampleHistory()),
            icon: const Icon(Icons.refresh),
            label: const Text("Muat Ulang"),
          ),
        ],
      ),
    );
  }
}
