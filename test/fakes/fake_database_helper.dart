import 'dart:async';
import 'package:cookpilot/ingredient_repository.dart';

class FakeDatabaseHelper implements IngredientRepository {
  final List<Map<String, dynamic>> _rows;
  final Duration delay;
  bool throwOnGet;

  FakeDatabaseHelper({
    List<Map<String, dynamic>>? initial,
    this.delay = Duration.zero,
    this.throwOnGet = false,
  }) : _rows = List<Map<String, dynamic>>.from(initial ?? []);

  @override
  Future<int> insertIngredient(Map<String, dynamic> ingredient) async {
    await Future.delayed(delay);
    final id = (_rows.isEmpty
        ? 1
        : (_rows.map((r) => r['id'] as int).reduce((a, b) => a > b ? a : b) +
              1));
    final row = Map<String, dynamic>.from(ingredient);
    row['id'] = id;
    _rows.insert(0, row);
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> getIngredients(
    String currentUserId,
  ) async {
    await Future.delayed(delay);
    if (throwOnGet) throw Exception('fetch error');
    return _rows.where((r) => r['userId'] == currentUserId).toList();
  }

  @override
  Future<int> deleteIngredient(int id, String currentUserId) async {
    await Future.delayed(delay);
    final index = _rows.indexWhere(
      (r) => r['id'] == id && r['userId'] == currentUserId,
    );
    if (index == -1) return 0;
    _rows.removeAt(index);
    return 1;
  }
}
