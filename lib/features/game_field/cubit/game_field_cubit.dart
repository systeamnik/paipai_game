import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/grid_config.dart';
import '../../../constants/level_config.dart';
import '../../../model/game_models/point.dart';
import '../../main_menu/service/game_storage_service.dart';
import 'game_field_state.dart';

/// Cubit для управления игровым полем
///
/// Реализует:
/// - Генерация уровней (близкое и случайное размещение)
/// - Pathfinding с 0, 1, 2 изгибами
/// - Выбор и сопоставление плиток
/// - Контроль тупиков с авто-перемешиванием
/// - Подсказки
class GameFieldCubit extends Cubit<GameFieldState> {
  final Random _random = Random();
  final GameStorageService _storage;

  GameFieldCubit({required GameStorageService storage})
    : _storage = storage,
      super(const GameFieldState());

  // ---------------------------------------------------------------------------
  // PUBLIC API
  // ---------------------------------------------------------------------------

  /// Инициализация нового уровня
  void initLevel(int level, {int initialScore = 0}) {
    final config = LevelConfig.forLevel(level);
    final grid = _createEmptyGrid();

    _generateGrid(grid, config);

    emit(
      GameFieldState(
        status: GameFieldStatus.playing,
        level: level,
        score: initialScore,
        remainingTime: config.timeLimit,
        grid: grid,
        wasShuffled: false,
      ),
    );

    // Проверка тупика после генерации
    if (!_hasAvailableMoves(grid)) {
      _shuffleAndEmit();
    }
  }

  /// Продолжить игру из сохранённого состояния
  void continueFromSaved(int level, int score, List<List<int>> grid) {
    final config = LevelConfig.forLevel(level);

    emit(
      GameFieldState(
        status: GameFieldStatus.playing,
        level: level,
        score: score,
        remainingTime: config.timeLimit,
        grid: grid,
        wasShuffled: false,
      ),
    );

    // Проверка тупика
    if (!_hasAvailableMoves(grid)) {
      _shuffleAndEmit();
    }
  }

  /// Сохранить текущее состояние игры (вызывается при выходе)
  void saveCurrentState() {
    if (state.status != GameFieldStatus.playing) return;
    _storage.saveGameState(
      level: state.level,
      score: state.score,
      grid: state.grid,
    );
  }

  /// Выбор плитки по координатам виртуальной сетки
  void selectTile(int row, int col) {
    if (state.status != GameFieldStatus.playing) return;

    // Проверяем что ячейка не пуста
    if (state.grid[row][col] == 0) return;

    final tappedPos = GridPoint(row, col);

    // Очищаем предыдущий matchPath/hint если есть
    if (state.matchPath != null || state.hintPair != null) {
      emit(state.copyWith(clearMatchPath: true, clearHintPair: true));
    }

    // Нет выбранной — запоминаем
    if (state.selectedPos == null) {
      emit(state.copyWith(selectedPos: tappedPos));
      return;
    }

    final firstPos = state.selectedPos!;

    // Тот же тайл — снимаем выделение
    if (firstPos == tappedPos) {
      emit(state.copyWith(clearSelectedPos: true));
      return;
    }

    final firstType = state.grid[firstPos.row][firstPos.col];
    final secondType = state.grid[row][col];

    // Типы совпадают — ищем путь
    if (firstType == secondType) {
      final path = _findPath(state.grid, firstPos.row, firstPos.col, row, col);

      if (path != null) {
        // Совпадение найдено!
        _processMatch(firstPos, tappedPos, path);
        return;
      }
    }

    // Не совпали или путь не найден — выбираем новую
    emit(state.copyWith(selectedPos: tappedPos));
  }

  /// Перемешать оставшиеся плитки
  void shuffle() {
    if (state.status != GameFieldStatus.playing) return;
    _shuffleAndEmit();
  }

  /// Показать подсказку
  void showHint() {
    if (state.status != GameFieldStatus.playing) return;

    final pair = _findHintPair(state.grid);
    if (pair != null) {
      emit(
        state.copyWith(
          hintPair: pair,
          clearSelectedPos: true,
          clearMatchPath: true,
        ),
      );
    }
  }

