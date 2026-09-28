import 'package:meta/meta.dart';

/// Controls what happens when a recipient already exists in the target audience.
enum ActionOnExisting {
  /// Keep the existing value unchanged.
  preserve,

  /// Overwrite the existing value with the new one.
  override,
}

/// Configuration for an audience-group broadcast source.
@immutable
class AudienceSourceConfig {
  /// The audience group reference identifier.
  final String ref;

  /// Action when the recipient has an existing trait. Defaults to [ActionOnExisting.preserve].
  final ActionOnExisting actionOnExistingTrait;

  /// Action when a matching profile already exists. Defaults to [ActionOnExisting.preserve].
  final ActionOnExisting actionOnExistingProfile;

  /// Whether to include recipients who have unsubscribed. Defaults to false.
  final bool includeUnsubscribed;

  const AudienceSourceConfig({
    required this.ref,
    this.actionOnExistingTrait = ActionOnExisting.preserve,
    this.actionOnExistingProfile = ActionOnExisting.preserve,
    this.includeUnsubscribed = false,
  });

  Map<String, dynamic> toJson() => {
        'ref': ref,
        'actionOnExistingTrait': actionOnExistingTrait.name,
        'actionOnExistingProfile': actionOnExistingProfile.name,
        'includeUnsubscribed': includeUnsubscribed,
      };
}

/// Configuration for a CSV file broadcast source.
@immutable
class CsvSourceConfig {
  /// A label applied to all recipients loaded from this CSV.
  final String label;

  /// A publicly accessible URL to the CSV file. Must support byte-range
  /// downloads (e.g. Amazon S3, Cloudflare R2).
  final String url;

  /// Maps CSV column headers to Ensend broadcast trait names.
  /// Example: `{'Email': 'address', 'First Name': 'firstName'}`.
  final Map<String, String> columnMappings;

  const CsvSourceConfig({
    required this.label,
    required this.url,
    required this.columnMappings,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'url': url,
        'columnMappings': columnMappings,
      };
}

/// A source of recipients for a broadcast send.
///
/// Use [BroadcastSource.audience] to pull recipients from a saved Ensend
/// audience group, or [BroadcastSource.csv] to load them from a CSV file.
sealed class BroadcastSource {
  const BroadcastSource();

  Map<String, dynamic> toJson();

  /// Creates an audience-group source.
  factory BroadcastSource.audience(AudienceSourceConfig config) =
      _AudienceBroadcastSource;

  /// Creates a CSV file source.
  factory BroadcastSource.csv(CsvSourceConfig config) = _CsvBroadcastSource;
}

final class _AudienceBroadcastSource extends BroadcastSource {
  final AudienceSourceConfig config;
  const _AudienceBroadcastSource(this.config);

  @override
  Map<String, dynamic> toJson() => {'config': config.toJson()};
}

final class _CsvBroadcastSource extends BroadcastSource {
  final CsvSourceConfig config;
  const _CsvBroadcastSource(this.config);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'CSV',
        'config': config.toJson(),
      };
}
