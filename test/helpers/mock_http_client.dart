import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

/// Returns a 200 response with [body] encoded as JSON.
http.Response successResponse(Map<String, dynamic> body) {
  return http.Response(jsonEncode(body), 200, headers: {
    'content-type': 'application/json',
  });
}

/// Returns a response with [statusCode] and [body] encoded as JSON.
http.Response errorResponse(int statusCode, Map<String, dynamic> body) {
  return http.Response(jsonEncode(body), statusCode, headers: {
    'content-type': 'application/json',
  });
}

/// Stubs [client] to respond to any POST with [response].
void whenPost(MockHttpClient client, http.Response response) {
  when(
    () => client.post(any(),
        headers: any(named: 'headers'), body: any(named: 'body')),
  ).thenAnswer((_) async => response);
}

/// Stubs [client] to throw [exception] on any POST.
void whenPostThrows(MockHttpClient client, Exception exception) {
  when(
    () => client.post(any(),
        headers: any(named: 'headers'), body: any(named: 'body')),
  ).thenThrow(exception);
}

/// Captures the last POST request body as a decoded map.
Map<String, dynamic> capturePostBody(MockHttpClient client) {
  final captured = verify(
    () => client.post(
      any(),
      headers: any(named: 'headers'),
      body: captureAny(named: 'body'),
    ),
  ).captured;
  return jsonDecode(captured.last as String) as Map<String, dynamic>;
}
