part of form_concierge_client;

class Survey {
  final int? id;
  final String slug;
  final String title;
  final String? description;
  final SurveyStatus status;
  final String? createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const Survey({
    this.id,
    required this.slug,
    required this.title,
    this.description,
    this.status = SurveyStatus.draft,
    this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.startsAt,
    this.endsAt,
  });

  factory Survey.fromJson(Map<String, dynamic> json) => Survey(
    id: json['id'] == null ? null : _int(json['id']),
    slug: json['slug'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    status: _enum(SurveyStatus.values, json['status'], SurveyStatus.draft),
    createdByUserId: json['createdByUserId'] as String?,
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
    startsAt: _optionalDate(json['startsAt']),
    endsAt: _optionalDate(json['endsAt']),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'slug': slug,
    'title': title,
    'description': description,
    'status': _enumName(status),
    'createdByUserId': createdByUserId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'startsAt': startsAt?.toIso8601String(),
    'endsAt': endsAt?.toIso8601String(),
  });

  Survey copyWith({
    int? id,
    String? slug,
    String? title,
    String? description,
    SurveyStatus? status,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    return Survey(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
    );
  }
}

class Question {
  final int? id;
  final int surveyId;
  final String text;
  final QuestionType type;
  final int orderIndex;
  final bool isRequired;
  final String? placeholder;
  final int? minLength;
  final int? maxLength;
  final bool isDeleted;

  const Question({
    this.id,
    required this.surveyId,
    required this.text,
    required this.type,
    required this.orderIndex,
    this.isRequired = true,
    this.placeholder,
    this.minLength,
    this.maxLength,
    this.isDeleted = false,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'] == null ? null : _int(json['id']),
    surveyId: _int(json['surveyId']),
    text: json['text'] as String,
    type: _enum(QuestionType.values, json['type'], QuestionType.textSingle),
    orderIndex: _int(json['orderIndex']),
    isRequired: _bool(json['isRequired'], true),
    placeholder: json['placeholder'] as String?,
    minLength: json['minLength'] == null ? null : _int(json['minLength']),
    maxLength: json['maxLength'] == null ? null : _int(json['maxLength']),
    isDeleted: _bool(json['isDeleted']),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'surveyId': surveyId,
    'text': text,
    'type': _enumName(type),
    'orderIndex': orderIndex,
    'isRequired': isRequired,
    'placeholder': placeholder,
    'minLength': minLength,
    'maxLength': maxLength,
    'isDeleted': isDeleted,
  });

  Question copyWith({
    int? id,
    int? surveyId,
    String? text,
    QuestionType? type,
    int? orderIndex,
    bool? isRequired,
    String? placeholder,
    int? minLength,
    int? maxLength,
    bool? isDeleted,
  }) {
    return Question(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      text: text ?? this.text,
      type: type ?? this.type,
      orderIndex: orderIndex ?? this.orderIndex,
      isRequired: isRequired ?? this.isRequired,
      placeholder: placeholder ?? this.placeholder,
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class Choice {
  final int? id;
  final int questionId;
  final String text;
  final int orderIndex;
  final String? value;

  const Choice({
    this.id,
    required this.questionId,
    required this.text,
    required this.orderIndex,
    this.value,
  });

  factory Choice.fromJson(Map<String, dynamic> json) => Choice(
    id: json['id'] == null ? null : _int(json['id']),
    questionId: _int(json['questionId']),
    text: json['text'] as String,
    orderIndex: _int(json['orderIndex']),
    value: json['value'] as String?,
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'questionId': questionId,
    'text': text,
    'orderIndex': orderIndex,
    'value': value,
  });

  Choice copyWith({
    int? id,
    int? questionId,
    String? text,
    int? orderIndex,
    String? value,
  }) {
    return Choice(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      text: text ?? this.text,
      orderIndex: orderIndex ?? this.orderIndex,
      value: value ?? this.value,
    );
  }
}

class QuestionWithChoices {
  final String text;
  final QuestionType type;
  final bool isRequired;
  final String? placeholder;
  final List<String> choices;

  const QuestionWithChoices({
    required this.text,
    required this.type,
    required this.isRequired,
    this.placeholder,
    required this.choices,
  });

  factory QuestionWithChoices.fromJson(Map<String, dynamic> json) =>
      QuestionWithChoices(
        text: json['text'] as String,
        type: _enum(QuestionType.values, json['type'], QuestionType.textSingle),
        isRequired: _bool(json['isRequired'], true),
        placeholder: json['placeholder'] as String?,
        choices: (json['choices'] as List? ?? const [])
            .map((value) => value.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => _withoutNulls({
    'text': text,
    'type': _enumName(type),
    'isRequired': isRequired,
    'placeholder': placeholder,
    'choices': choices,
  });
}