  /// Обновить оставшееся время (вызывается таймером)
  void tick() {
    if (state.status != GameFieldStatus.playing) return;
    if (state.remainingTime <= 1) {
      emit(state.copyWith(remainingTime: 0, status: GameFieldStatus.gameOver));
    } else {
      emit(state.copyWith(remainingTime: state.remainingTime - 1));
    }
  }

  // ---------------------------------------------------------------------------
  // GRID GENERATION
  // ---------------------------------------------------------------------------

  /// Создать пустую виртуальную сетку
  List<List<int>> _createEmptyGrid() {
    return List.generate(
      GridConfig.virtualRows,
      (_) => List.filled(GridConfig.virtualCols, 0),
    );
  }

  /// Единая точка входа для генерации сетки
  void _generateGrid(List<List<int>> grid, LevelConfig config) {
    // Шаг 1: Заполнить сетку случайным размещением пар
    _fillRandomPairs(grid, config.tileTypes);

    // Шаг 2: Для hard-режима — применить анти-кластер
    if (config.placementMode == PlacementMode.hard) {
      _applyAntiCluster(grid);
    }
  }

  /// Заполнить сетку случайно размещёнными парами
  void _fillRandomPairs(List<List<int>> grid, int tileTypes) {
    final positions = <_Cell>[];

    for (int r = 0; r < GridConfig.physicalRows; r++) {
      for (int c = 0; c < GridConfig.physicalCols; c++) {
        positions.add(
          _Cell(r + GridConfig.rowOffset, c + GridConfig.colOffset),
        );
      }
    }

    final totalCells = positions.length;
    final usableCells = totalCells % 2 == 0 ? totalCells : totalCells - 1;
    final pairsCount = usableCells ~/ 2;

    // Генерируем список значений (каждый тип по 2 шт)
    final values = <int>[];
    for (int i = 0; i < pairsCount; i++) {
      final typeId = (i % tileTypes) + 1;
      values.add(typeId);
      values.add(typeId);
    }
    values.shuffle(_random);

    // Перемешиваем позиции
    positions.shuffle(_random);

    // Заполняем
    for (int i = 0; i < values.length && i < positions.length; i++) {
      grid[positions[i].row][positions[i].col] = values[i];
    }
  }

  /// Анти-кластер: расталкиваем пары одного типа максимально далеко
  void _applyAntiCluster(List<List<int>> grid) {
    // Собираем позиции по типам
    final typePositions = <int, List<_Cell>>{};

    for (
      int r = GridConfig.rowOffset;
      r < GridConfig.rowOffset + GridConfig.physicalRows;
      r++
    ) {
      for (
        int c = GridConfig.colOffset;
        c < GridConfig.colOffset + GridConfig.physicalCols;
        c++
      ) {
        final type = grid[r][c];
        if (type > 0) {
          typePositions.putIfAbsent(type, () => []);
          typePositions[type]!.add(_Cell(r, c));
        }
      }
    }

    // Количество итераций swap
    final iterations = typePositions.length * 3;

    for (int iter = 0; iter < iterations; iter++) {
      // Найти пару с минимальным Manhattan distance
      int? worstType;
      int worstDist = 999999;

      for (final entry in typePositions.entries) {
        if (entry.value.length < 2) continue;
        final dist = _manhattanDistance(entry.value[0], entry.value[1]);
        if (dist < worstDist) {
          worstDist = dist;
          worstType = entry.key;
        }
      }

      if (worstType == null) break;

      // Найти пару с максимальным distance для потенциального swap
      int? bestType;
      int bestDist = -1;

      for (final entry in typePositions.entries) {
        if (entry.key == worstType) continue;
        if (entry.value.length < 2) continue;
        final dist = _manhattanDistance(entry.value[0], entry.value[1]);
        if (dist > bestDist) {
          bestDist = dist;
          bestType = entry.key;
        }
      }

      if (bestType == null) break;

      // Пробуем swap: одна плитка из worstType с одной из bestType
      // Выбираем ту комбинацию, которая улучшает суммарный distance
      final worstCells = typePositions[worstType]!;
      final bestCells = typePositions[bestType]!;

      int bestImprovement = 0;
      int swapWorstIdx = -1;
      int swapBestIdx = -1;

      for (int wi = 0; wi < worstCells.length; wi++) {
        for (int bi = 0; bi < bestCells.length; bi++) {
          // Текущие distances
          final currentWorstDist = _manhattanDistance(
            worstCells[0],
            worstCells[1],
          );
          final currentBestDist = _manhattanDistance(
            bestCells[0],
            bestCells[1],
          );

          // Simulate swap
          final tempWorst = List<_Cell>.from(worstCells);
          final tempBest = List<_Cell>.from(bestCells);
          final swapCell = tempWorst[wi];
          tempWorst[wi] = tempBest[bi];
          tempBest[bi] = swapCell;

          final newWorstDist = _manhattanDistance(tempWorst[0], tempWorst[1]);
          final newBestDist = _manhattanDistance(tempBest[0], tempBest[1]);

          // Считаем улучшение для пары с минимальным distance
          final improvement =
              (newWorstDist - currentWorstDist) +
              (newBestDist - currentBestDist);

          if (improvement > bestImprovement) {
            bestImprovement = improvement;
            swapWorstIdx = wi;
            swapBestIdx = bi;
          }
        }
      }

      // Применяем swap если есть улучшение
      if (bestImprovement > 0 && swapWorstIdx >= 0 && swapBestIdx >= 0) {
        final cellA = worstCells[swapWorstIdx];
        final cellB = bestCells[swapBestIdx];

        // Swap в сетке
        final temp = grid[cellA.row][cellA.col];
        grid[cellA.row][cellA.col] = grid[cellB.row][cellB.col];
        grid[cellB.row][cellB.col] = temp;

        // Swap в трекере позиций
        worstCells[swapWorstIdx] = cellB;
        bestCells[swapBestIdx] = cellA;
      }
    }
  }

