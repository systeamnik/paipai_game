import 'package:equatable/equatable.dart';

import '../../../model/game_models/point.dart';

/// Статус игрового поля
enum GameFieldStatus { initial, playing, paused, completed, gameOver }

/// Состояние Cubit-а игрового поля
class GameFieldState extends Equatable {
  /// Статус игры
  final GameFieldStatus status;

  /// Текущий уровень
  final int level;

  /// Текущий счёт
  final int score;

  /// Оставшееся время (секунды)
  final int remainingTime;

  /// Виртуальная сетка [virtualRows][virtualCols]
  /// 0 = пусто, >0 = tileTypeId
  final List<List<int>> grid;

  /// Выбранная позиция (физические координаты)
  final GridPoint? selectedPos;

  /// Путь между совпавшими плитками (для анимации линии)
  final List<GridPoint>? matchPath;

  /// Пара для подсказки
  final List<GridPoint>? hintPair;

  /// Было ли выполнено авто-перемешивание
  final bool wasShuffled;

  const GameFieldState({
    this.status = GameFieldStatus.initial,
    this.level = 1,
    this.score = 0,
    this.remainingTime = 300,
    this.grid = const [],
    this.selectedPos,
    this.matchPath,
    this.hintPair,
    this.wasShuffled = false,
  });

  /// Количество оставшихся (не удалённых) плиток
  int get remainingTiles {
    int count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell > 0) count++;
      }
    }
    return count;
  }

  GameFieldState copyWith({
    GameFieldStatus? status,
    int? level,
    int? score,
    int? remainingTime,
    List<List<int>>? grid,
    GridPoint? selectedPos,
    List<GridPoint>? matchPath,
    List<GridPoint>? hintPair,
    bool? wasShuffled,
    bool clearSelectedPos = false,
    bool clearMatchPath = false,
    bool clearHintPair = false,
  }) {
    return GameFieldState(
      status: status ?? this.status,
      level: level ?? this.level,
      score: score ?? this.score,
      remainingTime: remainingTime ?? this.remainingTime,
      grid: grid ?? this.grid,
      selectedPos: clearSelectedPos ? null : (selectedPos ?? this.selectedPos),
      matchPath: clearMatchPath ? null : (matchPath ?? this.matchPath),
      hintPair: clearHintPair ? null : (hintPair ?? this.hintPair),
      wasShuffled: wasShuffled ?? this.wasShuffled,
    );
  }

  @override
  List<Object?> get props => [
    status,
    level,
    score,
    remainingTime,
    grid,
    selectedPos,
    matchPath,
    hintPair,
    wasShuffled,
  ];
}
