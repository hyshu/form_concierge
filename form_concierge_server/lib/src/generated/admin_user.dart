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

/// Extended admin user with roles
abstract class AdminUser
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  AdminUser._({
    this.id,
    required this.userId,
    required this.displayName,
    bool? isAdmin,
    bool? canCreateSurveys,
    DateTime? createdAt,
  }) : isAdmin = isAdmin ?? false,
       canCreateSurveys = canCreateSurveys ?? true,
       createdAt = createdAt ?? DateTime.now();

  factory AdminUser({
    int? id,
    required int userId,
    required String displayName,
    bool? isAdmin,
    bool? canCreateSurveys,
    DateTime? createdAt,
  }) = _AdminUserImpl;

  factory AdminUser.fromJson(Map<String, dynamic> jsonSerialization) {
    return AdminUser(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      displayName: jsonSerialization['displayName'] as String,
      isAdmin: jsonSerialization['isAdmin'] as bool?,
      canCreateSurveys: jsonSerialization['canCreateSurveys'] as bool?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = AdminUserTable();

  static const db = AdminUserRepository._();

  @override
  int? id;

  /// Reference to the auth user
  int userId;

  /// Admin display name
  String displayName;

  /// Whether user has admin access
  bool isAdmin;

  /// Whether user can create surveys
  bool canCreateSurveys;

  /// When the admin user was created
  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [AdminUser]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AdminUser copyWith({
    int? id,
    int? userId,
    String? displayName,
    bool? isAdmin,
    bool? canCreateSurveys,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AdminUser',
      if (id != null) 'id': id,
      'userId': userId,
      'displayName': displayName,
      'isAdmin': isAdmin,
      'canCreateSurveys': canCreateSurveys,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AdminUser',
      if (id != null) 'id': id,
      'userId': userId,
      'displayName': displayName,
      'isAdmin': isAdmin,
      'canCreateSurveys': canCreateSurveys,
      'createdAt': createdAt.toJson(),
    };
  }

  static AdminUserInclude include() {
    return AdminUserInclude._();
  }

  static AdminUserIncludeList includeList({
    _i1.WhereExpressionBuilder<AdminUserTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AdminUserTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AdminUserTable>? orderByList,
    AdminUserInclude? include,
  }) {
    return AdminUserIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AdminUser.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(AdminUser.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AdminUserImpl extends AdminUser {
  _AdminUserImpl({
    int? id,
    required int userId,
    required String displayName,
    bool? isAdmin,
    bool? canCreateSurveys,
    DateTime? createdAt,
  }) : super._(
         id: id,
         userId: userId,
         displayName: displayName,
         isAdmin: isAdmin,
         canCreateSurveys: canCreateSurveys,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [AdminUser]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AdminUser copyWith({
    Object? id = _Undefined,
    int? userId,
    String? displayName,
    bool? isAdmin,
    bool? canCreateSurveys,
    DateTime? createdAt,
  }) {
    return AdminUser(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      isAdmin: isAdmin ?? this.isAdmin,
      canCreateSurveys: canCreateSurveys ?? this.canCreateSurveys,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AdminUserUpdateTable extends _i1.UpdateTable<AdminUserTable> {
  AdminUserUpdateTable(super.table);

  _i1.ColumnValue<int, int> userId(int value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> displayName(String value) => _i1.ColumnValue(
    table.displayName,
    value,
  );

  _i1.ColumnValue<bool, bool> isAdmin(bool value) => _i1.ColumnValue(
    table.isAdmin,
    value,
  );

  _i1.ColumnValue<bool, bool> canCreateSurveys(bool value) => _i1.ColumnValue(
    table.canCreateSurveys,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class AdminUserTable extends _i1.Table<int?> {
  AdminUserTable({super.tableRelation}) : super(tableName: 'admin_user') {
    updateTable = AdminUserUpdateTable(this);
    userId = _i1.ColumnInt(
      'userId',
      this,
    );
    displayName = _i1.ColumnString(
      'displayName',
      this,
    );
    isAdmin = _i1.ColumnBool(
      'isAdmin',
      this,
      hasDefault: true,
    );
    canCreateSurveys = _i1.ColumnBool(
      'canCreateSurveys',
      this,
      hasDefault: true,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final AdminUserUpdateTable updateTable;

  /// Reference to the auth user
  late final _i1.ColumnInt userId;

  /// Admin display name
  late final _i1.ColumnString displayName;

  /// Whether user has admin access
  late final _i1.ColumnBool isAdmin;

  /// Whether user can create surveys
  late final _i1.ColumnBool canCreateSurveys;

  /// When the admin user was created
  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    displayName,
    isAdmin,
    canCreateSurveys,
    createdAt,
  ];
}

class AdminUserInclude extends _i1.IncludeObject {
  AdminUserInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => AdminUser.t;
}

class AdminUserIncludeList extends _i1.IncludeList {
  AdminUserIncludeList._({
    _i1.WhereExpressionBuilder<AdminUserTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AdminUser.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => AdminUser.t;
}

class AdminUserRepository {
  const AdminUserRepository._();

  /// Returns a list of [AdminUser]s matching the given query parameters.
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
  Future<List<AdminUser>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AdminUserTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AdminUserTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AdminUserTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<AdminUser>(
      where: where?.call(AdminUser.t),
      orderBy: orderBy?.call(AdminUser.t),
      orderByList: orderByList?.call(AdminUser.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [AdminUser] matching the given query parameters.
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
  Future<AdminUser?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AdminUserTable>? where,
    int? offset,
    _i1.OrderByBuilder<AdminUserTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AdminUserTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<AdminUser>(
      where: where?.call(AdminUser.t),
      orderBy: orderBy?.call(AdminUser.t),
      orderByList: orderByList?.call(AdminUser.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [AdminUser] by its [id] or null if no such row exists.
  Future<AdminUser?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<AdminUser>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [AdminUser]s in the list and returns the inserted rows.
  ///
  /// The returned [AdminUser]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<AdminUser>> insert(
    _i1.Session session,
    List<AdminUser> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<AdminUser>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [AdminUser] and returns the inserted row.
  ///
  /// The returned [AdminUser] will have its `id` field set.
  Future<AdminUser> insertRow(
    _i1.Session session,
    AdminUser row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<AdminUser>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [AdminUser]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<AdminUser>> update(
    _i1.Session session,
    List<AdminUser> rows, {
    _i1.ColumnSelections<AdminUserTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<AdminUser>(
      rows,
      columns: columns?.call(AdminUser.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AdminUser]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AdminUser> updateRow(
    _i1.Session session,
    AdminUser row, {
    _i1.ColumnSelections<AdminUserTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<AdminUser>(
      row,
      columns: columns?.call(AdminUser.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AdminUser] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AdminUser?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<AdminUserUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<AdminUser>(
      id,
      columnValues: columnValues(AdminUser.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AdminUser]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<AdminUser>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<AdminUserUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<AdminUserTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AdminUserTable>? orderBy,
    _i1.OrderByListBuilder<AdminUserTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<AdminUser>(
      columnValues: columnValues(AdminUser.t.updateTable),
      where: where(AdminUser.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AdminUser.t),
      orderByList: orderByList?.call(AdminUser.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [AdminUser]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<AdminUser>> delete(
    _i1.Session session,
    List<AdminUser> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<AdminUser>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [AdminUser].
  Future<AdminUser> deleteRow(
    _i1.Session session,
    AdminUser row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AdminUser>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<AdminUser>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<AdminUserTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<AdminUser>(
      where: where(AdminUser.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AdminUserTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<AdminUser>(
      where: where?.call(AdminUser.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
