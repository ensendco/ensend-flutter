# Changelog

All notable changes to this package will be documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.1.1] - 2026-09-28

Merge pull request #2 from ensendco/develop

Develop

---

## [0.1.0] - 2026-09-28

### Added

- **`EnsendClient`** — main entry point with injectable `http.Client` for testing.
- **`SendApi`** — three methods covering the full Ensend Send API:
  - `sendMail` — transactional email to up to 10 recipients (`POST /send/mail`)
  - `sendBroadcast` — new broadcast campaign to up to 250 recipients (`POST /send/mail/broadcast`)
  - `sendBroadcastBatch` — append a batch to an existing broadcast
- **Models** — fully immutable, `copyWith`-enabled, and `toJson`-ready:
  - `EmailSender`, `EmailRecipient`, `EmailTemplate`, `EmailAttachment`
  - `SendMailRequest`, `SendMailOptions`
  - `BroadcastMailRequest`, `BroadcastBatchRequest`, `BroadcastOptions`
  - `BroadcastSource` (sealed: `audience`, `csv`), `AudienceSourceConfig`, `CsvSourceConfig`
  - `EnsendResponse<T>` with `.when()` pattern
  - `EnsendError`
- **`EnsendSmtpConfig`** — helper that exposes Ensend SMTP server settings (host, port, username, password) for use with third-party SMTP libraries.
- **Exception hierarchy** (`sealed class EnsendException`):
  - `EnsendValidationException` — pre-flight request validation
  - `EnsendNetworkException` — connectivity failures
  - `EnsendTimeoutException` — request timeout
  - `EnsendSerializationException` — JSON parse failures
- **54 unit tests** covering models, validation, HTTP serialization, API response handling, and mock-based network scenarios.
