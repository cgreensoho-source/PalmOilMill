import 'dart:io';
import '../../core/database/db_helper.dart';
import '../datasources/sample_remote_datasource.dart';
import '../models/sample_model.dart';

class SampleRepository {
  final SampleRemoteDataSource remoteDataSource;
  final DBHelper dbHelper;

  SampleRepository(this.remoteDataSource, this.dbHelper);

  Future<String> saveSample({
    required int userId,
    required int stationId,
    required String sampleName,
    required String condition,
    required String userCoordinate, // ATRIBUT BARU WAJIB
    required List<File> images,
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        await remoteDataSource.uploadSample(
          userId: userId,
          stationId: stationId,
          sampleName: sampleName,
          condition: condition,
          userCoordinate: userCoordinate, // LEMPAR KE API
          images: images,
        );
        return "Data berhasil dikirim langsung ke server";
      } catch (e) {
        // Fallback jika API gangguan/time-out
        final sampleId = await dbHelper.insert('offline_samples', {
          'user_id': userId,
          'station_id': stationId,
          'sample_name': sampleName,
          'condition': condition,
          'user_coordinate': userCoordinate, // SIMPAN KE SQLITE
          'created_at': DateTime.now().toIso8601String(),
          'is_synced': 0,
        });

        for (var img in images) {
          await dbHelper.insert('offline_images', {
            'sample_local_id': sampleId,
            'image_path': img.path,
            'user_id': userId,
          });
        }
        return "Server gangguan. Data dialihkan ke lokal.";
      }
    } else {
      // Offline murni
      final sampleId = await dbHelper.insert('offline_samples', {
        'user_id': userId,
        'station_id': stationId,
        'sample_name': sampleName,
        'condition': condition,
        'user_coordinate': userCoordinate, // SIMPAN KE SQLITE
        'created_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      });

      for (var img in images) {
        await dbHelper.insert('offline_images', {
          'sample_local_id': sampleId,
          'image_path': img.path,
          'user_id': userId,
        });
      }
      return "Data disimpan secara lokal (Offline)";
    }
  }

  Future<List<SampleModel>> getHistory() async {
    try {
      final List<dynamic> rawData = await remoteDataSource.getSampleHistory();
      return rawData.map((json) => SampleModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> getSampleDetail(int id) async {
    try {
      return await remoteDataSource.getSampleDetail(id);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
