class UserModel {
  final int userId;
  final String nip;
  final String username;
  final String role; // Diambil dari roles[0]['role_name']
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
    // Navigasi ke array roles sesuai bukti Postman
    String extractedRole = "OPERATOR";
    if (json['roles'] != null && (json['roles'] as List).isNotEmpty) {
      extractedRole = json['roles'][0]['role_name'] ?? "OPERATOR";
    }

    return UserModel(
      userId: json['user_id'] ?? 0,
      nip: json['nip'] ?? '-',
      username: json['username'] ?? 'User',
      role: extractedRole,
      token: token ?? '',
      email: json['email'],
      phone: json['phone'],
      gender: json['gender'],
    );
  }

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
