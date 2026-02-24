import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  static const String _userSessionKey = 'user_session_data';

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    // Logic Login: Simpan sesi ke memori internal
    on<LoginSubmitted>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await authRepository.login(
          event.username,
          event.password,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _userSessionKey,
          jsonEncode(response.user.toJson()),
        );

        emit(AuthAuthenticated(response.user));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    // Logic Cek Session (Saat App Dibuka): Baca dari memori internal
    on<AppStarted>((event, emit) async {
      emit(AuthLoading());
      try {
        final prefs = await SharedPreferences.getInstance();
        final userString = prefs.getString(_userSessionKey);

        if (userString != null && userString.isNotEmpty) {
          final Map<String, dynamic> userMap = jsonDecode(userString);
          // Ekstrak kembali menjadi UserModel
          final user = UserModel.fromJson(userMap, token: userMap['token']);
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      } catch (e) {
        // Jika JSON rusak atau gagal parsing, paksa login ulang
        emit(AuthUnauthenticated());
      }
    });

    // Logic Logout: Hancurkan data lokal
    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_userSessionKey);

        await authRepository.logout();
        emit(AuthUnauthenticated());
      } catch (e) {
        emit(AuthUnauthenticated());
      }
    });
  }
}
