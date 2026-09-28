import 'package:meta/meta.dart';

import 'ensend_error.dart';

/// The result envelope returned by every Ensend API call.
///
/// Either [data] or [error] will be non-null, never both.
///
/// ```dart
/// final result = await client.send.sendMail(request);
/// if (result.isSuccess) {
///   print(result.data);
/// } else {
///   print(result.error!.message);
/// }
/// ```
@immutable
class EnsendResponse<T> {
  /// The parsed response body on success.
  final T? data;

  /// The API error on failure.
  final EnsendError? error;

  const EnsendResponse({this.data, this.error})
      : assert(
          (data != null) != (error != null),
          'Exactly one of data or error must be provided',
        );

  const EnsendResponse.success(T data) : this(data: data);
  const EnsendResponse.failure(EnsendError error) : this(error: error);

  bool get isSuccess => data != null;
  bool get isError => error != null;

  /// Runs [onSuccess] if successful, [onError] on failure.
  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(EnsendError error) onError,
  }) {
    if (isSuccess) return onSuccess(data as T);
    return onError(error!);
  }

  @override
  String toString() => isSuccess
      ? 'EnsendResponse.success($data)'
      : 'EnsendResponse.failure($error)';
}
