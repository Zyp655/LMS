import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:backend/helpers/pagination.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  try {
    final db = context.read<AppDatabase>();
    final params = context.request.uri.queryParameters;
    final pg = Pagination.fromQuery(params);
    final roleFilter = int.tryParse(params['role'] ?? '');
    final search = params['search']?.toLowerCase();
    final departmentId = int.tryParse(params['departmentId'] ?? '');
    final studentClass = params['studentClass'];

    Set<int>? studentClassUserIds;
    if (studentClass != null && studentClass.isNotEmpty) {
      final profiles = await (db.select(db.studentProfiles)
            ..where((t) => t.studentClass.equals(studentClass)))
          .get();
      studentClassUserIds = profiles.map((p) => p.userId).toSet();
    }

    var query = db.select(db.users);

    if (roleFilter != null) {
      query = query..where((t) => t.role.equals(roleFilter));
    }

    if (departmentId != null) {
      query = query..where((t) => t.departmentId.equals(departmentId));
    }

    if (search != null && search.isNotEmpty) {
      query = query
        ..where(
          (t) =>
              t.email.lower().like('%$search%') |
              t.fullName.lower().like('%$search%'),
        );
    }

    if (studentClassUserIds != null) {
      query = query
        ..where((t) => t.id.isIn(studentClassUserIds!));
    }

    final countQuery = db.selectOnly(db.users);
    if (roleFilter != null) {
      countQuery.where(db.users.role.equals(roleFilter));
    }
    if (departmentId != null) {
      countQuery.where(db.users.departmentId.equals(departmentId));
    }
    if (search != null && search.isNotEmpty) {
      countQuery.where(
        db.users.email.lower().like('%$search%') |
            db.users.fullName.lower().like('%$search%'),
      );
    }
    if (studentClassUserIds != null) {
      countQuery.where(db.users.id.isIn(studentClassUserIds));
    }
    countQuery.addColumns([db.users.id.count()]);
    final countResult = await countQuery.getSingle();
    final total = countResult.read(db.users.id.count()) ?? 0;

    query = query
      ..orderBy([(t) => OrderingTerm.asc(t.id)])
      ..limit(pg.limit, offset: pg.offset);

    final paginatedUsers = await query.get();

    final userIds = paginatedUsers.map((u) => u.id).toSet();
    final profiles = await (db.select(db.studentProfiles)
          ..where((t) => t.userId.isIn(userIds)))
        .get();
    final profileMap = <int, dynamic>{};
    for (final p in profiles) {
      profileMap[p.userId] = p;
    }

    final departments = await db.select(db.departments).get();
    final deptNameMap = <int, String>{};
    for (final d in departments) {
      deptNameMap[d.id] = d.name;
    }

    final result = paginatedUsers.map(
      (u) {
        final profile = profileMap[u.id];
        return {
          'id': u.id,
          'email': u.email,
          'fullName': u.fullName,
          'role': u.role,
          'isBanned': u.isBanned,
          'departmentId': u.departmentId,
          'departmentName':
              u.departmentId != null ? deptNameMap[u.departmentId] : null,
          'studentClass': profile?.studentClass,
          'studentId': profile?.studentId,
        };
      },
    ).toList();

    return Response.json(body: pg.wrap(result, total: total, key: 'users'));
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'},
    );
  }
}
