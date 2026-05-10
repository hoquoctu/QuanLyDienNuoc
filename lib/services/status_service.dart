import 'package:cloud_firestore/cloud_firestore.dart';

class StatusCache {
  static List<Map<String, dynamic>> statuses = [];

  static bool isLoaded = false;

  static Future<void> loadStatuses() async {
    if (isLoaded) return;

    final snapshot =
        await FirebaseFirestore.instance.collection('status').get();

    statuses = snapshot.docs.map((e) => e.data()).toList();

    print("===== STATUS DATA =====");
    print(statuses);
    isLoaded = true;
  }
}
//dữ liệu khi dùng sẽ có 
// [{name: Phòng trống, type: room, key: available}, {name: Ngưng hoạt động, type: room, key: inactive}, {name: Đang thuê, type: room, key: occupied}, {name: Chờ xác nhận, title: payment, key: pending}]