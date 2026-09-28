import 'package:meta/meta.dart';

/// Optional settings for a broadcast email send.
@immutable
class BroadcastOptions {
  /// Schedule the broadcast for a future UTC timestamp.
  /// When null the broadcast is sent immediately.
  final DateTime? scheduleFor;

  /// Audience group reference. Delivered recipients are added to this group.
  final String? acquiringAudience;

  const BroadcastOptions({this.scheduleFor, this.acquiringAudience});

  Map<String, dynamic> toJson() => {
        if (scheduleFor != null)
          'scheduleFor': scheduleFor!.toUtc().toIso8601String(),
        if (acquiringAudience != null) 'acquiringAudience': acquiringAudience,
      };

  BroadcastOptions copyWith({
    DateTime? scheduleFor,
    String? acquiringAudience,
  }) =>
      BroadcastOptions(
        scheduleFor: scheduleFor ?? this.scheduleFor,
        acquiringAudience: acquiringAudience ?? this.acquiringAudience,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BroadcastOptions &&
          scheduleFor == other.scheduleFor &&
          acquiringAudience == other.acquiringAudience;

  @override
  int get hashCode => Object.hash(scheduleFor, acquiringAudience);
}
