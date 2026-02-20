import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/dio_handler.dart';
import '../models/login_response.dart';

class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource(this.apiClient);

  Future<LoginResponse> login(String username, String password) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw DioHandler.parseError(e);
    }
  }

  // Tambahkan Register jika dibutuhkan di mobile
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/register',
        data: userData,
      );
      return response.data;
    } on DioException catch (e) {
      throw DioHandler.parseError(e);
    }
  }
}
