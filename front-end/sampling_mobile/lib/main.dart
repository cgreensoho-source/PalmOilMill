import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/api/api_client.dart';
import 'core/database/db_helper.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/sample_remote_datasource.dart';
import 'data/datasources/station_remote_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/sample_repository.dart';
import 'data/repositories/station_repository.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/auth/auth_event.dart';
import 'logic/auth/auth_state.dart';
import 'logic/sample/sample_bloc.dart';
import 'logic/history/sample_history_bloc.dart';
import 'logic/notification/notification_bloc.dart'; // IMPORT BLOC NOTIFIKASI BARU
import 'presentation/pages/login_page.dart';
import 'presentation/pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Setup API & Database
  final apiClient = ApiClient();
  final dbHelper = DBHelper();

  // 2. Setup Data Sources
  final authRemoteDataSource = AuthRemoteDataSource(apiClient);
  final sampleRemoteDataSource = SampleRemoteDataSource(apiClient);
  final stationRemoteDataSource = StationRemoteDataSource(apiClient);

  // 3. Setup Repositories
  final authRepository = AuthRepository(authRemoteDataSource);
  final sampleRepository = SampleRepository(sampleRemoteDataSource, dbHelper);
  final stationRepository = StationRepository(
    stationRemoteDataSource,
    dbHelper,
  );

  runApp(
    MyApp(
      authRepository: authRepository,
      sampleRepository: sampleRepository,
      stationRepository: stationRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final SampleRepository sampleRepository;
  final StationRepository stationRepository;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.sampleRepository,
    required this.stationRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: sampleRepository),
        RepositoryProvider.value(value: stationRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            // TRIGGER APP STARTED DI SINI
            create: (context) =>
                AuthBloc(authRepository: authRepository)..add(AppStarted()),
          ),
          BlocProvider(
            create: (context) => SampleBloc(
              sampleRepository: sampleRepository,
              stationRepository: stationRepository,
            ),
          ),
          BlocProvider(
            create: (context) =>
                SampleHistoryBloc(sampleRepository: sampleRepository),
          ),
          // INJEKSI BLOC NOTIFIKASI
          BlocProvider(
            create: (context) =>
                NotificationBloc(sampleRepository: sampleRepository),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Sampling App',
          theme: ThemeData(primarySwatch: Colors.green, useMaterial3: false),
          // GUNAKAN ROUTER OTOMATIS, BUKAN HALAMAN LOGIN STATIS
          home: const AppRouter(),
        ),
      ),
    );
  }
}

// Komponen penengah untuk menentukan rute berdasarkan state
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          // Token ditemukan di lokal, langsung operasional
          return const MainPage();
        }

        if (state is AuthUnauthenticated || state is AuthError) {
          // Tidak ada token atau error, arahkan ke login
          return const LoginPage();
        }

        // Tampilan Splash Screen murni saat mengekstrak data dari SharedPreferences
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator(color: Colors.green)),
        );
      },
    );
  }
}
