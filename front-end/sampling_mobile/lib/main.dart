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
import 'logic/notification/notification_bloc.dart';
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
          BlocProvider(
            create: (context) =>
                NotificationBloc(sampleRepository: sampleRepository),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MillTrack HPI',
          theme: ThemeData(
            primarySwatch: Colors.green,
            useMaterial3: false,
            fontFamily: 'MaisonNeue',
            appBarTheme: const AppBarTheme(
              titleTextStyle: TextStyle(
                fontFamily: 'MaisonNeue',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          home: const AppRouter(),
        ),
      ),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Penundaan 2 detik sebelum masuk ke logika Auth
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (_showSplash || state is AuthInitial) {
          return const SplashUI();
        }

        if (state is AuthAuthenticated) {
          return const MainPage();
        }

        if (state is AuthUnauthenticated || state is AuthError) {
          return const LoginPage();
        }

        return const SplashUI();
      },
    );
  }
}

class SplashUI extends StatelessWidget {
  const SplashUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // LOGO UTAMA DI TENGAH
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.factory, size: 100, color: Colors.green.shade800),
            ),
          ),

          // BRANDING PERUSAHAAN DI BAGIAN BAWAH
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "from",
                  style: TextStyle(
                    fontSize: 14, // Ukuran teks sedikit diperbesar
                    color: Colors.grey.shade500,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Image.asset(
                  'assets/images/cgreen.png',
                  height:
                      80, // Logo cgreen diperbesar secara signifikan dari sebelumnya (35)
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      "ASSET ERROR",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
