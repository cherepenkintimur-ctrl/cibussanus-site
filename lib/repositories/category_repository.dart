import '../database/db_service.dart';
import '../models/category.dart';

class CategoryRepository {
  const CategoryRepository();

  Future<int> create(Category category) async {
    final id = await DbService.instance.insert('categories', {
      'name': category.name.trim(),
      'description': category.description?.trim(),
    });
    return id;
  }

  Future<List<Category>> getAll() async {
    final rows = await DbService.instance.query(
      'SELECT id, name, description, created_at FROM categories ORDER BY name',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<Category?> getById(int id) async {
    final row = await DbService.instance.queryOne(
      'SELECT id, name, description, created_at FROM categories WHERE id = ?',
      arguments: [id],
    );
    return row == null ? null : Category.fromMap(row);
  }

  Future<int> update(Category category) async {
    if (category.id == null) {
      throw ArgumentError('Category id is required for update');
    }
    return DbService.instance.update(
      'categories',
      {
        'name': category.name.trim(),
        'description': category.description?.trim(),
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> delete(int id) async {
    return DbService.instance.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Category>> search(String keyword) async {
    final rows = await DbService.instance.query(
      '''
      SELECT id, name, description, created_at
      FROM categories
      WHERE name LIKE ? OR COALESCE(description, '') LIKE ?
      ORDER BY name
      ''',
      arguments: ['%${keyword.trim()}%', '%${keyword.trim()}%'],
    );
    return rows.map(Category.fromMap).toList();
  }
}
