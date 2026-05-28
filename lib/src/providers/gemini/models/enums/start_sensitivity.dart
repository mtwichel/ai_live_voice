/// Sensitivity for detecting the start of user speech.
enum StartSensitivity {
  /// High sensitivity - more likely to detect speech start.
  ///
  /// May result in more false positives (detecting non-speech as speech).
  high('START_SENSITIVITY_HIGH'),

  /// Low sensitivity - less likely to detect speech start.
  ///
  /// May result in more false negatives (missing actual speech start).
  low('START_SENSITIVITY_LOW');

  const StartSensitivity(this.value);

  /// The JSON value.
  final String value;

  /// Creates from JSON value.
  ///
  /// Accepts official Live API names (`START_SENSITIVITY_*`) and legacy
  /// shorthand (`HIGH` / `LOW`) for backward compatibility.
  static StartSensitivity fromJson(String json) {
    return switch (json) {
      'START_SENSITIVITY_HIGH' || 'HIGH' => StartSensitivity.high,
      'START_SENSITIVITY_LOW' || 'LOW' => StartSensitivity.low,
      _ => throw FormatException('Unknown StartSensitivity: $json'),
    };
  }

  /// Converts to JSON value.
  String toJson() => value;
}
