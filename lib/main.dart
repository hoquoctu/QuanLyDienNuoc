import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quanlydiennc_app/services/status_service.dart';
import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CloudinaryContext.cloudinary = Cloudinary.fromCloudName(
    cloudName: 'dpndx8uik', // lấy từ Dashboard
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await StatusCache.loadStatuses();
  runApp(const QuanLyDienNuocApp());
}
//khi cần dùng status gọi lệnh sau 
// final statuses = StatusCache.statuses;