import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../data/repositories/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    // Logic Login
    on<LoginSubmitted>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await authRepository.login(
          event.username,
          event.password,
        );
        emit(AuthAuthenticated(response.user));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    // Logic Cek Session (Saat App Dibuka)
    on<AppStarted>((event, emit) async {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        // Jika butuh data user lengkap, bisa panggil API GetProfile di sini
        // Sementara kita buat Unauthenticated dulu agar aman
        emit(AuthUnauthenticated());
      } else {
        emit(AuthUnauthenticated());
      }
    });

    // Logic Logout
    on<LogoutRequested>((event, emit) async {
      await authRepository.logout();
      emit(AuthUnauthenticated());
    });
  }
}
