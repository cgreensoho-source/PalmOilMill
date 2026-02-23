import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/dio_handler.dart';

class SampleRemoteDataSource {
  final ApiClient apiClient;

  SampleRemoteDataSource(this.apiClient);

  Future<String> uploadSample({
    required int userId,
    required int stationId,
    required String sampleName,
    required String condition,
    required List<File> images,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'user_id': userId,
        'station_id': stationId,
        'sample_name': sampleName,
        'condition': condition,
        'images': await Future.wait(
          images.map(
            (file) async => await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        ),
      });

      final response = await apiClient.dio.post('/samples', data: formData);
      return response.data['message'];
    } on DioException catch (e) {
      throw DioHandler.parseError(e);
    }
  }

  Future<List<dynamic>> getSampleHistory() async {
    try {
      final response = await apiClient.dio.get('/samples');
      if (response.data is Map) {
        return response.data['data'] ?? response.data['samples'] ?? [];
      } else if (response.data is List) {
        return response.data;
      }
      return [];
    } on DioException catch (e) {
      throw DioHandler.parseError(e);
    }
  }

  // FUNGSI BARU: Menembak API Detail
  Future<Map<String, dynamic>> getSampleDetail(int id) async {
    try {
      final response = await apiClient.dio.get('/samples/$id');
      // Menyesuaikan jika backend membungkus respons dalam key "data"
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw DioHandler.parseError(e);
    }
  }
}
