import 'package:equatable/equatable.dart';

import 'tile.dart';

/// Статус игры
enum GameStatus {
  /// Начальное состояние
  initial,

  /// Игра в процессе
  playing,

  /// Игра на паузе
  paused,

  /// Игра завершена (победа)
  completed,

  /// Игра завершена (время вышло)
  gameOver,
}

/// Модель состояния игры
class GameStateModel extends Equatable {
  /// Текущий статус
  final GameStatus status;

  /// Текущий уровень
  final int level;

  /// Текущий счёт
  final int score;

  /// Оставшееся время (в секундах)
  final int remainingTime;

  /// Список плиток на поле
  final List<Tile> tiles;

  /// Выбранная плитка (первая)
  final Tile? selectedTile;

  const GameStateModel({
    this.status = GameStatus.initial,
    this.level = 1,
    this.score = 0,
    this.remainingTime = 300,
    this.tiles = const [],
    this.selectedTile,
  });

  /// Создать копию с изменёнными полями
  GameStateModel copyWith({
    GameStatus? status,
    int? level,
    int? score,
    int? remainingTime,
    List<Tile>? tiles,
    Tile? selectedTile,
    bool clearSelectedTile = false,
  }) {
    return GameStateModel(
      status: status ?? this.status,
      level: level ?? this.level,
      score: score ?? this.score,
      remainingTime: remainingTime ?? this.remainingTime,
      tiles: tiles ?? this.tiles,
      selectedTile: clearSelectedTile
          ? null
          : (selectedTile ?? this.selectedTile),
    );
  }

  @override
  List<Object?> get props => [
    status,
    level,
    score,
    remainingTime,
    tiles,
    selectedTile,
  ];
}
