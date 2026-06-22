part of form_concierge_client;

typedef UuidValue = String;

enum QuestionType { singleChoice, multipleChoice, textSingle, textMultiLine }

enum SurveyStatus { draft, published, closed, archived }

extension QuestionTypeProperties on QuestionType {
  bool get usesChoices =>
      this == QuestionType.singleChoice || this == QuestionType.multipleChoice;

  bool get usesTextAnswer =>
      this == QuestionType.textSingle || this == QuestionType.textMultiLine;
}

String _enumName(Object value) => value.toString().split('.').last;

DateTime _date(dynamic value) =>
    value is DateTime ? value : DateTime.parse(value as String);

DateTime? _optionalDate(dynamic value) => value == null ? null : _date(value);

int _int(dynamic value) => value is int ? value : int.parse(value.toString());

double _double(dynamic value) =>
    value is double ? value : double.parse(value.toString());

bool _bool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value.toString() == 'true';
}

T _enum<T>(Iterable<T> values, dynamic value, T fallback) {
  if (value == null) return fallback;
  final name = value.toString();
  return values.firstWhere(
    (v) => _enumName(v as Object) == name,
    orElse: () => fallback,
  );
}

List<int>? _intList(dynamic value) {
  if (value == null) return null;
  if (value is List) return value.map(_int).toList();
  if (value is String && value.isNotEmpty) {
    final decoded = jsonDecode(value);
    if (decoded is List) return decoded.map(_int).toList();
  }
  return null;
}

Map<String, dynamic>? _map(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
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
  final list = value as List? ?? const [];
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
