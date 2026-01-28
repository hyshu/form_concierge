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

/// A complete survey response submission
abstract class SurveyResponse
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  SurveyResponse._({
    this.id,
    required this.surveyId,
    this.userId,
    this.anonymousId,
    DateTime? submittedAt,
    this.ipAddress,
    this.userAgent,
  }) : submittedAt = submittedAt ?? DateTime.now();

  factory SurveyResponse({
    int? id,
    required int surveyId,
    String? userId,
    String? anonymousId,
    DateTime? submittedAt,
    String? ipAddress,
    String? userAgent,
  }) = _SurveyResponseImpl;

  factory SurveyResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return SurveyResponse(
      id: jsonSerialization['id'] as int?,
      surveyId: jsonSerialization['surveyId'] as int,
      userId: jsonSerialization['userId'] as String?,
      anonymousId: jsonSerialization['anonymousId'] as String?,
      submittedAt: jsonSerialization['submittedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['submittedAt'],
            ),
      ipAddress: jsonSerialization['ipAddress'] as String?,
      userAgent: jsonSerialization['userAgent'] as String?,
    );
  }

  static final t = SurveyResponseTable();

  static const db = SurveyResponseRepository._();

  @override
  int? id;

  /// Reference to the survey being responded to
  int surveyId;

  /// User identifier if authenticated response (from auth system)
  String? userId;

  /// Anonymous session identifier
  String? anonymousId;

  /// When the response was submitted
  DateTime submittedAt;

  /// IP address (for analytics/fraud prevention)
  String? ipAddress;

  /// User agent string
  String? userAgent;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [SurveyResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SurveyResponse copyWith({
    int? id,
    int? surveyId,
    String? userId,
    String? anonymousId,
    DateTime? submittedAt,
    String? ipAddress,
    String? userAgent,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SurveyResponse',
      if (id != null) 'id': id,
      'surveyId': surveyId,
      if (userId != null) 'userId': userId,
      if (anonymousId != null) 'anonymousId': anonymousId,
      'submittedAt': submittedAt.toJson(),
      if (ipAddress != null) 'ipAddress': ipAddress,
      if (userAgent != null) 'userAgent': userAgent,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SurveyResponse',
      if (id != null) 'id': id,
      'surveyId': surveyId,
      if (userId != null) 'userId': userId,
      if (anonymousId != null) 'anonymousId': anonymousId,
      'submittedAt': submittedAt.toJson(),
    };
  }

  static SurveyResponseInclude include() {
    return SurveyResponseInclude._();
  }

  static SurveyResponseIncludeList includeList({
    _i1.WhereExpressionBuilder<SurveyResponseTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SurveyResponseTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SurveyResponseTable>? orderByList,
    SurveyResponseInclude? include,
  }) {
    return SurveyResponseIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SurveyResponse.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(SurveyResponse.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SurveyResponseImpl extends SurveyResponse {
  _SurveyResponseImpl({
    int? id,
    required int surveyId,
    String? userId,
    String? anonymousId,
    DateTime? submittedAt,
    String? ipAddress,
    String? userAgent,
  }) : super._(
         id: id,
         surveyId: surveyId,
         userId: userId,
         anonymousId: anonymousId,
         submittedAt: submittedAt,
         ipAddress: ipAddress,
         userAgent: userAgent,
       );

  /// Returns a shallow copy of this [SurveyResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SurveyResponse copyWith({
    Object? id = _Undefined,
    int? surveyId,
    Object? userId = _Undefined,
    Object? anonymousId = _Undefined,
    DateTime? submittedAt,
    Object? ipAddress = _Undefined,
    Object? userAgent = _Undefined,
  }) {
    return SurveyResponse(
      id: id is int? ? id : this.id,
      surveyId: surveyId ?? this.surveyId,
      userId: userId is String? ? userId : this.userId,
      anonymousId: anonymousId is String? ? anonymousId : this.anonymousId,
      submittedAt: submittedAt ?? this.submittedAt,
      ipAddress: ipAddress is String? ? ipAddress : this.ipAddress,
      userAgent: userAgent is String? ? userAgent : this.userAgent,
    );
  }
}

class SurveyResponseUpdateTable extends _i1.UpdateTable<SurveyResponseTable> {
  SurveyResponseUpdateTable(super.table);

  _i1.ColumnValue<int, int> surveyId(int value) => _i1.ColumnValue(
    table.surveyId,
    value,
  );

  _i1.ColumnValue<String, String> userId(String? value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> anonymousId(String? value) => _i1.ColumnValue(
    table.anonymousId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> submittedAt(DateTime value) =>
      _i1.ColumnValue(
        table.submittedAt,
        value,
      );

  _i1.ColumnValue<String, String> ipAddress(String? value) => _i1.ColumnValue(
    table.ipAddress,
    value,
  );

  _i1.ColumnValue<String, String> userAgent(String? value) => _i1.ColumnValue(
    table.userAgent,
    value,
  );
}

class SurveyResponseTable extends _i1.Table<int?> {
  SurveyResponseTable({super.tableRelation})
    : super(tableName: 'survey_response') {
    updateTable = SurveyResponseUpdateTable(this);
    surveyId = _i1.ColumnInt(
      'surveyId',
      this,
    );
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    anonymousId = _i1.ColumnString(
      'anonymousId',
      this,
    );
    submittedAt = _i1.ColumnDateTime(
      'submittedAt',
      this,
      hasDefault: true,
    );
    ipAddress = _i1.ColumnString(
      'ipAddress',
      this,
    );
    userAgent = _i1.ColumnString(
      'userAgent',
      this,
    );
  }

  late final SurveyResponseUpdateTable updateTable;

  /// Reference to the survey being responded to
  late final _i1.ColumnInt surveyId;

  /// User identifier if authenticated response (from auth system)
  late final _i1.ColumnString userId;

  /// Anonymous session identifier
  late final _i1.ColumnString anonymousId;

  /// When the response was submitted
  late final _i1.ColumnDateTime submittedAt;

  /// IP address (for analytics/fraud prevention)
  late final _i1.ColumnString ipAddress;

  /// User agent string
  late final _i1.ColumnString userAgent;

  @override
  List<_i1.Column> get columns => [
    id,
    surveyId,
    userId,
    anonymousId,
    submittedAt,
    ipAddress,
    userAgent,
  ];
}

class SurveyResponseInclude extends _i1.IncludeObject {
  SurveyResponseInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => SurveyResponse.t;
}

class SurveyResponseIncludeList extends _i1.IncludeList {
  SurveyResponseIncludeList._({
    _i1.WhereExpressionBuilder<SurveyResponseTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SurveyResponse.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => SurveyResponse.t;
}

class SurveyResponseRepository {
  const SurveyResponseRepository._();

  /// Returns a list of [SurveyResponse]s matching the given query parameters.
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
  Future<List<SurveyResponse>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SurveyResponseTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SurveyResponseTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SurveyResponseTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<SurveyResponse>(
      where: where?.call(SurveyResponse.t),
      orderBy: orderBy?.call(SurveyResponse.t),
      orderByList: orderByList?.call(SurveyResponse.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [SurveyResponse] matching the given query parameters.
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
  Future<SurveyResponse?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SurveyResponseTable>? where,
    int? offset,
    _i1.OrderByBuilder<SurveyResponseTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SurveyResponseTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<SurveyResponse>(
      where: where?.call(SurveyResponse.t),
      orderBy: orderBy?.call(SurveyResponse.t),
      orderByList: orderByList?.call(SurveyResponse.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [SurveyResponse] by its [id] or null if no such row exists.
  Future<SurveyResponse?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<SurveyResponse>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [SurveyResponse]s in the list and returns the inserted rows.
  ///
  /// The returned [SurveyResponse]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<SurveyResponse>> insert(
    _i1.Session session,
    List<SurveyResponse> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<SurveyResponse>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [SurveyResponse] and returns the inserted row.
  ///
  /// The returned [SurveyResponse] will have its `id` field set.
  Future<SurveyResponse> insertRow(
    _i1.Session session,
    SurveyResponse row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<SurveyResponse>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [SurveyResponse]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<SurveyResponse>> update(
    _i1.Session session,
    List<SurveyResponse> rows, {
    _i1.ColumnSelections<SurveyResponseTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<SurveyResponse>(
      rows,
      columns: columns?.call(SurveyResponse.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SurveyResponse]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SurveyResponse> updateRow(
    _i1.Session session,
    SurveyResponse row, {
    _i1.ColumnSelections<SurveyResponseTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<SurveyResponse>(
      row,
      columns: columns?.call(SurveyResponse.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SurveyResponse] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SurveyResponse?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<SurveyResponseUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<SurveyResponse>(
      id,
      columnValues: columnValues(SurveyResponse.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SurveyResponse]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<SurveyResponse>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<SurveyResponseUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<SurveyResponseTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SurveyResponseTable>? orderBy,
    _i1.OrderByListBuilder<SurveyResponseTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<SurveyResponse>(
      columnValues: columnValues(SurveyResponse.t.updateTable),
      where: where(SurveyResponse.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SurveyResponse.t),
      orderByList: orderByList?.call(SurveyResponse.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [SurveyResponse]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<SurveyResponse>> delete(
    _i1.Session session,
    List<SurveyResponse> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<SurveyResponse>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [SurveyResponse].
  Future<SurveyResponse> deleteRow(
    _i1.Session session,
    SurveyResponse row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SurveyResponse>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<SurveyResponse>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<SurveyResponseTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<SurveyResponse>(
      where: where(SurveyResponse.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SurveyResponseTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<SurveyResponse>(
      where: where?.call(SurveyResponse.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
