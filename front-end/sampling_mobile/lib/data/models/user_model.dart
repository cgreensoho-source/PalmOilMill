class UserModel {
  final int userId;
  final String nip;
  final String username;
  final String role;
  final String token;
  final String? email;
  final String? phone;
  final String? gender;

  UserModel({
    required this.userId,
    required this.nip,
    required this.username,
    required this.role,
    required this.token,
    this.email,
    this.phone,
    this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    // Ekstraksi array roles sesuai format JSON backend
    String extractedRole = "OPERATOR";
    if (json['roles'] != null && (json['roles'] as List).isNotEmpty) {
      extractedRole =
          json['roles'][0]['role_name']?.toString().toUpperCase() ?? "OPERATOR";
    }

    return UserModel(
      userId: json['user_id'] ?? 0,
      nip: json['nip'] ?? '-',
      username: json['username'] ?? 'User',
      role: extractedRole,
      token: token ?? '',
      email: json['email'],
      phone: json['phone']?.toString(),
      gender: json['gender'],
    );
  }

  // Metode krusial yang hilang untuk serialisasi data lokal
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'nip': nip,
      'username': username,
      'role': role,
      'token': token,
      'email': email,
      'phone': phone,
      'gender': gender,
    };
  }
}
