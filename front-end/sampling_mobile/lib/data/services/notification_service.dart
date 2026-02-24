import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class NotificationService {
  static Future<List<NotificationModel>> getNotifications() async {
    final response = await http.get(
      Uri.parse("http://103.49.239.94:8082/api/v1"),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);

      return data
          .map((e) => NotificationModel.fromJson(e))
          .toList();
    } else {
      throw Exception("Gagal ambil data");
    }
  }
}