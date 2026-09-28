import '../http/ensend_http_client.dart';
import '../models/broadcast_batch_request.dart';
import '../models/broadcast_mail_request.dart';
import '../models/ensend_error.dart';
import '../models/ensend_response.dart';
import '../models/send_mail_request.dart';

/// Provides access to the Ensend Send API for transactional email and
/// broadcast messaging.
///
/// Do not instantiate directly — access it through [EnsendClient.send].
class SendApi {
  final EnsendHttpClient _http;

  SendApi(this._http);

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
    return _execute(() => _http.post('/send/mail', request.toJson()));
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
      () => _http.post('/send/mail/broadcast', request.toJson()),
    );
  }

  Future<EnsendResponse<Map<String, dynamic>>> _execute(
    Future<Map<String, dynamic>> Function() call,
  ) async {
    final body = await call();

    // The API returns HTTP 4xx/5xx bodies as JSON with error details.
    // The HTTP layer always returns the parsed body regardless of status code;
    // we detect errors by the presence of an 'error' or 'message' key when
    // 'data' is absent.
    if (body.containsKey('data')) {
      return EnsendResponse.success(
          body['data'] as Map<String, dynamic>? ?? body);
    }

    if (body.containsKey('error') || body.containsKey('message')) {
      final statusCode = body['statusCode'] as int? ?? 400;
      return EnsendResponse.failure(
        EnsendError.fromJson(body, statusCode),
      );
    }

    // Treat the whole body as success data when the API omits an envelope.
    return EnsendResponse.success(body);
  }
}
