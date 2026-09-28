# ensend_flutter

The official Dart/Flutter SDK for [Ensend](https://docs.ensend.co) — a multi-channel notification and messaging platform. Supports transactional email, email broadcasts, and SMTP relay configuration.

[![pub package](https://img.shields.io/pub/v/ensend_flutter.svg)](https://pub.dev/packages/ensend_flutter)
[![Dart SDK](https://img.shields.io/badge/dart-%3E%3D3.0.0-blue)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Features

| Capability | Status |
|---|---|
| Transactional email (up to 10 recipients) | ✅ |
| Email broadcasts (up to 250 recipients/batch) | ✅ |
| Template-based sending with variable substitution | ✅ |
| File attachments (URL or base64) | ✅ |
| Broadcast scheduling (`scheduleFor`) | ✅ |
| CSV and audience-group broadcast sources | ✅ |
| SMTP relay configuration helper | ✅ |
| Typed response model with `.when()` pattern | ✅ |
| `package:http` transport (default) | ✅ |
| `package:dio` transport with interceptor support | ✅ |
| Pluggable `EnsendHttpAdapter` for custom transports | ✅ |
| Levelled, colour-coded logging via `package:logger` | ✅ |
| Mockable adapters for unit testing | ✅ |
| Sealed `EmailAttachment` (exhaustive switch support) | ✅ |
| `SmtpEncryption` enum (port + TLS mode in one place) | ✅ |
| `JsonMapX` / `ObjectCoercionX` parser extensions | ✅ |
| Sealed `EnsendException` (exhaustive switch support) | ✅ |

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ensend_flutter: ^0.1.0
```

Then run:

```sh
dart pub get
# or
flutter pub get
```

---

## Quick start

```dart
import 'package:ensend_flutter/ensend_flutter.dart';

void main() async {
  final ensend = EnsendClient(secret: 'your_project_secret');

  final result = await ensend.send.sendMail(
    SendMailRequest(
      subject: 'Welcome aboard!',
      sender: EmailSender(address: 'hello@acme.com', name: 'Acme'),
      recipients: [
        EmailRecipient(address: 'user@example.com', name: 'Alice'),
      ],
      message: '<h1>Welcome, Alice!</h1><p>We are glad you joined.</p>',
    ),
  );

  result.when(
    onSuccess: (data) => print('Email sent! $data'),
    onError: (error) => print('Error ${error.statusCode}: ${error.message}'),
  );

  ensend.close();
}
```

---

## Authentication

Get your credentials from the Ensend dashboard under **Workspace → Project → Credentials**.

| Key type | Use | Client-safe? |
|---|---|---|
| **Live Secret** | Production sends | No |
| **Sandbox Secret** | Development/testing — not delivered | No |
| **Public Key** | SMTP username only | Yes |

```dart
// Production
final ensend = EnsendClient(secret: 'sk_live_...');

// Development (messages not delivered, free)
final ensend = EnsendClient(secret: 'sk_sandbox_...');
```

> **Security:** Never expose secrets in client-side Flutter code or public repositories. Use server-side Dart or environment variables.

---

## Choosing an HTTP transport

The SDK ships two fully-tested HTTP adapters. Both implement the same `EnsendHttpAdapter` interface, so you can swap them without changing any application code.

### Default: `package:http`

The out-of-the-box choice. No extra setup needed:

```dart
final ensend = EnsendClient(secret: 'sk_...');
```

### Dio: `package:dio`

Use `EnsendClient.withDio` for richer middleware support — retry policies, certificate pinning, response caching, or observability interceptors:

```dart
// Minimal — creates a clean Dio instance internally
final ensend = EnsendClient.withDio(secret: 'sk_...');

// Advanced — bring your own Dio with interceptors pre-attached
import 'package:dio/dio.dart';

final dio = Dio()
  ..interceptors.add(LogInterceptor(responseBody: true))
  ..interceptors.add(RetryInterceptor(dio: dio, retries: 3));

final ensend = EnsendClient.withDio(secret: 'sk_...', dio: dio);
```

The SDK **never mutates** your Dio instance's base options. Authentication headers and timeouts are injected per-request via `Options`, so your existing interceptor chain is untouched.

### Custom transport: `EnsendClient.withAdapter`

Implement `EnsendHttpAdapter` to plug in any HTTP backend — useful for advanced proxy setups, integration tests against a fake server, or non-standard environments:

```dart
class MyCustomAdapter implements EnsendHttpAdapter {
  @override
  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    // your transport logic
  }

  @override
  void close() { /* clean up */ }
}

final ensend = EnsendClient.withAdapter(
  secret: 'sk_...',
  adapter: MyCustomAdapter(),
);
```

---

## API Reference

### `EnsendClient` factory constructors

#### `EnsendClient({...})` — `package:http` backend

```dart
final ensend = EnsendClient(
  secret: 'your_project_secret',      // required
  baseUrl: 'https://api.ensend.co',   // default
  timeout: Duration(seconds: 30),     // default
  enableLogging: false,               // default — see Logging section
  logger: null,                       // inject a custom Logger instance
  httpClient: null,                   // inject an http.Client for testing
);
```

| Parameter | Type | Description |
|---|---|---|
| `secret` | `String` | **Required.** Live or sandbox project secret. |
| `baseUrl` | `String` | API base URL. Override to point at a local stub server in tests. |
| `timeout` | `Duration` | Per-request timeout (default 30 s). |
| `enableLogging` | `bool` | Enable debug output via `package:logger` (default `false`). |
| `logger` | `Logger?` | Custom `Logger` from `package:logger`. Uses `PrettyPrinter` when omitted. |
| `httpClient` | `http.Client?` | Inject a custom client for testing or proxying. |

#### `EnsendClient.withDio({...})` — `package:dio` backend

```dart
final ensend = EnsendClient.withDio(
  secret: 'your_project_secret',
  baseUrl: 'https://api.ensend.co',
  timeout: Duration(seconds: 30),
  enableLogging: false,
  logger: null,   // inject a custom Logger instance
  dio: null,      // inject a pre-configured Dio instance
);
```

| Parameter | Type | Description |
|---|---|---|
| `secret` | `String` | **Required.** Live or sandbox project secret. |
| `baseUrl` | `String` | API base URL. |
| `timeout` | `Duration` | Per-request timeout (default 30 s). |
| `enableLogging` | `bool` | Enable debug output via `package:logger` (default `false`). |
| `logger` | `Logger?` | Custom `Logger` from `package:logger`. |
| `dio` | `Dio?` | Pre-configured Dio instance. A fresh one is created when omitted. |

#### `EnsendClient.withAdapter({...})` — custom transport

```dart
final ensend = EnsendClient.withAdapter(
  secret: 'your_project_secret',
  adapter: myAdapter,                // required — your EnsendHttpAdapter
  baseUrl: 'https://api.ensend.co',
  timeout: Duration(seconds: 30),
  enableLogging: false,
);
```

---

### Sending transactional email

**Endpoint:** `POST /send/mail` — up to **10 recipients** per call.

```dart
final result = await ensend.send.sendMail(
  SendMailRequest(
    subject: 'Your order is confirmed',
    sender: EmailSender(address: 'orders@acme.com', name: 'Acme Orders'),
    recipients: [
      EmailRecipient(
        address: 'customer@example.com',
        name: 'Jane',
        variables: {'orderNumber': '#1042', 'total': '\$99.00'},
      ),
    ],
    template: EmailTemplate(
      ref: 'order-confirmation',
      variables: {'supportEmail': 'help@acme.com'},
    ),
    replyAddress: 'support@acme.com',
    preheader: 'Your order #1042 is on its way!',
  ),
);
```

#### `SendMailRequest` fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `subject` | `String` | Yes | |
| `sender` | `EmailSender` | Yes | Must be a verified sender identity |
| `recipients` | `List<EmailRecipient>` | Yes | Max 10 |
| `message` | `String?` | One of | Raw HTML or plain text body |
| `template` | `EmailTemplate?` | One of | Saved template reference |
| `preheader` | `String?` | No | Inbox preview text |
| `replyAddress` | `String?` | No | Where replies go |
| `attachments` | `List<EmailAttachment>?` | No | |
| `options` | `SendMailOptions?` | No | Audience acquisition |

---

### Sending email broadcasts

**Endpoint:** `POST /send/mail/broadcast` — up to **250 recipients per batch**.

#### Initial broadcast

```dart
final result = await ensend.send.sendBroadcast(
  BroadcastMailRequest(
    subject: 'Our October newsletter',
    sender: EmailSender(address: 'news@acme.com', name: 'Acme Newsletter'),
    recipients: firstBatch, // List<EmailRecipient>
    message: '<h1>This month at Acme</h1>...',
    options: BroadcastOptions(
      scheduleFor: DateTime.utc(2025, 10, 1, 9, 0), // 09:00 UTC
    ),
  ),
);

final broadcastRef = result.data!['broadcastRef'] as String;
```

#### Subsequent batches

```dart
await ensend.send.sendBroadcastBatch(
  BroadcastBatchRequest(
    broadcastRef: broadcastRef,
    recipients: nextBatch,
  ),
);
```

#### `BroadcastMailRequest` fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `subject` | `String` | Yes | |
| `sender` | `EmailSender` | Yes | |
| `recipients` | `List<EmailRecipient>?` | One of | Max 250 per batch |
| `sources` | `List<BroadcastSource>?` | One of | Audience groups or CSV files |
| `message` | `String?` | One of | |
| `template` | `EmailTemplate?` | One of | |
| `preheader` | `String?` | No | |
| `replyAddress` | `String?` | No | |
| `attachments` | `List<EmailAttachment>?` | No | |
| `options` | `BroadcastOptions?` | No | Scheduling + audience acquisition |

---

### Using broadcast sources

#### Audience group source

```dart
BroadcastSource.audience(
  AudienceSourceConfig(
    ref: 'vip-customers',
    actionOnExistingTrait: ActionOnExisting.preserve,
    actionOnExistingProfile: ActionOnExisting.override,
    includeUnsubscribed: false,
  ),
)
```

#### CSV file source

```dart
BroadcastSource.csv(
  CsvSourceConfig(
    label: 'promo-oct-2025',
    url: 'https://your-bucket.s3.amazonaws.com/subscribers.csv',
    columnMappings: {
      'Email': 'address',
      'First Name': 'firstName',
      'Plan': 'plan',
    },
  ),
)
```

The CSV URL must support byte-range requests (e.g. Amazon S3, Cloudflare R2).

---

### Templates and variables

Use `{{variableName}}` in your saved Ensend templates.

```dart
SendMailRequest(
  subject: 'Hello {{recipient.firstName}}!',
  sender: EmailSender(address: 'hello@acme.com'),
  recipients: [
    EmailRecipient(
      address: 'alice@example.com',
      name: 'Alice',
      variables: {'plan': 'Pro', 'trialDays': '14'},
    ),
    EmailRecipient(
      address: 'bob@example.com',
      name: 'Bob',
      variables: {'plan': 'Free', 'trialDays': '7'},
    ),
  ],
  template: EmailTemplate(
    ref: 'welcome-email',
    variables: {'appName': 'Acme', 'supportEmail': 'help@acme.com'},
  ),
)
```

Per-recipient `variables` override global template `variables` for that recipient.

---

### File attachments

`EmailAttachment` is a **sealed class** with two concrete variants. Construct via the named factories:

```dart
// Attach from a public URL → UrlEmailAttachment
EmailAttachment.fromUrl(
  name: 'invoice.pdf',
  url: 'https://cdn.acme.com/invoices/inv-1042.pdf',
)

// Attach from base64-encoded content → ContentEmailAttachment
EmailAttachment.fromContent(
  name: 'receipt.pdf',
  content: base64Encode(pdfBytes),
)
```

Because the type is sealed you can exhaustively switch on it:

```dart
for (final att in request.attachments ?? <EmailAttachment>[]) {
  switch (att) {
    case UrlEmailAttachment(:final url):
      print('Linked: $url');
    case ContentEmailAttachment(:final content):
      print('Inline: ${content.length} bytes (base64)');
  }
}
```

---

### Handling responses

Every API call returns `EnsendResponse<Map<String, dynamic>>`. Use `.when()` for exhaustive handling:

```dart
result.when(
  onSuccess: (data) {
    // Use the built-in JsonMapX extension for safe, coercion-free access
    final id    = data.getString('id');
    final count = data.getInt('count', fallback: 0);
    final ok    = data.getBool('acknowledged');
    final meta  = data.getMap('metadata'); // Map<String, dynamic>?
  },
  onError: (error) {
    print('Status ${error.statusCode}: ${error.message}');
    // error.details has the full raw response body
  },
);

// Or check directly
if (result.isSuccess) { ... }
if (result.isError) { ... }
```

---

### Exceptions

Network and serialization errors throw instead of returning an `EnsendResponse`:

| Exception | When thrown |
|---|---|
| `EnsendValidationException` | Invalid request fields (before any HTTP call) |
| `EnsendNetworkException` | DNS failure, connection refused, etc. |
| `EnsendTimeoutException` | Request exceeded `EnsendConfig.timeout` |
| `EnsendSerializationException` | Response body could not be parsed as JSON |

Because `EnsendException` is a **sealed class**, you can exhaustively switch on its subtypes:

```dart
try {
  final result = await ensend.send.sendMail(request);
  // handle result.data / result.error
} on EnsendException catch (e) {
  switch (e) {
    case EnsendValidationException():
      print('Fix your request: ${e.message}');
    case EnsendNetworkException(:final cause):
      print('Network error: ${e.message} (caused by: $cause)');
    case EnsendTimeoutException():
      print('Timed out: ${e.message}');
    case EnsendSerializationException():
      print('Bad response body: ${e.message}');
  }
}
```

---

### SMTP relay

Use Ensend's SMTP server with any SMTP-compatible library.

#### Via `EnsendClient` (recommended)

```dart
// STARTTLS port 587 (default)
final smtp = ensend.smtpConfig(publicKey: 'your_public_key');

// Implicit TLS port 465
final smtp = ensend.smtpConfig(publicKey: 'your_public_key', ssl: true);

print(smtp.host);       // smtp.ensend.co
print(smtp.port);       // 587
print(smtp.username);   // your_public_key
print(smtp.password);   // your_project_secret (from EnsendClient)
print(smtp.toMap());    // {"host": ..., "port": ..., "auth": {...}}
```

#### Via `SmtpEncryption` enum directly

`SmtpEncryption` carries the port and TLS flag, eliminating the coupled `port + useSsl` pair:

```dart
// Construct directly using the enum
final smtp = EnsendSmtpConfig(
  publicKey: 'pk_...',
  secret: 'sk_...',
  encryption: SmtpEncryption.ssl,     // port 465, useSsl = true
  // or SmtpEncryption.starttls       // port 587, useSsl = false (default)
);

print(smtp.encryption);       // SmtpEncryption.ssl
print(smtp.port);             // derived from enum → 465
print(smtp.useSsl);           // derived from enum → true

// Switch exhaustively on the encryption mode if needed
switch (smtp.encryption) {
  case SmtpEncryption.starttls:
    print('Connect then upgrade via STARTTLS');
  case SmtpEncryption.ssl:
    print('Connect directly over TLS');
}
```

---

## Parser extensions

The SDK exports two extension groups you can use anywhere you work with JSON data — including the `data` map returned inside `EnsendResponse`.

### `JsonMapX` on `Map<String, dynamic>`

Safe, coercing key access that never throws on unexpected types:

```dart
result.when(
  onSuccess: (data) {
    // Strings
    final id   = data.getString('id');            // '' if missing
    final name = data.getStringOrNull('name');    // null if missing

    // Numbers (coerces int ↔ double ↔ String automatically)
    final count  = data.getInt('count', fallback: 0);
    final price  = data.getDouble('price', fallback: 0.0);

    // Booleans (coerces 1/0 and "true"/"false" strings)
    final active = data.getBool('active');

    // Nested objects and lists
    final meta  = data.getMap('metadata');        // Map<String, dynamic>?
    final tags  = data.getList<String>('tags');   // List<String>
    final items = data.getMapList('items');       // List<Map<String, dynamic>>

    // Presence check
    if (data.hasValue('broadcastRef')) { ... }
  },
  onError: (e) => print(e.message),
);
```

### `ObjectCoercionX` on `Object?`

Type-safe coercion for values typed as `dynamic` or `Object?`:

```dart
final Object? raw = someExternalValue;

final s = raw.asString();          // '' if null
final n = raw.asInt(fallback: -1);
final d = raw.asDouble();
final b = raw.asBool();
final m = raw.asJsonMap();         // Map<String, dynamic>? or null
final l = raw.asListOf<String>();  // filters non-String elements
```

### `JsonStringX` on `String`

Parse raw JSON strings from HTTP response bodies:

```dart
// Throws FormatException on bad JSON or non-object top-level
final map  = responseBody.parseJsonMap();

// Returns null instead of throwing
final safe = responseBody.tryParseJsonMap();

// Number helpers
final n = '42'.toIntOrNull();       // int?
final f = '3.14'.toDoubleOrNull();  // double?
final i = 'abc'.toIntOr(0);        // 0 — fallback

// Boolean helper
final ok = 'true'.isTruthy;        // true
```

---

## Logging

The SDK uses [`package:logger`](https://pub.dev/packages/logger) for structured, levelled debug output.

### Enable with default settings

Pass `enableLogging: true` to either factory constructor. Logs are emitted using a `PrettyPrinter` with colour-coded levels, timestamps, and automatic suppression in Dart release/profile builds (via `DevelopmentFilter`):

```dart
final ensend = EnsendClient(
  secret: 'sk_...',
  enableLogging: true,
);
```

Each outgoing request and response is printed to the console at **debug** / **info** level respectively. Errors are printed at **error** level with their stack trace. Base64 attachment content is automatically truncated to prevent megabyte-sized log output.

Sample output:

```
💙 [EnsendSDK] → POST https://api.ensend.co/send/mail
    {
      "subject": "Welcome!",
      "sender": { "address": "hello@acme.com" }
    }
💚 [EnsendSDK] ← 200
    { "data": { "id": "msg_abc123" } }
```

### Inject a custom `Logger`

Supply any `Logger` from `package:logger` to change the printer, filter, or output destination:

```dart
import 'package:logger/logger.dart';

// Plain text output — great for structured log aggregators
final ensend = EnsendClient(
  secret: 'sk_...',
  enableLogging: true,
  logger: Logger(printer: SimplePrinter()),
);

// Write to a file
final ensend = EnsendClient.withDio(
  secret: 'sk_...',
  enableLogging: true,
  logger: Logger(
    printer: SimplePrinter(),
    output: FileOutput(file: File('ensend.log')),
  ),
);

// Keep logs enabled in release builds (opt-in — use with care)
final ensend = EnsendClient(
  secret: 'sk_...',
  enableLogging: true,
  logger: Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(methodCount: 0),
  ),
);
```

> The `logger` parameter has no effect when `enableLogging` is `false`. You must set both to see output.

---

## Testing

### Approach 1 — inject a mock `http.Client`

Use `mocktail` to stub the underlying `http.Client` without touching the network:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:ensend_flutter/ensend_flutter.dart';
import 'package:test/test.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://api.ensend.co'));
  });

  test('sendMail returns success', () async {
    final mockHttp = MockHttpClient();
    final client = EnsendClient(secret: 'sk_test', httpClient: mockHttp);

    when(
      () => mockHttp.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        jsonEncode({'data': {'id': 'msg_1'}}),
        200,
      ),
    );

    final result = await client.send.sendMail(
      SendMailRequest(
        subject: 'Test',
        sender: EmailSender(address: 'test@acme.com'),
        recipients: [EmailRecipient(address: 'user@example.com')],
        message: 'Hello',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.data!['id'], 'msg_1');

    client.close();
  });
}
```

### Approach 2 — inject a mock `EnsendHttpAdapter`

Mock the transport abstraction directly. This works for both the `package:http` and `package:dio` adapters and is the recommended approach for testing at the API layer:

```dart
import 'package:mocktail/mocktail.dart';
import 'package:ensend_flutter/ensend_flutter.dart';
import 'package:test/test.dart';

class MockEnsendHttpAdapter extends Mock implements EnsendHttpAdapter {}

void main() {
  late MockEnsendHttpAdapter adapter;
  late EnsendClient client;

  setUp(() {
    adapter = MockEnsendHttpAdapter();
    client = EnsendClient.withAdapter(
      secret: 'sk_test',
      adapter: adapter,
    );
  });

  test('sendMail delegates to adapter', () async {
    when(() => adapter.post(any(), any()))
        .thenAnswer((_) async => {'data': {'id': 'msg_1'}});

    final result = await client.send.sendMail(
      SendMailRequest(
        subject: 'Test',
        sender: EmailSender(address: 'test@acme.com'),
        recipients: [EmailRecipient(address: 'user@example.com')],
        message: 'Hello',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.data!['id'], 'msg_1');
  });
}
```

### Approach 3 — mock `Dio` for Dio-specific behaviour

```dart
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ensend_flutter/ensend_flutter.dart';
import 'package:test/test.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('DioEnsendHttpClient maps DioException to EnsendNetworkException', () async {
    final mockDio = MockDio();
    final client = EnsendClient.withDio(secret: 'sk_test', dio: mockDio);

    when(() => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/send/mail'),
      type: DioExceptionType.connectionError,
    ));

    expect(
      () => client.send.sendMail(SendMailRequest(
        subject: 'Test',
        sender: EmailSender(address: 'test@acme.com'),
        recipients: [EmailRecipient(address: 'user@example.com')],
        message: 'Hello',
      )),
      throwsA(isA<EnsendNetworkException>()),
    );
  });
}
```

Run the SDK's own test suite (77 tests, 0 warnings):

```sh
dart test
```

---

## Channels (roadmap)

| Channel | Status |
|---|---|
| Email | ✅ Available |
| SMS | Coming soon |
| WhatsApp | Coming soon |
| Push notifications | Coming soon |

---

## License

MIT — see [LICENSE](LICENSE).
