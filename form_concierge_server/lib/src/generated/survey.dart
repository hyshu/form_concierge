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
import 'survey_status.dart' as _i2;
import 'auth_requirement.dart' as _i3;

/// A survey/questionnaire form definition
abstract class Survey implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Survey._({
    this.id,
    required this.slug,
    required this.title,
    this.description,
    _i2.SurveyStatus? status,
    _i3.AuthRequirement? authRequirement,
    this.createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.startsAt,
    this.endsAt,
  }) : status = status ?? _i2.SurveyStatus.draft,
       authRequirement = authRequirement ?? _i3.AuthRequirement.anonymous,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Survey({
    int? id,
    required String slug,
    required String title,
    String? description,
    _i2.SurveyStatus? status,
    _i3.AuthRequirement? authRequirement,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startsAt,
    DateTime? endsAt,
  }) = _SurveyImpl;

  factory Survey.fromJson(Map<String, dynamic> jsonSerialization) {
    return Survey(
      id: jsonSerialization['id'] as int?,
      slug: jsonSerialization['slug'] as String,
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String?,
      status: jsonSerialization['status'] == null
          ? null
          : _i2.SurveyStatus.fromJson((jsonSerialization['status'] as String)),
      authRequirement: jsonSerialization['authRequirement'] == null
          ? null
          : _i3.AuthRequirement.fromJson(
              (jsonSerialization['authRequirement'] as String),
            ),
      createdByUserId: jsonSerialization['createdByUserId'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      startsAt: jsonSerialization['startsAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['startsAt']),
      endsAt: jsonSerialization['endsAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['endsAt']),
    );
  }

  static final t = SurveyTable();

  static const db = SurveyRepository._();

  @override
  int? id;

  /// Unique identifier for the survey (used in URLs)
  String slug;

  /// Title of the survey
  String title;

  /// Optional description of the survey
  String? description;

  /// Current status of the survey
  _i2.SurveyStatus status;

  /// Whether responses require authentication
  _i3.AuthRequirement authRequirement;

  /// Identifier of the admin user who created this survey (from auth system)
  String? createdByUserId;

  /// When the survey was created
  DateTime createdAt;

  /// When the survey was last updated
  DateTime updatedAt;

  /// Optional start date for accepting responses
  DateTime? startsAt;

  /// Optional end date for accepting responses
  DateTime? endsAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Survey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Survey copyWith({
    int? id,
    String? slug,
    String? title,
    String? description,
    _i2.SurveyStatus? status,
    _i3.AuthRequirement? authRequirement,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startsAt,
    DateTime? endsAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Survey',
      if (id != null) 'id': id,
      'slug': slug,
      'title': title,
      if (description != null) 'description': description,
      'status': status.toJson(),
      'authRequirement': authRequirement.toJson(),
      if (createdByUserId != null) 'createdByUserId': createdByUserId,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (startsAt != null) 'startsAt': startsAt?.toJson(),
      if (endsAt != null) 'endsAt': endsAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Survey',
      if (id != null) 'id': id,
      'slug': slug,
      'title': title,
      if (description != null) 'description': description,
      'status': status.toJson(),
      'authRequirement': authRequirement.toJson(),
      if (createdByUserId != null) 'createdByUserId': createdByUserId,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (startsAt != null) 'startsAt': startsAt?.toJson(),
      if (endsAt != null) 'endsAt': endsAt?.toJson(),
    };
  }

  static SurveyInclude include() {
    return SurveyInclude._();
  }

  static SurveyIncludeList includeList({
    _i1.WhereExpressionBuilder<SurveyTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SurveyTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SurveyTable>? orderByList,
    SurveyInclude? include,
  }) {
    return SurveyIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Survey.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Survey.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SurveyImpl extends Survey {
  _SurveyImpl({
    int? id,
    required String slug,
    required String title,
    String? description,
    _i2.SurveyStatus? status,
    _i3.AuthRequirement? authRequirement,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startsAt,
    DateTime? endsAt,
  }) : super._(
         id: id,
         slug: slug,
         title: title,
         description: description,
         status: status,
         authRequirement: authRequirement,
         createdByUserId: createdByUserId,
         createdAt: createdAt,
         updatedAt: updatedAt,
         startsAt: startsAt,
         endsAt: endsAt,
       );

  /// Returns a shallow copy of this [Survey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Survey copyWith({
    Object? id = _Undefined,
    String? slug,
    String? title,
    Object? description = _Undefined,
    _i2.SurveyStatus? status,
    _i3.AuthRequirement? authRequirement,
    Object? createdByUserId = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? startsAt = _Undefined,
    Object? endsAt = _Undefined,
  }) {
    return Survey(
      id: id is int? ? id : this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description is String? ? description : this.description,
      status: status ?? this.status,
      authRequirement: authRequirement ?? this.authRequirement,
      createdByUserId: createdByUserId is String?
          ? createdByUserId
          : this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startsAt: startsAt is DateTime? ? startsAt : this.startsAt,
      endsAt: endsAt is DateTime? ? endsAt : this.endsAt,
    );
  }
}

class SurveyUpdateTable extends _i1.UpdateTable<SurveyTable> {
  SurveyUpdateTable(super.table);

  _i1.ColumnValue<String, String> slug(String value) => _i1.ColumnValue(
    table.slug,
    value,
  );

  _i1.ColumnValue<String, String> title(String value) => _i1.ColumnValue(
    table.title,
    value,
  );

  _i1.ColumnValue<String, String> description(String? value) => _i1.ColumnValue(
    table.description,
    value,
  );

  _i1.ColumnValue<_i2.SurveyStatus, _i2.SurveyStatus> status(
    _i2.SurveyStatus value,
  ) => _i1.ColumnValue(
    table.status,
    value,
  );

  _i1.ColumnValue<_i3.AuthRequirement, _i3.AuthRequirement> authRequirement(
    _i3.AuthRequirement value,
  ) => _i1.ColumnValue(
    table.authRequirement,
    value,
  );

  _i1.ColumnValue<String, String> createdByUserId(String? value) =>
      _i1.ColumnValue(
        table.createdByUserId,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> startsAt(DateTime? value) =>
      _i1.ColumnValue(
        table.startsAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> endsAt(DateTime? value) =>
      _i1.ColumnValue(
        table.endsAt,
        value,
      );
}

class SurveyTable extends _i1.Table<int?> {
  SurveyTable({super.tableRelation}) : super(tableName: 'survey') {
    updateTable = SurveyUpdateTable(this);
    slug = _i1.ColumnString(
      'slug',
      this,
    );
    title = _i1.ColumnString(
      'title',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
    );
    status = _i1.ColumnEnum(
      'status',
      this,
      _i1.EnumSerialization.byName,
      hasDefault: true,
    );
    authRequirement = _i1.ColumnEnum(
      'authRequirement',
      this,
      _i1.EnumSerialization.byName,
      hasDefault: true,
    );
    createdByUserId = _i1.ColumnString(
      'createdByUserId',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
      hasDefault: true,
    );
    startsAt = _i1.ColumnDateTime(
      'startsAt',
      this,
    );
    endsAt = _i1.ColumnDateTime(
      'endsAt',
      this,
    );
  }

  late final SurveyUpdateTable updateTable;

  /// Unique identifier for the survey (used in URLs)
  late final _i1.ColumnString slug;

  /// Title of the survey
  late final _i1.ColumnString title;

  /// Optional description of the survey
  late final _i1.ColumnString description;

  /// Current status of the survey
  late final _i1.ColumnEnum<_i2.SurveyStatus> status;

  /// Whether responses require authentication
  late final _i1.ColumnEnum<_i3.AuthRequirement> authRequirement;

  /// Identifier of the admin user who created this survey (from auth system)
  late final _i1.ColumnString createdByUserId;

  /// When the survey was created
  late final _i1.ColumnDateTime createdAt;

  /// When the survey was last updated
  late final _i1.ColumnDateTime updatedAt;

  /// Optional start date for accepting responses
  late final _i1.ColumnDateTime startsAt;

  /// Optional end date for accepting responses
  late final _i1.ColumnDateTime endsAt;

  @override
  List<_i1.Column> get columns => [
    id,
    slug,
    title,
    description,
    status,
    authRequirement,
    createdByUserId,
    createdAt,
    updatedAt,
    startsAt,
    endsAt,
  ];
}

class SurveyInclude extends _i1.IncludeObject {
  SurveyInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Survey.t;
}

class SurveyIncludeList extends _i1.IncludeList {
  SurveyIncludeList._({
    _i1.WhereExpressionBuilder<SurveyTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Survey.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Survey.t;
}

class SurveyRepository {
  const SurveyRepository._();

  /// Returns a list of [Survey]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Survey>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SurveyTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SurveyTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SurveyTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Survey>(
      where: where?.call(Survey.t),
      orderBy: orderBy?.call(Survey.t),
      orderByList: orderByList?.call(Survey.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Survey] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Survey?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SurveyTable>? where,
    int? offset,
    _i1.OrderByBuilder<SurveyTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SurveyTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Survey>(
      where: where?.call(Survey.t),
      orderBy: orderBy?.call(Survey.t),
      orderByList: orderByList?.call(Survey.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Survey] by its [id] or null if no such row exists.
  Future<Survey?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Survey>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Survey]s in the list and returns the inserted rows.
  ///
  /// The returned [Survey]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Survey>> insert(
    _i1.Session session,
    List<Survey> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Survey>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Survey] and returns the inserted row.
  ///
  /// The returned [Survey] will have its `id` field set.
  Future<Survey> insertRow(
    _i1.Session session,
    Survey row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Survey>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Survey]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Survey>> update(
    _i1.Session session,
    List<Survey> rows, {
    _i1.ColumnSelections<SurveyTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Survey>(
      rows,
      columns: columns?.call(Survey.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Survey]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Survey> updateRow(
    _i1.Session session,
    Survey row, {
    _i1.ColumnSelections<SurveyTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Survey>(
      row,
      columns: columns?.call(Survey.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Survey] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Survey?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<SurveyUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Survey>(
      id,
      columnValues: columnValues(Survey.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Survey]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Survey>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<SurveyUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<SurveyTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SurveyTable>? orderBy,
    _i1.OrderByListBuilder<SurveyTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Survey>(
      columnValues: columnValues(Survey.t.updateTable),
      where: where(Survey.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Survey.t),
      orderByList: orderByList?.call(Survey.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Survey]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Survey>> delete(
    _i1.Session session,
    List<Survey> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Survey>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Survey].
  Future<Survey> deleteRow(
    _i1.Session session,
    Survey row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Survey>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Survey>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<SurveyTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Survey>(
      where: where(Survey.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SurveyTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Survey>(
      where: where?.call(Survey.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