  /// Manhattan distance между двумя ячейками
  int _manhattanDistance(_Cell a, _Cell b) {
    return (a.row - b.row).abs() + (a.col - b.col).abs();
  }

  // ---------------------------------------------------------------------------
  // PATHFINDING
  // ---------------------------------------------------------------------------

  /// Найти путь между двумя ячейками (0, 1 или 2 изгиба)
  /// Возвращает список точек пути или null
  List<GridPoint>? _findPath(
    List<List<int>> grid,
    int r1,
    int c1,
    int r2,
    int c2,
  ) {
    // 0 изгибов — прямая линия
    final straight = _checkStraight(grid, r1, c1, r2, c2);
    if (straight != null) return straight;

    // 1 изгиб — L-путь
    final lPath = _checkL(grid, r1, c1, r2, c2);
    if (lPath != null) return lPath;

    // 2 изгиба — Z-путь
    final zPath = _checkZ(grid, r1, c1, r2, c2);
    if (zPath != null) return zPath;

    return null;
  }

  /// Проверка по прямой (0 изгибов)
  /// Оба конца на одной оси, все промежуточные ячейки = 0
  List<GridPoint>? _checkStraight(
    List<List<int>> grid,
    int r1,
    int c1,
    int r2,
    int c2,
  ) {
    if (r1 == r2) {
      // Горизонтальная линия
      final minC = min(c1, c2);
      final maxC = max(c1, c2);
      for (int c = minC + 1; c < maxC; c++) {
        if (grid[r1][c] != 0) return null;
      }
      return [GridPoint(r1, c1), GridPoint(r2, c2)];
    }

    if (c1 == c2) {
      // Вертикальная линия
      final minR = min(r1, r2);
      final maxR = max(r1, r2);
      for (int r = minR + 1; r < maxR; r++) {
        if (grid[r][c1] != 0) return null;
      }
      return [GridPoint(r1, c1), GridPoint(r2, c2)];
    }

    return null;
  }

  /// Проверка свободного пути по прямой (не включая концы)
  bool _isLineClear(List<List<int>> grid, int r1, int c1, int r2, int c2) {
    if (r1 == r2) {
      final minC = min(c1, c2);
      final maxC = max(c1, c2);
      for (int c = minC + 1; c < maxC; c++) {
        if (grid[r1][c] != 0) return false;
      }
      return true;
    }
    if (c1 == c2) {
      final minR = min(r1, r2);
      final maxR = max(r1, r2);
      for (int r = minR + 1; r < maxR; r++) {
        if (grid[r][c1] != 0) return false;
      }
      return true;
    }
    return false;
  }

