import '../copy_with_sentinel.dart';
import 'function_declaration.dart';

/// Tool that the model may use to generate a response.
///
/// For Live voice, only [functionDeclarations] are supported in this package.
class Tool {
  /// List of function declarations.
  final List<FunctionDeclaration>? functionDeclarations;

  /// Creates a [Tool] with [functionDeclarations] only.
  const Tool({this.functionDeclarations});

  /// Creates a [Tool] from JSON.
  factory Tool.fromJson(Map<String, dynamic> json) => Tool(
    functionDeclarations: json['functionDeclarations'] != null
        ? (json['functionDeclarations'] as List)
              .map(
                (e) => FunctionDeclaration.fromJson(e as Map<String, dynamic>),
              )
              .toList()
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (functionDeclarations != null)
      'functionDeclarations': functionDeclarations!
          .map((e) => e.toJson())
          .toList(),
  };

  /// Creates a copy with replaced values.
  Tool copyWith({Object? functionDeclarations = unsetCopyWithValue}) {
    return Tool(
      functionDeclarations: functionDeclarations == unsetCopyWithValue
          ? this.functionDeclarations
          : functionDeclarations as List<FunctionDeclaration>?,
    );
  }
}
