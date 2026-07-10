part of form_concierge_client;

typedef UuidValue = String;

enum QuestionType {
  singleChoice,
  multipleChoice,
  textSingle,
  textMultiLine,
  imageUpload,
}

enum SurveyStatus { draft, published, closed, archived }

enum AdminRole { admin, editor, viewer }

enum VisibilityConditionMode { all, any }

enum VisibilityOperator {
  equals,
  notEquals,
  contains,
  notContains,
  isAnswered,
  isNotAnswered,
}

extension QuestionTypeProperties on QuestionType {
  bool get usesChoices =>
      this == QuestionType.singleChoice || this == QuestionType.multipleChoice;

  bool get usesTextAnswer =>
      this == QuestionType.textSingle || this == QuestionType.textMultiLine;

  bool get usesImageUpload => this == QuestionType.imageUpload;
}

String _enumName(Object value) => value.toString().split('.').last;

DateTime _date(dynamic value) =>
    value is DateTime ? value : DateTime.parse(_string(value));

DateTime? _optionalDate(dynamic value) => value == null ? null : _date(value);

String _string(dynamic value) {
  if (value is String) return value;
  throw FormatException('Expected string, got ${value.runtimeType}');
}

String? _optionalString(dynamic value) => value == null ? null : _string(value);

List<String> _stringList(dynamic value) {
  if (value is! List) {
    throw FormatException('Expected string list, got ${value.runtimeType}');
  }
  return value.map(_string).toList();
}

int _int(dynamic value) {
  if (value is int) return value;
  throw FormatException('Expected integer, got ${value.runtimeType}');
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  throw FormatException('Expected number, got ${value.runtimeType}');
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  throw FormatException('Expected boolean, got ${value.runtimeType}');
}

T _enum<T extends Object>(Iterable<T> values, dynamic value) {
  if (value is! String) {
    throw FormatException('Expected enum string, got ${value.runtimeType}');
  }
  final name = value;
  return values.firstWhere(
    (v) => _enumName(v) == name,
    orElse: () => throw FormatException('Unknown enum value: $name'),
  );
}

int _intStringKey(Object? key) {
  final value = _string(key);
  if (!RegExp(r'^-?\d+$').hasMatch(value)) {
    throw FormatException('Expected integer key, got $value');
  }
  return int.parse(value);
}

List<int>? _intList(dynamic value) {
  if (value == null) return null;
  if (value is List) return value.map(_int).toList();
  throw FormatException('Expected integer list, got ${value.runtimeType}');
}

Map<String, dynamic>? _map(dynamic value) {
  if (value == null) return null;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('Expected JSON object, got ${value.runtimeType}');
}

Map<String, dynamic> _requiredMap(dynamic value) {
  final map = _map(value);
  if (map == null) {
    throw const FormatException('Expected JSON object');
  }
  return map;
}

T _object<T>(dynamic value, T Function(Map<String, dynamic>) fromJson) {
  return fromJson(_requiredMap(value));
}

T? _optionalObject<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromJson,
) {
  final map = _map(value);
  return map == null ? null : fromJson(map);
}

List<T> _objectList<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! List) {
    throw FormatException('Expected JSON array, got ${value.runtimeType}');
  }
  final list = value;
  return list.map((item) => _object(item, fromJson)).toList();
}

Future<Map<int, List<Choice>>> _choicesByQuestion(
  Iterable<Question> questions,
  Future<List<Choice>> Function(int questionId) getChoicesForQuestion,
) async {
  final entries = await Future.wait(
    questions
        .where((question) => question.id != null && question.type.usesChoices)
        .map((question) async {
          return MapEntry(
            question.id!,
            await getChoicesForQuestion(question.id!),
          );
        }),
  );
  return Map.fromEntries(entries);
}

Map<String, dynamic> _withoutNulls(Map<String, dynamic> source) {
  return Map.fromEntries(source.entries.where((entry) => entry.value != null));
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Object? details;

  const ApiException(this.statusCode, this.message, [this.details]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
