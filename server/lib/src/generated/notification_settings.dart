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

/// Configuration for daily email notifications per survey
abstract class NotificationSettings
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  NotificationSettings._({
    this.id,
    required this.surveyId,
    bool? enabled,
    required this.recipientEmail,
    int? sendHour,
    DateTime? updatedAt,
    this.lastSentAt,
  }) : enabled = enabled ?? false,
       sendHour = sendHour ?? 9,
       updatedAt = updatedAt ?? DateTime.now();

  factory NotificationSettings({
    int? id,
    required int surveyId,
    bool? enabled,
    required String recipientEmail,
    int? sendHour,
    DateTime? updatedAt,
    DateTime? lastSentAt,
  }) = _NotificationSettingsImpl;

  factory NotificationSettings.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return NotificationSettings(
      id: jsonSerialization['id'] as int?,
      surveyId: jsonSerialization['surveyId'] as int,
      enabled: jsonSerialization['enabled'] as bool?,
      recipientEmail: jsonSerialization['recipientEmail'] as String,
      sendHour: jsonSerialization['sendHour'] as int?,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      lastSentAt: jsonSerialization['lastSentAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastSentAt']),
    );
  }

  static final t = NotificationSettingsTable();

  static const db = NotificationSettingsRepository._();

  @override
  int? id;

  /// Reference to the survey (one settings record per survey)
  int surveyId;

  /// Whether daily notifications are enabled
  bool enabled;

  /// Email address to receive notifications
  String recipientEmail;

  /// Hour of day to send notification (0-23, UTC)
  int sendHour;

  /// When settings were last updated
  DateTime updatedAt;

  /// Last time notification was sent (null if never)
  DateTime? lastSentAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [NotificationSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotificationSettings copyWith({
    int? id,
    int? surveyId,
    bool? enabled,
    String? recipientEmail,
    int? sendHour,
    DateTime? updatedAt,
    DateTime? lastSentAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NotificationSettings',
      if (id != null) 'id': id,
      'surveyId': surveyId,
      'enabled': enabled,
      'recipientEmail': recipientEmail,
      'sendHour': sendHour,
      'updatedAt': updatedAt.toJson(),
      if (lastSentAt != null) 'lastSentAt': lastSentAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'NotificationSettings',
      if (id != null) 'id': id,
      'surveyId': surveyId,
      'enabled': enabled,
      'recipientEmail': recipientEmail,
      'sendHour': sendHour,
      'updatedAt': updatedAt.toJson(),
      if (lastSentAt != null) 'lastSentAt': lastSentAt?.toJson(),
    };
  }

  static NotificationSettingsInclude include() {
    return NotificationSettingsInclude._();
  }

  static NotificationSettingsIncludeList includeList({
    _i1.WhereExpressionBuilder<NotificationSettingsTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<NotificationSettingsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<NotificationSettingsTable>? orderByList,
    NotificationSettingsInclude? include,
  }) {
    return NotificationSettingsIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(NotificationSettings.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(NotificationSettings.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NotificationSettingsImpl extends NotificationSettings {
  _NotificationSettingsImpl({
    int? id,
    required int surveyId,
    bool? enabled,
    required String recipientEmail,
    int? sendHour,
    DateTime? updatedAt,
    DateTime? lastSentAt,
  }) : super._(
         id: id,
         surveyId: surveyId,
         enabled: enabled,
         recipientEmail: recipientEmail,
         sendHour: sendHour,
         updatedAt: updatedAt,
         lastSentAt: lastSentAt,
       );

  /// Returns a shallow copy of this [NotificationSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotificationSettings copyWith({
    Object? id = _Undefined,
    int? surveyId,
    bool? enabled,
    String? recipientEmail,
    int? sendHour,
    DateTime? updatedAt,
    Object? lastSentAt = _Undefined,
  }) {
    return NotificationSettings(
      id: id is int? ? id : this.id,
      surveyId: surveyId ?? this.surveyId,
      enabled: enabled ?? this.enabled,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      sendHour: sendHour ?? this.sendHour,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSentAt: lastSentAt is DateTime? ? lastSentAt : this.lastSentAt,
    );
  }
}

class NotificationSettingsUpdateTable
    extends _i1.UpdateTable<NotificationSettingsTable> {
  NotificationSettingsUpdateTable(super.table);

  _i1.ColumnValue<int, int> surveyId(int value) => _i1.ColumnValue(
    table.surveyId,
    value,
  );

  _i1.ColumnValue<bool, bool> enabled(bool value) => _i1.ColumnValue(
    table.enabled,
    value,
  );

  _i1.ColumnValue<String, String> recipientEmail(String value) =>
      _i1.ColumnValue(
        table.recipientEmail,
        value,
      );

  _i1.ColumnValue<int, int> sendHour(int value) => _i1.ColumnValue(
    table.sendHour,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> lastSentAt(DateTime? value) =>
      _i1.ColumnValue(
        table.lastSentAt,
        value,
      );
}

class NotificationSettingsTable extends _i1.Table<int?> {
  NotificationSettingsTable({super.tableRelation})
    : super(tableName: 'notification_settings') {
    updateTable = NotificationSettingsUpdateTable(this);
    surveyId = _i1.ColumnInt(
      'surveyId',
      this,
    );
    enabled = _i1.ColumnBool(
      'enabled',
      this,
      hasDefault: true,
    );
    recipientEmail = _i1.ColumnString(
      'recipientEmail',
      this,
    );
    sendHour = _i1.ColumnInt(
      'sendHour',
      this,
      hasDefault: true,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
      hasDefault: true,
    );
    lastSentAt = _i1.ColumnDateTime(
      'lastSentAt',
      this,
    );
  }

  late final NotificationSettingsUpdateTable updateTable;

  /// Reference to the survey (one settings record per survey)
  late final _i1.ColumnInt surveyId;

  /// Whether daily notifications are enabled
  late final _i1.ColumnBool enabled;

  /// Email address to receive notifications
  late final _i1.ColumnString recipientEmail;

  /// Hour of day to send notification (0-23, UTC)
  late final _i1.ColumnInt sendHour;

  /// When settings were last updated
  late final _i1.ColumnDateTime updatedAt;

  /// Last time notification was sent (null if never)
  late final _i1.ColumnDateTime lastSentAt;

  @override
  List<_i1.Column> get columns => [
    id,
    surveyId,
    enabled,
    recipientEmail,
    sendHour,
    updatedAt,
    lastSentAt,
  ];
}

class NotificationSettingsInclude extends _i1.IncludeObject {
  NotificationSettingsInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => NotificationSettings.t;
}

class NotificationSettingsIncludeList extends _i1.IncludeList {
  NotificationSettingsIncludeList._({
    _i1.WhereExpressionBuilder<NotificationSettingsTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(NotificationSettings.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => NotificationSettings.t;
}

class NotificationSettingsRepository {
  const NotificationSettingsRepository._();

  /// Returns a list of [NotificationSettings]s matching the given query parameters.
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
  Future<List<NotificationSettings>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<NotificationSettingsTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<NotificationSettingsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<NotificationSettingsTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<NotificationSettings>(
      where: where?.call(NotificationSettings.t),
      orderBy: orderBy?.call(NotificationSettings.t),
      orderByList: orderByList?.call(NotificationSettings.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [NotificationSettings] matching the given query parameters.
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
  Future<NotificationSettings?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<NotificationSettingsTable>? where,
    int? offset,
    _i1.OrderByBuilder<NotificationSettingsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<NotificationSettingsTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<NotificationSettings>(
      where: where?.call(NotificationSettings.t),
      orderBy: orderBy?.call(NotificationSettings.t),
      orderByList: orderByList?.call(NotificationSettings.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [NotificationSettings] by its [id] or null if no such row exists.
  Future<NotificationSettings?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<NotificationSettings>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [NotificationSettings]s in the list and returns the inserted rows.
  ///
  /// The returned [NotificationSettings]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<NotificationSettings>> insert(
    _i1.Session session,
    List<NotificationSettings> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<NotificationSettings>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [NotificationSettings] and returns the inserted row.
  ///
  /// The returned [NotificationSettings] will have its `id` field set.
  Future<NotificationSettings> insertRow(
    _i1.Session session,
    NotificationSettings row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<NotificationSettings>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [NotificationSettings]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<NotificationSettings>> update(
    _i1.Session session,
    List<NotificationSettings> rows, {
    _i1.ColumnSelections<NotificationSettingsTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<NotificationSettings>(
      rows,
      columns: columns?.call(NotificationSettings.t),
      transaction: transaction,
    );
  }

  /// Updates a single [NotificationSettings]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<NotificationSettings> updateRow(
    _i1.Session session,
    NotificationSettings row, {
    _i1.ColumnSelections<NotificationSettingsTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<NotificationSettings>(
      row,
      columns: columns?.call(NotificationSettings.t),
      transaction: transaction,
    );
  }

  /// Updates a single [NotificationSettings] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<NotificationSettings?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<NotificationSettingsUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<NotificationSettings>(
      id,
      columnValues: columnValues(NotificationSettings.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [NotificationSettings]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<NotificationSettings>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<NotificationSettingsUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<NotificationSettingsTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<NotificationSettingsTable>? orderBy,
    _i1.OrderByListBuilder<NotificationSettingsTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<NotificationSettings>(
      columnValues: columnValues(NotificationSettings.t.updateTable),
      where: where(NotificationSettings.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(NotificationSettings.t),
      orderByList: orderByList?.call(NotificationSettings.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [NotificationSettings]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<NotificationSettings>> delete(
    _i1.Session session,
    List<NotificationSettings> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<NotificationSettings>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [NotificationSettings].
  Future<NotificationSettings> deleteRow(
    _i1.Session session,
    NotificationSettings row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<NotificationSettings>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<NotificationSettings>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<NotificationSettingsTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<NotificationSettings>(
      where: where(NotificationSettings.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<NotificationSettingsTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<NotificationSettings>(
      where: where?.call(NotificationSettings.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
