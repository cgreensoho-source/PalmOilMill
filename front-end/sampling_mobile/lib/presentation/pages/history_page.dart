import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget { // <-- Pastikan namanya HistoryPage
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Riwayat Sampling", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "Belum ada riwayat",
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}