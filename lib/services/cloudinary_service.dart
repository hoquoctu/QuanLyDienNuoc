import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static Future<String?> uploadBillImage({
    required File imageFile,
    required String tenantName,
  }) async {
    final now = DateTime.now();

    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();

    final initials = tenantName
        .trim()
        .split(' ')
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    final fileName =
        '${initials}_${month}_${year}_${DateTime.now().millisecondsSinceEpoch}';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/dpndx8uik/image/upload',
    );

    var request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = 'Room_Zy_upload'
      ..fields['folder'] = 'Room_Zy/bills'
      ..fields['public_id'] = fileName
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

    final response = await request.send();

    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(body);

      return json['secure_url'];
    }

    print(body);

    return null;
  }

  /// Upload ảnh đính kèm trong review/comment của tenant.
  /// Lưu vào folder Room_Zy/comment trên Cloudinary.
  static Future<String?> uploadReviewImage({
    required File imageFile,
    required String tenantId,
  }) async {
    final fileName = '${tenantId}_${DateTime.now().millisecondsSinceEpoch}';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/dpndx8uik/image/upload',
    );

    var request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = 'Room_Zy_upload'
      ..fields['folder'] = 'Room_Zy/comment'
      ..fields['public_id'] = fileName
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

    final response = await request.send();

    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(body);

      return json['secure_url'];
    }

    print(body);

    return null;
  }
}
