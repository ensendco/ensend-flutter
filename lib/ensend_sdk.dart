/// The official Dart SDK for the Ensend multi-channel notification platform.
///
/// ## Quick start
///
/// ```dart
/// import 'package:ensend_sdk/ensend_sdk.dart';
///
/// // Default (package:http)
/// final ensend = EnsendClient(secret: 'your_project_secret');
///
/// // With Dio
/// final ensend = EnsendClient.withDio(secret: 'your_project_secret');
///
/// // With debug logging
/// final ensend = EnsendClient(secret: 'sk_...', enableLogging: true);
///
/// final result = await ensend.send.sendMail(
///   SendMailRequest(
///     subject: 'Welcome!',
///     sender: EmailSender(address: 'hello@acme.com', name: 'Acme'),
///     recipients: [EmailRecipient(address: 'user@example.com', name: 'Alice')],
///     message: '<h1>Welcome, Alice!</h1>',
///   ),
/// );
///
/// result.when(
///   onSuccess: (data) => print('Sent!'),
///   onError: (error) => print('Error: ${error.message}'),
/// );
/// ```
library ensend_sdk;

export 'src/client.dart';
export 'src/api/send_api.dart';
export 'src/http/ensend_http_client.dart';
export 'src/dio/ensend_dio_client.dart';
