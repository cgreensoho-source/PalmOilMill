class NotificationModel {
  final String message;
  final String status;
  final String createdAt;

  NotificationModel({
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      message: json['message'],
      status: json['status'],
      createdAt: json['created_at'],
    );
  }
}