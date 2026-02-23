import 'user_model.dart';

class LoginResponse {
  final String token;
  final UserModel user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final String receivedToken = json['token'] ?? '';
    return LoginResponse(
      token: receivedToken,
      user: UserModel.fromJson(json['user'], token: receivedToken),
    );
  }
}
