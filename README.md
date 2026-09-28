# ensend_sdk

The official Dart/Flutter SDK for [Ensend](https://docs.ensend.co) — a multi-channel notification and messaging platform. Supports transactional email, email broadcasts, and SMTP relay configuration.

[![pub package](https://img.shields.io/pub/v/ensend_sdk.svg)](https://pub.dev/packages/ensend_sdk)
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
| Mockable HTTP client for unit testing | ✅ |

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ensend_sdk: ^0.1.0
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
import 'package:ensend_sdk/ensend_sdk.dart';

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

## API Reference

### `EnsendClient`

The main entry point. Create once at startup and reuse throughout your app.

```dart
final ensend = EnsendClient(
  secret: 'your_project_secret',
  baseUrl: 'https://api.ensend.co', // default
  timeout: Duration(seconds: 30),   // default
);
```

| Parameter | Type | Description |
|---|---|---|
| `secret` | `String` | **Required.** Your live or sandbox project secret. |
| `baseUrl` | `String` | API base URL. Override in tests. |
| `timeout` | `Duration` | Per-request timeout (default 30 s). |
| `httpClient` | `http.Client?` | Inject a custom client for testing/proxying. |

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

```dart
// Attach from a public URL
EmailAttachment.fromUrl(
  name: 'invoice.pdf',
  url: 'https://cdn.acme.com/invoices/inv-1042.pdf',
)

// Attach from base64-encoded content
EmailAttachment.fromContent(
  name: 'receipt.pdf',
  content: base64Encode(pdfBytes),
)
```

---

### Handling responses

Every API call returns `EnsendResponse<Map<String, dynamic>>`. Use `.when()` for exhaustive handling:

```dart
result.when(
  onSuccess: (data) {
    // data is Map<String, dynamic> with the API response
    final id = data['id'] as String?;
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

```dart
try {
  final result = await ensend.send.sendMail(request);
  // handle result.data / result.error
} on EnsendValidationException catch (e) {
  print('Fix your request: ${e.message}');
} on EnsendNetworkException catch (e) {
  print('Network error: ${e.message}');
} on EnsendTimeoutException catch (e) {
  print('Timed out: ${e.message}');
}
```

---

### SMTP relay

Use Ensend's SMTP server with any SMTP-compatible library.

```dart
final smtp = ensend.smtpConfig(
  publicKey: 'your_public_key',
  ssl: false, // false = STARTTLS on port 587; true = SSL on port 465
);

print(smtp.host);      // smtp.ensend.co
print(smtp.port);      // 587
print(smtp.username);  // your_public_key
print(smtp.password);  // your_project_secret (from EnsendClient)
print(smtp.toMap());   // {"host": ..., "port": ..., "auth": {...}}
```

---

## Testing

The SDK is built to be easily testable. Inject a mock `http.Client` to intercept all HTTP calls without hitting the network:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:ensend_sdk/ensend_sdk.dart';
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

Run the SDK's own test suite:

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
