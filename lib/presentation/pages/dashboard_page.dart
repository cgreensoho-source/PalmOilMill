import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api/api_client.dart';
import '../../core/database/db_helper.dart';
import '../../data/datasources/sample_remote_datasource.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../../logic/sample/sync_service.dart';
import 'scan_qr_page.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPendingData();
  }

  // Fungsi buat ngecek ada berapa data yang belum terkirim ke server
  Future<void> _checkPendingData() async {
    final db = await DBHelper().database;
    final count = await db.rawQuery(
      'SELECT COUNT(*) as total FROM offline_samples WHERE is_synced = 0',
    );
    setState(() {
      _pendingCount = firstFormFieldValue(count) ?? 0;
    });
  }

  int? firstFormFieldValue(List<Map<String, dynamic>> list) {
    if (list.isNotEmpty) return list.first['total'] as int?;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Sampling"),
        actions: [
          // TOMBOL SYNC UPGRADED
          IconButton(
            icon: Badge(
              label: Text(_pendingCount.toString()),
              isLabelVisible: _pendingCount > 0,
              child: const Icon(Icons.sync),
            ),
            onPressed: () async {
              final syncService = SyncService(
                SampleRemoteDataSource(ApiClient()),
                DBHelper(),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Memulai Sinkronisasi..."),
                  duration: Duration(seconds: 1),
                ),
              );

              await syncService.syncData();
              await _checkPendingData(); // Update angka badge

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Sinkronisasi Selesai!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          // TOMBOL LOGOUT
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String username = "Petugas";
          if (state is AuthAuthenticated) {
            username = state.user.username;
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Halo, $username",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text("Selamat bertugas, pastikan GPS Anda aktif."),
                const SizedBox(height: 30),

                // CARD STATUS SINKRONISASI
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: _pendingCount > 0
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _pendingCount > 0 ? Colors.orange : Colors.green,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _pendingCount > 0 ? Icons.cloud_off : Icons.cloud_done,
                        color: _pendingCount > 0 ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _pendingCount > 0
                              ? "Ada $_pendingCount data belum terkirim. Klik tombol sync di pojok kanan atas."
                              : "Semua data sudah aman di server.",
                          style: TextStyle(
                            color: _pendingCount > 0
                                ? Colors.orange.shade900
                                : Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // TOMBOL UTAMA SCAN QR
                SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScanQRPage(),
                        ),
                      );
                      _checkPendingData(); // Cek data lagi pas balik dari scan
                    },
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 60,
                          color: Colors.white,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "MULAI SCAN QR STASIUN",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }
}