  /// Проверка с одним изгибом (L-путь)
  /// Проверяет две возможные точки поворота: (r1, c2) и (r2, c1)
  List<GridPoint>? _checkL(
    List<List<int>> grid,
    int r1,
    int c1,
    int r2,
    int c2,
  ) {
    // Точка поворота 1: (r1, c2)
    if (grid[r1][c2] == 0) {
      if (_isLineClear(grid, r1, c1, r1, c2) &&
          _isLineClear(grid, r1, c2, r2, c2)) {
        return [GridPoint(r1, c1), GridPoint(r1, c2), GridPoint(r2, c2)];
      }
    }

    // Точка поворота 2: (r2, c1)
    if (grid[r2][c1] == 0) {
      if (_isLineClear(grid, r1, c1, r2, c1) &&
          _isLineClear(grid, r2, c1, r2, c2)) {
        return [GridPoint(r1, c1), GridPoint(r2, c1), GridPoint(r2, c2)];
      }
    }

    return null;
  }

  /// Проверка с двумя изгибами (Z-путь)
  /// Сканируем все горизонтальные и вертикальные линии
  List<GridPoint>? _checkZ(
    List<List<int>> grid,
    int r1,
    int c1,
    int r2,
    int c2,
  ) {
    // Сканируем по горизонтальным линиям (фиксированный row)
    for (int r = 0; r < GridConfig.virtualRows; r++) {
      // Точка поворота 1: (r, c1), Точка поворота 2: (r, c2)
      final p1Empty = (r == r1) || grid[r][c1] == 0;
      final p2Empty = (r == r2) || grid[r][c2] == 0;

      if (p1Empty && p2Empty) {
        // Проверяем три сегмента: (r1,c1)->(r,c1), (r,c1)->(r,c2), (r,c2)->(r2,c2)
        final seg1 = (r == r1) || _isLineClear(grid, r1, c1, r, c1);
        final seg2 = _isLineClear(grid, r, c1, r, c2);
        final seg3 = (r == r2) || _isLineClear(grid, r, c2, r2, c2);

        if (seg1 && seg2 && seg3) {
          return [
            GridPoint(r1, c1),
            GridPoint(r, c1),
            GridPoint(r, c2),
            GridPoint(r2, c2),
          ];
        }
      }
    }

    // Сканируем по вертикальным линиям (фиксированный col)
    for (int c = 0; c < GridConfig.virtualCols; c++) {
      // Точка поворота 1: (r1, c), Точка поворота 2: (r2, c)
      final p1Empty = (c == c1) || grid[r1][c] == 0;
      final p2Empty = (c == c2) || grid[r2][c] == 0;

      if (p1Empty && p2Empty) {
        final seg1 = (c == c1) || _isLineClear(grid, r1, c1, r1, c);
        final seg2 = _isLineClear(grid, r1, c, r2, c);
        final seg3 = (c == c2) || _isLineClear(grid, r2, c, r2, c2);

        if (seg1 && seg2 && seg3) {
          return [
            GridPoint(r1, c1),
            GridPoint(r1, c),
            GridPoint(r2, c),
            GridPoint(r2, c2),
          ];
        }
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // MATCH PROCESSING
  // ---------------------------------------------------------------------------

  /// Обработать совпадение
  void _processMatch(GridPoint first, GridPoint second, List<GridPoint> path) {
    final newScore = state.score + GridConfig.scorePerMatch;

    // Фаза 1: Показать линию пути (плитки ещё на месте)
    emit(
      state.copyWith(
        matchPath: path,
        score: newScore,
        clearSelectedPos: true,
        clearHintPair: true,
      ),
    );

    // Фаза 2: Через 400мс убрать плитки и линию
    Future.delayed(const Duration(milliseconds: 400), () {
      if (isClosed) return;

      final newGrid = _copyGrid(state.grid);
      newGrid[first.row][first.col] = 0;
      newGrid[second.row][second.col] = 0;

      final hasAnyTiles = _hasTilesLeft(newGrid);

      if (!hasAnyTiles) {
        // Уровень пройден!
        _storage.saveGameState(level: state.level + 1, score: newScore);
        emit(
          state.copyWith(
            grid: newGrid,
            status: GameFieldStatus.completed,
            clearMatchPath: true,
          ),
        );
        return;
      }

      emit(state.copyWith(grid: newGrid, clearMatchPath: true));

      // Проверяем тупик
      if (!_hasAvailableMoves(newGrid)) {
        _shuffleAndEmit();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // DEADLOCK & SHUFFLE
  // ---------------------------------------------------------------------------

  /// Проверить наличие хотя бы одного доступного хода
  bool _hasAvailableMoves(List<List<int>> grid) {
    final filledCells = <_Cell>[];

    for (int r = 0; r < GridConfig.virtualRows; r++) {
      for (int c = 0; c < GridConfig.virtualCols; c++) {
        if (grid[r][c] > 0) {
          filledCells.add(_Cell(r, c));
        }
      }
    }

    // Проверяем все пары
    for (int i = 0; i < filledCells.length; i++) {
      for (int j = i + 1; j < filledCells.length; j++) {
        final a = filledCells[i];
        final b = filledCells[j];

        if (grid[a.row][a.col] != grid[b.row][b.col]) continue;

        if (_findPath(grid, a.row, a.col, b.row, b.col) != null) {
          return true;
        }
      }
    }

    return false;
  }

  /// Перемешать оставшиеся элементы и emit
  void _shuffleAndEmit() {
    final newGrid = _copyGrid(state.grid);
    _shuffleGrid(newGrid);

    // Повторять до тех пор, пока не будет хотя бы один ход
    int attempts = 0;
    while (!_hasAvailableMoves(newGrid) && attempts < 100) {
      _shuffleGrid(newGrid);
      attempts++;
    }

    emit(
      state.copyWith(
        grid: newGrid,
        wasShuffled: true,
        clearSelectedPos: true,
        clearMatchPath: true,
        clearHintPair: true,
      ),
    );
  }

  /// Перемешать элементы в сетке (Fisher-Yates)
  void _shuffleGrid(List<List<int>> grid) {
    // Собираем все заполненные позиции и их значения
    final positions = <_Cell>[];
    final values = <int>[];

    for (
      int r = GridConfig.rowOffset;
      r < GridConfig.rowOffset + GridConfig.physicalRows;
      r++
    ) {
      for (
        int c = GridConfig.colOffset;
        c < GridConfig.colOffset + GridConfig.physicalCols;
        c++
      ) {
        if (grid[r][c] > 0) {
          positions.add(_Cell(r, c));
          values.add(grid[r][c]);
        }
      }
    }

    // Fisher-Yates shuffle значений
    for (int i = values.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = values[i];
      values[i] = values[j];
      values[j] = temp;
    }

    // Записываем обратно
    for (int i = 0; i < positions.length; i++) {
      grid[positions[i].row][positions[i].col] = values[i];
    }
  }

  // ---------------------------------------------------------------------------
  // HINT
  // ---------------------------------------------------------------------------

  /// Найти пару для подсказки
  List<GridPoint>? _findHintPair(List<List<int>> grid) {
    final filledCells = <_Cell>[];

    for (int r = 0; r < GridConfig.virtualRows; r++) {
      for (int c = 0; c < GridConfig.virtualCols; c++) {
        if (grid[r][c] > 0) {
          filledCells.add(_Cell(r, c));
        }
      }
    }

    for (int i = 0; i < filledCells.length; i++) {
      for (int j = i + 1; j < filledCells.length; j++) {
        final a = filledCells[i];
        final b = filledCells[j];

        if (grid[a.row][a.col] != grid[b.row][b.col]) continue;

        if (_findPath(grid, a.row, a.col, b.row, b.col) != null) {
          return [GridPoint(a.row, a.col), GridPoint(b.row, b.col)];
        }
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  /// Глубокая копия сетки
  List<List<int>> _copyGrid(List<List<int>> grid) {
    return grid.map((row) => List<int>.from(row)).toList();
  }

  /// Проверить наличие плиток на поле
  bool _hasTilesLeft(List<List<int>> grid) {
    for (final row in grid) {
      for (final cell in row) {
        if (cell > 0) return true;
      }
    }
    return false;
  }
}

/// Внутренняя вспомогательная структура для позиций
class _Cell {
  final int row;
  final int col;
  const _Cell(this.row, this.col);
}
