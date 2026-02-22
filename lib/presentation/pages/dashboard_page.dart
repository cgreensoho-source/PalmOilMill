import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api/api_client.dart';
import '../../core/database/db_helper.dart';
import '../../data/datasources/sample_remote_datasource.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_state.dart';
import '../../logic/sample/sample_bloc.dart';
import '../../logic/sample/sample_state.dart';
import '../../logic/sample/sync_service.dart';
import 'user_profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _pendingCount = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkPendingData();
  }

  // Fungsi membaca jumlah data di SQLite
  Future<void> _checkPendingData() async {
    final db = await DBHelper().database;
    final count = await db.rawQuery(
      'SELECT COUNT(*) as total FROM offline_samples WHERE is_synced = 0',
    );
    if (mounted) {
      setState(() {
        _pendingCount = firstFormFieldValue(count) ?? 0;
      });
    }
  }

  int? firstFormFieldValue(List<Map<String, dynamic>> list) {
    if (list.isNotEmpty) return list.first['total'] as int?;
    return 0;
  }

  // Fungsi sinkronisasi manual saat tombol ditekan
  Future<void> _performSync() async {
    if (_pendingCount == 0) return;

    setState(() => _isSyncing = true);

    final syncService = SyncService(SampleRemoteDataSource(ApiClient()), DBHelper());
    await syncService.syncData();
    await _checkPendingData(); // Update angka setelah sync

    setState(() => _isSyncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text("Sisa antrean sekarang: $_pendingCount"),
              ],
            ),
            backgroundColor: _pendingCount == 0 ? Colors.green.shade700 : Colors.orange.shade700,
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade700;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            String firstName = "Pekerja";
            if (state is AuthAuthenticated) {
              firstName = state.user.username.split(" ")[0];
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("MILLTRACK HPI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2)),
                Text("Halo, ${firstName.toUpperCase()}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70)),
              ],
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfilePage()));
              },
              customBorder: const CircleBorder(),
              child: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      // BlocListener UTAMA: Mendeteksi jika ada data baru masuk dari form!
      body: BlocListener<SampleBloc, SampleState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            _checkPendingData(); // Langsung perbarui tampilan jika form sukses
          }
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- TOMBOL SINKRONISASI RAKSASA ---
                Material(
                  color: _pendingCount > 0 ? Colors.orange.shade600 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(32),
                  elevation: _pendingCount > 0 ? 8 : 0,
                  shadowColor: Colors.orange.shade200,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(32),
                    onTap: _isSyncing || _pendingCount == 0 ? null : _performSync,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSyncing)
                            const SizedBox(
                                height: 72,
                                width: 72,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 6)
                            )
                          else
                            Icon(
                              _pendingCount > 0 ? Icons.cloud_upload_rounded : Icons.cloud_done_rounded,
                              size: 72,
                              color: _pendingCount > 0 ? Colors.white : Colors.grey.shade500,
                            ),
                          const SizedBox(height: 16),
                          Text(
                            _pendingCount > 0 ? "UNGGAH DATA" : "SISTEM SINKRON",
                            style: TextStyle(
                              fontSize: 22,
                              color: _pendingCount > 0 ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- STATUS KECIL DI BAWAH TOMBOL ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _pendingCount > 0 ? Colors.orange.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _pendingCount > 0 ? Colors.orange.shade200 : Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          _pendingCount > 0 ? Icons.schedule_rounded : Icons.check_circle_outline,
                          size: 16,
                          color: _pendingCount > 0 ? Colors.orange.shade800 : Colors.green.shade800
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _pendingCount > 0
                            ? "Ada $_pendingCount sampel menunggu diunggah"
                            : "Tidak ada antrean data lokal",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _pendingCount > 0 ? Colors.orange.shade800 : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}