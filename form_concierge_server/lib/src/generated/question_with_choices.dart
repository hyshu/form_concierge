/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'question_type.dart' as _i2;
import 'package:form_concierge_server/src/generated/protocol.dart' as _i3;

/// DTO for creating a question with its choices in one request
abstract class QuestionWithChoices
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  QuestionWithChoices._({
    required this.text,
    required this.type,
    required this.isRequired,
    this.placeholder,
    required this.choices,
  });

  factory QuestionWithChoices({
    required String text,
    required _i2.QuestionType type,
    required bool isRequired,
    String? placeholder,
    required List<String> choices,
  }) = _QuestionWithChoicesImpl;

  factory QuestionWithChoices.fromJson(Map<String, dynamic> jsonSerialization) {
    return QuestionWithChoices(
      text: jsonSerialization['text'] as String,
      type: _i2.QuestionType.fromJson((jsonSerialization['type'] as String)),
      isRequired: jsonSerialization['isRequired'] as bool,
      placeholder: jsonSerialization['placeholder'] as String?,
      choices: _i3.Protocol().deserialize<List<String>>(
        jsonSerialization['choices'],
      ),
    );
  }

  /// The question text
  String text;

  /// Type of question (single choice, multiple choice, text, etc.)
  _i2.QuestionType type;

  /// Whether this question is required
  bool isRequired;

  /// Optional placeholder text for text inputs
  String? placeholder;

  /// List of choice texts (for single/multiple choice questions)
  List<String> choices;

  /// Returns a shallow copy of this [QuestionWithChoices]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  QuestionWithChoices copyWith({
    String? text,
    _i2.QuestionType? type,
    bool? isRequired,
    String? placeholder,
    List<String>? choices,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'QuestionWithChoices',
      'text': text,
      'type': type.toJson(),
      'isRequired': isRequired,
      if (placeholder != null) 'placeholder': placeholder,
      'choices': choices.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'QuestionWithChoices',
      'text': text,
      'type': type.toJson(),
      'isRequired': isRequired,
      if (placeholder != null) 'placeholder': placeholder,
      'choices': choices.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _QuestionWithChoicesImpl extends QuestionWithChoices {
  _QuestionWithChoicesImpl({
    required String text,
    required _i2.QuestionType type,
    required bool isRequired,
    String? placeholder,
    required List<String> choices,
  }) : super._(
         text: text,
         type: type,
         isRequired: isRequired,
         placeholder: placeholder,
         choices: choices,
       );

  /// Returns a shallow copy of this [QuestionWithChoices]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  QuestionWithChoices copyWith({
    String? text,
    _i2.QuestionType? type,
    bool? isRequired,
    Object? placeholder = _Undefined,
    List<String>? choices,
  }) {
    return QuestionWithChoices(
      text: text ?? this.text,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      placeholder: placeholder is String? ? placeholder : this.placeholder,
      choices: choices ?? this.choices.map((e0) => e0).toList(),
    );
  }
}
