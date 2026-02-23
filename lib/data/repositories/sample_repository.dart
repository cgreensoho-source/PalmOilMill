import 'dart:io';
import '../../core/database/db_helper.dart';
import '../datasources/sample_remote_datasource.dart';

class SampleRepository {
  final SampleRemoteDataSource remoteDataSource;
  final DBHelper dbHelper;

  SampleRepository(this.remoteDataSource, this.dbHelper);

  Future<String> saveSample({
    required int userId,
    required int stationId,
    required String sampleName,
    required String condition,
    required List<File> images,
    required bool isOnline,
  }) async {
    print(
      'SampleRepository.saveSample called: isOnline=$isOnline, userId=$userId, stationId=$stationId, sampleName=$sampleName',
    );
    if (isOnline) {
      // Jika Online: Langsung tembak ke Backend Go
      print('Attempting to upload to backend...');
      try {
        final result = await remoteDataSource.uploadSample(
          userId: userId,
          stationId: stationId,
          sampleName: sampleName,
          condition: condition,
          images: images,
        );
        print('Upload successful: $result');
        return result;
      } catch (e) {
        print('Upload failed: $e');
        // Jika gagal upload, simpan ke lokal sebagai fallback
        print('Saving to local DB as fallback...');
        final sampleId = await dbHelper.insert('offline_samples', {
          'user_id': userId,
          'station_id': stationId,
          'sample_name': sampleName,
          'condition': condition,
          'created_at': DateTime.now().toIso8601String(),
          'is_synced': 0,
        });
        print('Saved to local DB with id: $sampleId');
        return "Data disimpan lokal karena upload gagal";
      }
    } else {
      // Jika Offline: Simpan ke SQFlite
      print('Saving offline to local DB...');
      final sampleId = await dbHelper.insert('offline_samples', {
        'user_id': userId,
        'station_id': stationId,
        'sample_name': sampleName,
        'condition': condition,
        'created_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      });
      print('Saved offline with id: $sampleId');

      // Simpan path gambar petugas ke tabel offline_images
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
}
