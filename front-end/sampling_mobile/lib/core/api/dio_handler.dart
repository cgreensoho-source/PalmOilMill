import 'package:dio/dio.dart';

class DioHandler {
  static String parseError(DioException error) {
    if (error.response != null) {
      // Mengambil pesan error dari JSON backend kamu: {"error": "pesan"}
      return error.response?.data['error'] ?? "Terjadi kesalahan server";
    }
    if (error.type == DioExceptionType.connectionTimeout) {
      return "Koneksi internet tidak stabil (Timeout)";
    }
    return "Tidak dapat terhubung ke server";
  }
}
