import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../models/models.dart';

class NoteRepository {
  final _dbProvider = AppDatabase.instance;

  Future<List<GeneralNote>> getAll() async {
    final db = await _dbProvider.database;
    final rows = await db.query('notes', orderBy: 'id DESC');
    return rows.map(GeneralNote.fromMap).toList();
  }

  Future<int> add(String text) async {
    final db = await _dbProvider.database;
    return db.insert('notes', {
      'text': text,
      'date': AppHelpers.todayDateOnly(),
      'created_at': AppHelpers.nowIso(),
    });
  }

  Future<void> update(int id, String text) async {
    final db = await _dbProvider.database;
    await db.update('notes', {'text': text}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await _dbProvider.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
