class UserModel {
  final int userId;
  final String nip;
  final String username;
  final String? email;
  final String? phone;
  final String? gender;

  UserModel({
    required this.userId,
    required this.nip,
    required this.username,
    this.email,
    this.phone,
    this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'],
      nip: json['nip'],
      username: json['username'],
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
      'email': email,
      'phone': phone,
      'gender': gender,
    };
  }
}
