import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sampling_mobile/presentation/pages/dashboard_page.dart';
import 'package:sampling_mobile/presentation/pages/sample_form_page.dart';
import 'core/api/api_client.dart';
import 'core/database/db_helper.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/sample_remote_datasource.dart';
import 'data/datasources/station_remote_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/sample_repository.dart';
import 'data/repositories/station_repository.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/sample/sample_bloc.dart';
import 'presentation/pages/login_page.dart';

void main() async {
  // Pastikan plugin flutter sudah terinisialisasi sebelum panggil DB/API
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
    return MultiBlocProvider(
      providers: [
        // Provider untuk Login/Logout
        BlocProvider(
          create: (context) => AuthBloc(authRepository: authRepository),
        ),
        // Provider untuk Scan QR & Input Sampling
        BlocProvider(
          create: (context) => SampleBloc(
            sampleRepository: sampleRepository,
            stationRepository: stationRepository,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sampling App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: false, // Biar style seragam dengan tutorial sebelumnya
        ),
        home: const LoginPage(),
      ),
    );
  }
}
