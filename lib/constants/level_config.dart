/// Режим размещения плиток
enum PlacementMode {
  /// Случайное, мало типов — легко найти визуально
  easy,

  /// Случайное, больше типов — сложнее визуально
  medium,

  /// Анти-кластер: пары одного типа максимально далеко друг от друга
  hard,
}

/// Конфигурация уровня
class LevelConfig {
  /// Количество уникальных типов иконок
  final int tileTypes;

  /// Время на уровень (секунды)
  final int timeLimit;

  /// Режим размещения плиток
  final PlacementMode placementMode;

  const LevelConfig({
    required this.tileTypes,
    required this.timeLimit,
    required this.placementMode,
  });

  /// Конфигурации для 10 уровней
  static const List<LevelConfig> levels = [
    // Уровни 1-3: Easy — пары легко найти (случайное размещение)
    LevelConfig(
      tileTypes: 20,
      timeLimit: 300,
      placementMode: PlacementMode.easy,
    ),
    LevelConfig(
      tileTypes: 22,
      timeLimit: 290,
      placementMode: PlacementMode.easy,
    ),
    LevelConfig(
      tileTypes: 24,
      timeLimit: 280,
      placementMode: PlacementMode.easy,
    ),
    // Уровни 4-7: Medium — больше типов, сложнее визуально
    LevelConfig(
      tileTypes: 26,
      timeLimit: 270,
      placementMode: PlacementMode.medium,
    ),
    LevelConfig(
      tileTypes: 28,
      timeLimit: 260,
      placementMode: PlacementMode.medium,
    ),
    LevelConfig(
      tileTypes: 30,
      timeLimit: 250,
      placementMode: PlacementMode.medium,
    ),
    LevelConfig(
      tileTypes: 32,
      timeLimit: 240,
      placementMode: PlacementMode.medium,
    ),
    // Уровни 8-10: Hard — анти-кластер, пары далеко
    LevelConfig(
      tileTypes: 34,
      timeLimit: 220,
      placementMode: PlacementMode.hard,
    ),
    LevelConfig(
      tileTypes: 35,
      timeLimit: 200,
      placementMode: PlacementMode.hard,
    ),
    LevelConfig(
      tileTypes: 36,
      timeLimit: 180,
      placementMode: PlacementMode.hard,
    ),
  ];

  /// Получить конфигурацию для уровня (1-indexed)
  static LevelConfig forLevel(int level) {
    final index = (level - 1).clamp(0, levels.length - 1);
    return levels[index];
  }
}
