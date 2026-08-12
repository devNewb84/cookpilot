abstract class IngredientRepository {
  Future<int> insertIngredient(Map<String, dynamic> ingredient);
  Future<List<Map<String, dynamic>>> getIngredients(String currentUserId);
  Future<int> deleteIngredient(int id, String currentUserId);
}
