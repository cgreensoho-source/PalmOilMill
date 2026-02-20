import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/constants.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_response.dart';

class AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepository(this.remoteDataSource);

  Future<LoginResponse> login(String username, String password) async {
    final response = await remoteDataSource.login(username, password);

    // Simpan token ke storage setelah login berhasil
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, response.token);
    await prefs.setInt('user_id', response.user.userId);

    return response;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(AppConstants.tokenKey);
  }
}
