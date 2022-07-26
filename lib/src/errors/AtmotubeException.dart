/// An enumerator defining the possible types of [AtmotubeException].
enum AtmotubeExceptionType {
  /// It occurs when the Atmotube Pro is not near and not found
  NOT_NEAR,

  /// It occurs when the Atmotube Pro is not connected and some actions are triggered
  NOT_CONNECTED,

  /// Default error type.
  DEFAULT,
} // AtmotubeExceptionType

/// [AtmotubeException] is a class defining an [Exception] that
/// can be thrown by atmotuber.
class AtmotubeException implements Exception {
  /// The [AtmotubeException] method.
  String? message;

  /// The type of the [AtmotubeException].
  AtmotubeExceptionType type;

  /// Default [AtmotubeException] constructor.
  AtmotubeException(
      {this.message = '', this.type = AtmotubeExceptionType.DEFAULT});

  /// Returns the string representation of this object.
  String toString();
} // AtmotubeException