import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class NotificationService {
  static Future<List<NotificationModel>> getNotifications() async {
    final response = await http.get(
      Uri.parse("http://103.49.239.94:8082/api/v1/samples/approved"),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      List data = decoded['data'];

      // ✅ hanya yang sudah di-review (ACC admin)
      List approvedOnly =
          data.where((e) => e['is_reviewed'] == true).toList();

      print("DATA APPROVED: $approvedOnly");

      return approvedOnly
          .map((e) => NotificationModel.fromJson(e))
          .toList();
    } else {
      throw Exception("Gagal ambil data");
    }
  }
}