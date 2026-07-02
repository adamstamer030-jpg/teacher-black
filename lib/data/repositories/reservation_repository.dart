import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../models/models.dart';

class ReservationRepository {
  final _dbProvider = AppDatabase.instance;

  Future<List<Reservation>> getAll({String? status, String? search}) async {
    final db = await _dbProvider.database;
    final where = <String>[];
    final args = <dynamic>[];
    if (status != null && status.isNotEmpty) {
      where.add('status = ?');
      args.add(status);
    }
    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      where.add('(student_name LIKE ? OR phone LIKE ? OR parent_phone LIKE ?)');
      args.addAll([s, s, s]);
    }
    final rows = await db.query(
      'reservations',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'id DESC',
    );
    return rows.map(Reservation.fromMap).toList();
  }

  Future<int> add(Reservation r) async {
    final db = await _dbProvider.database;
    final map = r.toMap();
    map['created_at'] = AppHelpers.nowIso();
    return db.insert('reservations', map);
  }

  Future<void> update(Reservation r) async {
    final db = await _dbProvider.database;
    await db.update('reservations', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await _dbProvider.database;
    await db.update('reservations', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await _dbProvider.database;
    await db.delete('reservations', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery('SELECT COUNT(*) c FROM reservations');
    return (rows.first['c'] as int?) ?? 0;
  }
}
