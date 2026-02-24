class NotificationModel {
  final int sampleId;
  final String sampleName;
  final bool isReviewed;
  final String createdAt;

  NotificationModel({
    required this.sampleId,
    required this.sampleName,
    required this.isReviewed,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      sampleId: json['sample_id'],
      sampleName: json['sample_name'] ?? '',
      isReviewed: json['is_reviewed'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}