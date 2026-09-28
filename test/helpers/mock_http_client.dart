import 'dart:convert';

import 'package:ensend_flutter/ensend_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

// ── http.Client mock ──────────────────────────────────────────────────────────

class MockHttpClient extends Mock implements http.Client {}

/// Call once in setUpAll to satisfy mocktail's Uri fallback requirement.
void registerFallbacks() {
  registerFallbackValue(Uri.parse('https://api.ensend.co'));
}

// ── EnsendHttpAdapter mock (for testing SendApi in isolation) ─────────────────

class MockEnsendHttpAdapter extends Mock implements EnsendHttpAdapter {}

// ── Response builders ─────────────────────────────────────────────────────────

/// Returns a 200 response with [body] encoded as JSON.
http.Response successResponse(Map<String, dynamic> body) => http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
    );

/// Returns a response with [statusCode] and [body] encoded as JSON.
http.Response errorResponse(int statusCode, Map<String, dynamic> body) =>
    http.Response(
      jsonEncode(body),
      statusCode,
      headers: {'content-type': 'application/json'},
    );

// ── Stub helpers (http.Client) ────────────────────────────────────────────────

/// Stubs [client] to respond to any POST with [response].
void whenPost(MockHttpClient client, http.Response response) {
  when(
    () => client.post(
      any(),
      headers: any(named: 'headers'),
      body: any(named: 'body'),
    ),
  ).thenAnswer((_) async => response);
}

/// Stubs [client] to throw [exception] on any POST.
void whenPostThrows(MockHttpClient client, Exception exception) {
  when(
    () => client.post(
      any(),
      headers: any(named: 'headers'),
      body: any(named: 'body'),
    ),
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

// ── Stub helpers (EnsendHttpAdapter mock) ─────────────────────────────────────

/// Stubs [adapter] to resolve with [body] on any POST.
void whenAdapterPost(
  MockEnsendHttpAdapter adapter,
  Map<String, dynamic> body,
) {
  when(
    () => adapter.post(any(), any()),
  ).thenAnswer((_) async => body);
}

/// Stubs [adapter] to throw [exception] on any POST.
void whenAdapterThrows(
  MockEnsendHttpAdapter adapter,
  Exception exception,
) {
  when(
    () => adapter.post(any(), any()),
  ).thenThrow(exception);
}

/// Captures the path and body of the last adapter POST call.
({String path, Map<String, dynamic> body}) captureAdapterPost(
  MockEnsendHttpAdapter adapter,
) {
  final captured = verify(
    () => adapter.post(captureAny(), captureAny()),
  ).captured;
  return (
    path: captured[0] as String,
    body: captured[1] as Map<String, dynamic>,
  );
}
