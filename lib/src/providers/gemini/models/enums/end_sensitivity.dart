/// Sensitivity for detecting the end of user speech.
enum EndSensitivity {
  /// High sensitivity - more likely to detect speech end quickly.
  ///
  /// May cut off speech prematurely.
  high('END_SENSITIVITY_HIGH'),

  /// Low sensitivity - waits longer before detecting speech end.
  ///
  /// May include more silence at the end.
  low('END_SENSITIVITY_LOW');

  const EndSensitivity(this.value);

  /// The JSON value.
  final String value;

  /// Creates from JSON value.
  ///
  /// Accepts official Live API names (`END_SENSITIVITY_*`) and legacy
  /// shorthand (`HIGH` / `LOW`) for backward compatibility.
  static EndSensitivity fromJson(String json) {
    return switch (json) {
      'END_SENSITIVITY_HIGH' || 'HIGH' => EndSensitivity.high,
      'END_SENSITIVITY_LOW' || 'LOW' => EndSensitivity.low,
      _ => throw FormatException('Unknown EndSensitivity: $json'),
    };
  }

  /// Converts to JSON value.
  String toJson() => value;
}
