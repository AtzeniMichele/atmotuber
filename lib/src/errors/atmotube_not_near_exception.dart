import 'package:atmotuber/src/errors/atmotube_exception.dart';

/// [AtmotubeNotNearException] is a class that implements the
/// [AtmotubeExceptionType.notNEAR] exception.
class AtmotubeNotNearException extends AtmotubeException {
  /// Default [AtmotubeNotNearException] constructor.
  AtmotubeNotNearException({
    AtmotubeExceptionType? type,
    String? message,
  }) : super(type: AtmotubeExceptionType.notNEAR, message: message);

  @override
  String toString() {
    return 'AtmotubeException [$type]: $message';
  } // toString
} // AtmotubeNotNearException