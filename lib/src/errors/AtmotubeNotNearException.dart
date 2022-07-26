import 'package:atmotuber/src/errors/AtmotubeException.dart';

/// [AtmotubeNotNearException] is a class that implements the
/// [AtmotubeExceptionType.NOT_NEAR] exception.
class AtmotubeNotNearException extends AtmotubeException {
  /// Default [AtmotubeNotNearException] constructor.
  AtmotubeNotNearException({
    AtmotubeExceptionType? type,
    String? message,
  }) : super(type: AtmotubeExceptionType.NOT_NEAR, message: message);

  @override
  String toString() {
    return 'AtmotubeException [$type]: $message';
  } // toString
} // AtmotubeNotNearException