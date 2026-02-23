import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

// User menekan tombol login
class LoginSubmitted extends AuthEvent {
  final String username;
  final String password;

  LoginSubmitted({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}

// Cek status saat aplikasi pertama dibuka
class AppStarted extends AuthEvent {}

// User menekan tombol logout
class LogoutRequested extends AuthEvent {}
