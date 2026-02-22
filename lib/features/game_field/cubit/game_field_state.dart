import 'package:equatable/equatable.dart';

import '../../../model/game_models/point.dart';
import '../../../model/game_models/tile.dart';

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
  /// 0 = пусто, >0 = tileTypeId (для pathfinding)
  final List<List<int>> grid;

  /// Плоский список живых плиток с текущими координатами (для анимированного рендера)
  final List<Tile> tiles;

  /// Выбранная позиция (виртуальные координаты)
  final GridPoint? selectedPos;

  /// Путь между совпавшими плитками (для визуальной линии)
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
    this.tiles = const [],
    this.selectedPos,
    this.matchPath,
    this.hintPair,
    this.wasShuffled = false,
  });

  /// Количество оставшихся (не удалённых) плиток
  int get remainingTiles => tiles.length;

  GameFieldState copyWith({
    GameFieldStatus? status,
    int? level,
    int? score,
    int? remainingTime,
    List<List<int>>? grid,
    List<Tile>? tiles,
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
      tiles: tiles ?? this.tiles,
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
    tiles,
    selectedPos,
    matchPath,
    hintPair,
    wasShuffled,
  ];
}
