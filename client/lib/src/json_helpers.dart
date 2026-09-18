part of form_concierge_client;

/// A UUID represented as a string.
typedef UuidValue = String;

/// Creates a random key that can be reused when retrying one submission.
String generateIdempotencyKey() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// The input format used to collect a question's answer.
enum QuestionType {
  /// A question that accepts one selected choice.
  singleChoice,

  /// A question that accepts several selected choices.
  multipleChoice,

  /// A question that accepts a single line of text.
  textSingle,

  /// A question that accepts multiple lines of text.
  textMultiLine,

  /// A question that accepts uploaded images.
  imageUpload,
}

/// The publication state of a survey.
enum SurveyStatus {
  /// A survey that has not been published.
  draft,

  /// A published survey, subject to its availability schedule.
  published,

  /// A survey that no longer accepts responses.
  closed,

  /// A survey retained for reference after active use.
  archived,
}

/// The permission level assigned to an administrator.
enum AdminRole {
  /// Full administrator access, including user and integration management.
  admin,

  /// Access to edit survey content and manage responses.
  editor,

  /// Read access to survey content and response results.
  viewer,
}

/// How multiple rules combine to control question visibility.
enum VisibilityConditionMode {
  /// Shows the question only when every rule matches.
  all,

  /// Shows the question when at least one rule matches.
  any,
}

/// The comparison applied to a source question's answer.
enum VisibilityOperator {
  /// Matches equal text or a selected choice.
  equals,

  /// Matches different text or an unselected choice when an answer exists.
  notEquals,

  /// Matches text containing a substring or a selected choice.
  contains,

  /// Matches an answer that excludes the text or choice.
  notContains,

  /// Matches a nonempty answer.
  isAnswered,

  /// Matches a missing or empty answer.
  isNotAnswered,
}

/// Input capabilities associated with each question type.
extension QuestionTypeProperties on QuestionType {
  /// Whether this question type presents selectable choices.
  bool get usesChoices =>
      this == QuestionType.singleChoice || this == QuestionType.multipleChoice;

  /// Whether this question type accepts text input.
  bool get usesTextAnswer =>
      this == QuestionType.textSingle || this == QuestionType.textMultiLine;

  /// Whether this question type accepts image uploads.
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

/// An unsuccessful API response with its HTTP status and error details.
class ApiException implements Exception {
  /// The HTTP status returned by the server.
  final int statusCode;

  /// The message displayed to the caller or user.
  final String message;

  /// Additional error information returned by the server, when available.
  final Object? details;

  /// Creates ApiException with the supplied values.
  const ApiException(this.statusCode, this.message, [this.details]);

  /// Returns a readable description of this error.
  @override
  String toString() => 'ApiException($statusCode): $message';
}
