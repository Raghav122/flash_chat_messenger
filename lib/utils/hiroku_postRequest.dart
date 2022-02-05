import 'package:http/http.dart' as http;
import 'dart:convert';

String url = '';

Future fcmNotification(String message, String from, String tokens) async {
  Map<String, String> headers = {"Content-type": "application/json"};
  final body = jsonEncode({"message": message, "from": from, "tokens": tokens});

  http.Response response =
      await http.post(Uri.parse(url), body: body, headers: headers);

  if (response.statusCode == 200) {
    return;
  } else {
    print(response.body);
  }
}
