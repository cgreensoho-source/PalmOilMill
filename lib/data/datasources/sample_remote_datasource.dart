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
      print(
        'SampleRemoteDataSource: Preparing upload - userId: $userId, stationId: $stationId, sampleName: $sampleName, images: ${images.length}',
      );
      // Siapkan FormData sesuai spek Backend Go kamu
      FormData formData = FormData.fromMap({
        'user_id': userId,
        'station_id': stationId,
        'sample_name': sampleName,
        'condition': condition,
        // Mapping list file ke form data
        'images': await Future.wait(
          images.map(
            (file) async => await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        ),
      });

      print('SampleRemoteDataSource: Sending POST request to /samples');
      final response = await apiClient.dio.post('/samples', data: formData);
      print(
        'SampleRemoteDataSource: Response status: ${response.statusCode}, data: ${response.data}',
      );

      return response.data['message'];
    } on DioException catch (e) {
      print(
        'SampleRemoteDataSource: DioException - ${e.response?.statusCode}: ${e.response?.data}',
      );
      throw DioHandler.parseError(e);
    }
  }
}
