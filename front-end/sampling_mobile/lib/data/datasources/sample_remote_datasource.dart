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
      String endpoint = '/samples/my';

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_session_data');

      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        final String role =
            userMap['role']?.toString().toUpperCase() ?? 'OPERATOR';

        if (role == 'ADMIN') {
          endpoint = '/samples';
        }
      }

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
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_session_data');
      String role = 'OPERATOR';

      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        role = userMap['role']?.toString().toUpperCase() ?? 'OPERATOR';
      }

      if (role == 'ADMIN') {
        final response = await apiClient.dio.get('/samples/$id');
        final dynamic rawData = response.data;

        if (rawData is Map) {
          if (rawData.containsKey('data')) return rawData['data'];
          return rawData as Map<String, dynamic>;
        }
        throw Exception("Format balasan Admin tidak dikenali.");
      } else {
        final response = await apiClient.dio.get('/samples/my');
        final dynamic rawData = response.data;

        List<dynamic> listData = [];
        if (rawData is Map) {
          listData =
              rawData['data'] ?? rawData['samples'] ?? rawData['items'] ?? [];
        } else if (rawData is List) {
          listData = rawData;
        }

        if (listData.isEmpty) {
          throw Exception(
            "Riwayat kosong. Server tidak mengembalikan data apa pun.",
          );
        }

        final detailData = listData.firstWhere((element) {
          if (element is Map) {
            final elementId =
                element['id'] ?? element['sample_id'] ?? element['ID'];
            if (elementId != null) {
              return elementId.toString().trim() == id.toString().trim();
            }
          }
          return false;
        }, orElse: () => null);

        if (detailData != null) {
          return detailData as Map<String, dynamic>;
        } else {
          throw Exception(
            "Gagal merender detail: ID Sampel ($id) tidak ditemukan di dalam respons array server.",
          );
        }
      }
    } on DioException catch (e) {
      throw DioHandler.parseError(e);
    }
  }

  Future<List<dynamic>> getApprovedSamples() async {
    try {
      final response = await apiClient.dio.get('/samples/approved');

      if (response.data is Map) {
        return response.data['data'] ??
            response.data['samples'] ??
            response.data['items'] ??
            [];
      } else if (response.data is List) {
        return response.data;
      }
      return [];
    } on DioException catch (e) {
      throw DioHandler.parseError(e);
    }
  }
}
