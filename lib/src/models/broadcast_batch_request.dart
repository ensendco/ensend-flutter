import 'package:meta/meta.dart';

import '../exceptions.dart';
import 'broadcast_source.dart';
import 'email_recipient.dart';

/// Request payload for sending a subsequent batch to an existing broadcast.
///
/// Obtain [broadcastRef] from the initial [BroadcastMailRequest] response or
/// from the Ensend project dashboard.
///
/// ```dart
/// final batchRequest = BroadcastBatchRequest(
///   broadcastRef: 'bcast_abc123',
///   recipients: [
///     EmailRecipient(address: 'charlie@example.com'),
///   ],
/// );
/// ```
@immutable
class BroadcastBatchRequest {
  static const int _maxRecipients = 250;

  /// The identifier of an existing broadcast to append recipients to.
  final String broadcastRef;

  /// Inline recipient list for this batch. Maximum 250.
  final List<EmailRecipient>? recipients;

  /// External recipient sources for this batch.
  final List<BroadcastSource>? sources;

  const BroadcastBatchRequest({
    required this.broadcastRef,
    this.recipients,
    this.sources,
  });

  void validate() {
    if (broadcastRef.isEmpty) {
      throw const EnsendValidationException('broadcastRef must not be empty');
    }
    if ((recipients == null || recipients!.isEmpty) &&
        (sources == null || sources!.isEmpty)) {
      throw EnsendValidationException(
        'Either recipients or sources must be provided',
      );
    }
    if (recipients != null && recipients!.length > _maxRecipients) {
      throw EnsendValidationException(
        'BroadcastBatchRequest supports at most $_maxRecipients recipients per batch.',
      );
    }
  }

  Map<String, dynamic> toJson() {
    validate();
    return {
      'broadcastRef': broadcastRef,
      if (recipients != null && recipients!.isNotEmpty)
        'recipients': recipients!.map((r) => r.toJson()).toList(),
      if (sources != null && sources!.isNotEmpty)
        'sources': sources!.map((s) => s.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'BroadcastBatchRequest(ref: $broadcastRef, recipients: ${recipients?.length ?? 0})';
}
