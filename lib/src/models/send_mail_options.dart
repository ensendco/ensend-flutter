import 'package:meta/meta.dart';

/// Optional settings for a transactional email send.
@immutable
class SendMailOptions {
  /// Audience group reference. When provided, each successfully delivered
  /// recipient is added to the specified audience group.
  final String? acquiringAudience;

  const SendMailOptions({this.acquiringAudience});

  Map<String, dynamic> toJson() => {
        if (acquiringAudience != null) 'acquiringAudience': acquiringAudience,
      };

  SendMailOptions copyWith({String? acquiringAudience}) => SendMailOptions(
        acquiringAudience: acquiringAudience ?? this.acquiringAudience,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendMailOptions && acquiringAudience == other.acquiringAudience;

  @override
  int get hashCode => acquiringAudience.hashCode;
}
