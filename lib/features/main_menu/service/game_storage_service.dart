import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для сохранения/загрузки прогресса игры
class GameStorageService {
  static const _keyLevel = 'game_level';
  static const _keyScore = 'game_score';
  static const _keyGrid = 'game_grid';

  /// Сохранить текущий прогресс (уровень, очки, опционально сетку)
  Future<void> saveGameState({
    required int level,
    required int score,
    List<List<int>>? grid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLevel, level);
    await prefs.setInt(_keyScore, score);

    if (grid != null) {
      final gridJson = jsonEncode(grid);
      await prefs.setString(_keyGrid, gridJson);
    } else {
      await prefs.remove(_keyGrid);
    }
  }

  /// Загрузить сохранённый прогресс
  /// Возвращает null если сохранения нет
  Future<({int level, int score, List<List<int>>? grid})?>
  loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt(_keyLevel);
    final score = prefs.getInt(_keyScore);

    if (level == null) return null;

    // Загрузить сетку если есть
    List<List<int>>? grid;
    final gridJson = prefs.getString(_keyGrid);
    if (gridJson != null) {
      final decoded = jsonDecode(gridJson) as List<dynamic>;
      grid = decoded
          .map((row) => (row as List<dynamic>).map((e) => e as int).toList())
          .toList();
    }

    return (level: level, score: score ?? 0, grid: grid);
  }

  /// Проверить наличие сохранения
  Future<bool> hasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyLevel);
  }

  /// Очистить сохранение
  Future<void> clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLevel);
    await prefs.remove(_keyScore);
    await prefs.remove(_keyGrid);
  }
}
