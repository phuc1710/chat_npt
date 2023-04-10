import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<String> getResponse(String prompt) async {
  final apiKey = dotenv.env['API_KEY'];
  var response = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: prompt,
  );

  if (response.statusCode == 200) {
    var jsonResponse = json.decode(response.body);
    var botResponse =
        jsonResponse['choices'][0]['message']['content'].toString().trim();
    return botResponse;
  } else {
    throw Exception('Failed to load response');
  }
}

String getRequestBody(List<String> messages) {
  var requestBody = '{ "model": "gpt-3.5-turbo", "messages": [';
  for (int i = 0; i < messages.length; i++) {
    if (i & 1 == 1) {
      requestBody +=
          '{ "role": "assistant", "content": ${jsonEncode(messages[i])} }';
    } else {
      requestBody +=
          '{ "role": "user", "content": ${jsonEncode(messages[i])} }';
    }
    if (i < messages.length - 1) {
      requestBody += ',';
    }
  }
  requestBody += ']}';
  return requestBody;
}
