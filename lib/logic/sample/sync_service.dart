import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/database/db_helper.dart';
import '../../data/datasources/sample_remote_datasource.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncService {
  final SampleRemoteDataSource remoteDataSource;
  final DBHelper dbHelper;

  SyncService(this.remoteDataSource, this.dbHelper);

  Future<void> syncData() async {
    // 1. Cek Koneksi Internet
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) return;

    // 2. Ambil data yang belum ter-sinkron dari Local DB
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> pendingSamples = await db.query(
      'offline_samples',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    if (pendingSamples.isEmpty) return;

    print("Ditemukan ${pendingSamples.length} data untuk disinkronisasi...");

    for (var sampleMap in pendingSamples) {
      try {
        int localId = sampleMap['id'];

        // 3. Ambil foto-fotonya dari tabel offline_images
        final List<Map<String, dynamic>> imageMaps = await db.query(
          'offline_images',
          where: 'sample_local_id = ?',
          whereArgs: [localId],
        );

        List<File> images = imageMaps
            .map((img) => File(img['image_path']))
            .toList();

        // 4. Kirim ke Backend Go (Endpoint /samples)
        await remoteDataSource.uploadSample(
          userId: sampleMap['user_id'],
          stationId: sampleMap['station_id'],
          sampleName: sampleMap['sample_name'],
          condition: sampleMap['condition'],
          images: images,
        );

        // 5. Update status di local DB jadi 'ter-sync'
        await db.update(
          'offline_samples',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [localId],
        );

        print("Data local ID $localId berhasil disinkronisasi.");
      } catch (e) {
        print("Gagal sinkron ID ${sampleMap['id']}: $e");
        // Lanjut ke data berikutnya jika satu gagal
      }
    }
  }
}
