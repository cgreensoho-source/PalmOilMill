import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/dio_handler.dart';
import '../models/station_model.dart';

class StationRemoteDataSource {
  final ApiClient apiClient;

  StationRemoteDataSource(this.apiClient);

  Future<List<StationModel>> getStations() async {
    try {
      final response = await apiClient.dio.get('/stations');

      // Ambil list dari key "stations" sesuai dokumentasi API kamu
      List data = response.data['stations'];
      return data.map((json) => StationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw DioHandler.parseError(e);
    }
  }
}
