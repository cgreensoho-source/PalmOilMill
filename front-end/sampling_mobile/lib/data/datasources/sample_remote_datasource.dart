import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    required String userCoordinate,
    required List<File> images,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'user_id': userId,
        'station_id': stationId,
        'sample_name': sampleName,
        'condition': condition,
        'user_coordinate': userCoordinate,
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
      // 1. Tentukan rute default untuk keamanan (Operator)
      String endpoint = '/samples/my';

      // 2. Ekstraksi Role dari sesi lokal
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_session_data');

      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        final String role =
            userMap['role']?.toString().toUpperCase() ?? 'OPERATOR';

        // 3. Override rute jika terdeteksi otorisasi Admin
        if (role == 'ADMIN') {
          endpoint = '/samples';
        }
      }

      // 4. Eksekusi request dinamis
      final response = await apiClient.dio.get(endpoint);

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

  Future<Map<String, dynamic>> getSampleDetail(int id) async {
    try {
      // 1. Tentukan rute detail default untuk Operator
      String endpoint = '/samples/my/$id';

      // 2. Ekstraksi Role dari sesi lokal
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_session_data');

      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        final String role =
            userMap['role']?.toString().toUpperCase() ?? 'OPERATOR';

        // 3. Override rute detail jika Admin
        if (role == 'ADMIN') {
          endpoint = '/samples/$id';
        }
      }

      // 4. Eksekusi request dinamis
      final response = await apiClient.dio.get(endpoint);
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw DioHandler.parseError(e);
    }
  }
}
