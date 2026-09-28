import '../http/ensend_http_adapter.dart';
import '../models/broadcast_batch_request.dart';
import '../models/broadcast_mail_request.dart';
import '../models/ensend_error.dart';
import '../models/ensend_response.dart';
import '../models/send_mail_request.dart';
import '../utils/json_ext.dart';
import '../utils/logger.dart';

/// Classifies a JSON response body by its envelope shape.
enum _Envelope {
  /// The body contains a top-level `data` key — API success.
  data,

  /// The body contains a top-level `error` or `message` key — API failure.
  error,

  /// The body has no recognised envelope — treat as success data with a warning.
  unknown,
}

_Envelope _classify(Map<String, dynamic> body) {
  if (body.containsKey('data')) return _Envelope.data;
  if (body.containsKey('error') || body.containsKey('message')) {
    return _Envelope.error;
  }
  return _Envelope.unknown;
}

/// Provides access to the Ensend Send API for transactional email and
/// broadcast messaging.
///
/// Do not instantiate directly — access it through [EnsendClient.send].
class SendApi {
  final EnsendHttpAdapter _http;
  final EnsendLogger _log;

  SendApi(this._http, {EnsendLogger? logger}) : _log = logger ?? EnsendLogger();

  /// Sends a transactional email to up to 10 recipients.
  ///
  /// **Endpoint:** `POST /send/mail`
  ///
  /// Throws [EnsendValidationException] when [request] violates any constraint
  /// (e.g. exceeds 10 recipients, missing message/template).
  /// Throws [EnsendNetworkException] or [EnsendTimeoutException] on
  /// connectivity failures.
  ///
  /// ```dart
  /// final result = await client.send.sendMail(
  ///   SendMailRequest(
  ///     subject: 'Verify your email',
  ///     sender: EmailSender(address: 'noreply@acme.com'),
  ///     recipients: [EmailRecipient(address: 'user@example.com')],
  ///     message: '<p>Click <a href="...">here</a> to verify.</p>',
  ///   ),
  /// );
  ///
  /// result.when(
  ///   onSuccess: (data) => print('Sent! $data'),
  ///   onError: (error) => print('Failed: ${error.message}'),
  /// );
  /// ```
  Future<EnsendResponse<Map<String, dynamic>>> sendMail(
    SendMailRequest request,
  ) async {
    return _execute(
      '/send/mail',
      () => _http.post('/send/mail', request.toJson()),
    );
  }

  /// Initiates a new email broadcast to up to 250 recipients per batch.
  ///
  /// **Endpoint:** `POST /send/mail/broadcast`
  ///
  /// The response [data] contains a `broadcastRef` you must pass to
  /// [sendBroadcastBatch] for subsequent batches on the same campaign.
  ///
  /// ```dart
  /// final result = await client.send.sendBroadcast(
  ///   BroadcastMailRequest(
  ///     subject: 'Monthly update',
  ///     sender: EmailSender(address: 'news@acme.com'),
  ///     recipients: recipients, // List<EmailRecipient>
  ///     message: '<h1>This month...</h1>',
  ///   ),
  /// );
  /// ```
  Future<EnsendResponse<Map<String, dynamic>>> sendBroadcast(
    BroadcastMailRequest request,
  ) async {
    return _execute(
      '/send/mail/broadcast',
      () => _http.post('/send/mail/broadcast', request.toJson()),
    );
  }

  /// Appends a subsequent batch of recipients to an existing broadcast.
  ///
  /// **Endpoint:** `POST /send/mail/broadcast`
  ///
  /// Use the `broadcastRef` from the initial [sendBroadcast] response to tie
  /// batches together under the same campaign.
  ///
  /// ```dart
  /// final result = await client.send.sendBroadcastBatch(
  ///   BroadcastBatchRequest(
  ///     broadcastRef: 'bcast_abc123',
  ///     recipients: nextBatch,
  ///   ),
  /// );
  /// ```
  Future<EnsendResponse<Map<String, dynamic>>> sendBroadcastBatch(
    BroadcastBatchRequest request,
  ) async {
    return _execute(
      '/send/mail/broadcast',
      () => _http.post('/send/mail/broadcast', request.toJson()),
    );
  }

  Future<EnsendResponse<Map<String, dynamic>>> _execute(
    String path,
    Future<Map<String, dynamic>> Function() call,
  ) async {
    final body = await call();

    // The API returns HTTP 4xx/5xx bodies as JSON with error details.
    // Both adapters return the parsed body regardless of status code so the
    // response envelope shape is consistent across http and Dio transports.
    switch (_classify(body)) {
      case _Envelope.data:
        final nested = body.getMap('data');
        if (nested == null) {
          _log.warning(
            'Response for $path has a "data" key but its value is not a JSON '
            'object (got ${body['data'].runtimeType}). Treating the whole body '
            'as success data.',
          );
        }
        return EnsendResponse.success(nested ?? body);

      case _Envelope.error:
        final rawStatus = body['statusCode'];
        if (rawStatus != null && rawStatus is! int) {
          _log.warning(
            'Response "statusCode" for $path is a ${rawStatus.runtimeType} '
            '("$rawStatus"), expected int. Coercing.',
          );
        }
        final statusCode = body.getInt('statusCode', fallback: 400);
        return EnsendResponse.failure(EnsendError.fromJson(body, statusCode));

      case _Envelope.unknown:
        _log.warning(
          'Response for $path has no recognised envelope key ("data", "error", '
          'or "message"). Treating the full body as success data.',
        );
        return EnsendResponse.success(body);
    }
  }
}
