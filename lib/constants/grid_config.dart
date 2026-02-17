/// Конфигурация игровой сетки
class GridConfig {
  GridConfig._();

  /// Физическая сетка (видимая) — горизонтальная ориентация
  static const int physicalRows = 9;
  static const int physicalCols = 16;

  /// Виртуальная сетка (для поиска пути, +2 к каждой стороне)
  static const int virtualRows = 11;
  static const int virtualCols = 18;

  /// Смещение физической сетки внутри виртуальной
  static const int rowOffset = 1;
  static const int colOffset = 1;

  /// Максимальное количество изгибов в пути
  static const int maxTurns = 2;

  /// Количество типов плиток (максимум)
  static const int tileTypesCount = 36;

  /// Размер плитки (логический)
  static const double tileSize = 34.0;

  /// Отступ между плитками
  static const double tilePadding = 2.0;

  /// Базовый лимит времени (секунды)
  static const int baseTimeLimit = 300;

  /// Очки за одно совпадение
  static const int scorePerMatch = 10;

  /// Общее количество ячеек в физической сетке
  static const int totalCells = physicalRows * physicalCols;
}
