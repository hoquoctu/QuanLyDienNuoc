import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String?> uploadToCloudinary(File imageFile, {String folder = 'Room_Zy/avatar'}) async {
  final uri = Uri.parse(
    'https://api.cloudinary.com/v1_1/dpndx8uik/image/upload',
  );

  var request = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = 'Room_Zy_upload'
    ..fields['folder'] = folder
    ..files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

  final response = await request.send();

  final body = await response.stream.bytesToString();

  print(body);

  if (response.statusCode == 200) {
    final json = jsonDecode(body);

    return json['secure_url'];
  }

  return null;
}