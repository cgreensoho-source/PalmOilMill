import 'dart:io';
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
  List<Map<String, dynamic>> _pendingSamples = [];

  @override
  void initState() {
    super.initState();
    _checkPendingData();
  }

  Future<void> _checkPendingData() async {
    final db = await DBHelper().database;
    final samples = await db.rawQuery(
      'SELECT * FROM offline_samples WHERE is_synced = 0 ORDER BY id DESC',
    );

    List<Map<String, dynamic>> enrichedSamples = [];
    for (var sample in samples) {
      final imageRecords = await db.query(
        'offline_images',
        where: 'sample_local_id = ?',
        whereArgs: [sample['id']],
        limit: 1,
      );

      String? firstImagePath;
      if (imageRecords.isNotEmpty) {
        firstImagePath = imageRecords.first['image_path'] as String?;
      }

      enrichedSamples.add({...sample, 'first_image_path': firstImagePath});
    }

    if (mounted) {
      setState(() {
        _pendingSamples = enrichedSamples;
        _pendingCount = samples.length;
      });
    }
  }

  Future<void> _performSync() async {
    if (_pendingCount == 0) return;

    setState(() => _isSyncing = true);
    int previousCount = _pendingCount;

    try {
      final syncService = SyncService(
        SampleRemoteDataSource(ApiClient()),
        DBHelper(),
      );
      await syncService.syncData();

      await _checkPendingData();

      if (mounted) {
        if (_pendingCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Berhasil! Semua antrean telah terkirim."),
              backgroundColor: Colors.green.shade700,
            ),
          );
        } else if (_pendingCount < previousCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Sebagian terkirim. Sisa antrean: $_pendingCount"),
              backgroundColor: Colors.orange.shade700,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Gagal mengunggah! Pastikan internet menyala.",
              ),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } catch (e) {
      await _checkPendingData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Gagal upload: Server menolak atau jaringan bermasalah.",
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return '-';
    try {
      final dt = DateTime.parse(isoString);
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
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
                const Text(
                  "MILLTRACK HPI",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  "Halo, ${firstName.toUpperCase()}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.white70,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserProfilePage(),
                  ),
                );
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
      body: BlocListener<SampleBloc, SampleState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            _checkPendingData();
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
          child: Column(
            children: [
              Material(
                color: _pendingCount > 0
                    ? Colors.orange.shade600
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(32),
                elevation: _pendingCount > 0 ? 8 : 0,
                shadowColor: Colors.orange.shade200,
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: _isSyncing || _pendingCount == 0 ? null : _performSync,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isSyncing)
                          const SizedBox(
                            height: 60,
                            width: 60,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 6,
                            ),
                          )
                        else
                          Icon(
                            _pendingCount > 0
                                ? Icons.cloud_upload_rounded
                                : Icons.cloud_done_rounded,
                            size: 60,
                            color: _pendingCount > 0
                                ? Colors.white
                                : Colors.grey.shade500,
                          ),
                        const SizedBox(height: 12),
                        Text(
                          _pendingCount > 0 ? "UNGGAH DATA" : "SISTEM SINKRON",
                          style: TextStyle(
                            fontSize: 20,
                            color: _pendingCount > 0
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _pendingCount > 0
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _pendingCount > 0
                        ? Colors.orange.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _pendingCount > 0
                          ? Icons.schedule_rounded
                          : Icons.check_circle_outline,
                      size: 16,
                      color: _pendingCount > 0
                          ? Colors.orange.shade800
                          : Colors.green.shade800,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _pendingCount > 0
                          ? "Ada $_pendingCount sampel menunggu diunggah"
                          : "Tidak ada antrean data lokal",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _pendingCount > 0
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_pendingCount > 0)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _pendingSamples.length,
                    itemBuilder: (context, index) {
                      final sample = _pendingSamples[index];
                      final imagePath = sample['first_image_path'] as String?;
                      final timeString = _formatDateTime(
                        sample['created_at']?.toString(),
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child:
                                    imagePath != null &&
                                        File(imagePath).existsSync()
                                    ? Image.file(
                                        File(imagePath),
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey.shade200,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sample['sample_name']?.toString() ??
                                          'Sampel Tidak Bernama',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sample['condition']?.toString() ?? '-',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          timeString,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
