import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/grid_config.dart';
import '../../../model/game_models/point.dart';
import '../cubit/game_field_cubit.dart';
import '../cubit/game_field_state.dart';

/// Экран игрового поля
class GameFieldScreen extends StatefulWidget {
  final int initialLevel;
  final int initialScore;
  final List<List<int>>? initialGrid;

  const GameFieldScreen({
    super.key,
    this.initialLevel = 1,
    this.initialScore = 0,
    this.initialGrid,
  });

  @override
  State<GameFieldScreen> createState() => _GameFieldScreenState();
}

class _GameFieldScreenState extends State<GameFieldScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<GameFieldCubit>();
    if (widget.initialGrid != null) {
      cubit.continueFromSaved(
        widget.initialLevel,
        widget.initialScore,
        widget.initialGrid!,
      );
    } else {
      cubit.initLevel(widget.initialLevel, initialScore: widget.initialScore);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          context.read<GameFieldCubit>().saveCurrentState();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 40,
          title: BlocBuilder<GameFieldCubit, GameFieldState>(
            buildWhen: (prev, curr) =>
                prev.level != curr.level || prev.score != curr.score,
            builder: (context, state) {
              return Row(
                children: [
                  Text(
                    'Ур. ${state.level}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Очки: ${state.score}',
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        // widthFactor: state.timerProgress,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red, Colors.yellow, Colors.green],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () {
                context.read<GameFieldCubit>().showHint();
              },
              tooltip: 'Пауза',
            ),
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              onPressed: () {
                context.read<GameFieldCubit>().showHint();
              },
              tooltip: 'Подсказка',
            ),
          ],
        ),
        body: BlocConsumer<GameFieldCubit, GameFieldState>(
          listener: (context, state) {
            if (state.status == GameFieldStatus.completed) {
              _showLevelCompleteDialog(context, state.level);
            }
            if (state.wasShuffled) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Плитки перемешаны!'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == GameFieldStatus.initial || state.grid.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return _buildGameGrid(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildGameGrid(BuildContext context, GameFieldState state) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _GridWidget(state: state),
        ),
      ),
    );
  }

  void _showLevelCompleteDialog(BuildContext context, int level) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🎉 Уровень пройден!'),
        content: Text('Уровень $level завершён!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<GameFieldCubit>().initLevel(level + 1);
            },
            child: const Text('Следующий уровень'),
          ),
        ],
      ),
    );
  }
}

/// Виджет игровой сетки с анимированными плитками и overlay для линии пути
class _GridWidget extends StatelessWidget {
  final GameFieldState state;

  const _GridWidget({required this.state});

  @override
  Widget build(BuildContext context) {
    final rows = GridConfig.physicalRows;
    final cols = GridConfig.physicalCols;
    final cellSize = GridConfig.tileSize + GridConfig.tilePadding;

    // Отступ, чтобы линия пути не обрезалась краями
    const overflow = 4.0;

    final gridWidth = cols * cellSize;
    final gridHeight = rows * cellSize;

    return SizedBox(
      width: gridWidth + overflow * 2,
      height: gridHeight + overflow * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Слой 1: Фон сетки (пустые ячейки для визуального ориентира)
          Positioned(
            left: overflow,
            top: overflow,
            child: SizedBox(
              width: gridWidth,
              height: gridHeight,
              child: CustomPaint(
                painter: _GridBackgroundPainter(
                  rows: rows,
                  cols: cols,
                  cellSize: cellSize,
                ),
              ),
            ),
          ),

          // Слой 2: Анимированные плитки через AnimatedPositioned
          for (final tile in state.tiles)
            AnimatedPositioned(
              key: ValueKey(tile.id),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              left: overflow + (tile.col - GridConfig.colOffset) * cellSize,
              top: overflow + (tile.row - GridConfig.rowOffset) * cellSize,
              child: _TileWidget(
                tileType: tile.tileTypeId,
                isSelected: state.selectedPos == GridPoint(tile.row, tile.col),
                isHint:
                    state.hintPair?.contains(GridPoint(tile.row, tile.col)) ??
                    false,
                onTap: () => context.read<GameFieldCubit>().selectTile(
                  tile.row,
                  tile.col,
                ),
              ),
            ),

          // Слой 3: Линия пути (поверх плиток)
          if (state.matchPath != null && state.matchPath!.length >= 2)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: PathLinePainter(
                    path: state.matchPath!,
                    cellSize: cellSize,
                    offset: overflow,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Рисует серый фон пустых ячеек
class _GridBackgroundPainter extends CustomPainter {
  final int rows;
  final int cols;
  final double cellSize;

  const _GridBackgroundPainter({
    required this.rows,
    required this.cols,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A2E).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF2A2A4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const radius = Radius.circular(6);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final rect = RRect.fromLTRBR(
          c * cellSize + 1,
          r * cellSize + 1,
          (c + 1) * cellSize - 1,
          (r + 1) * cellSize - 1,
          radius,
        );
        canvas.drawRRect(rect, paint);
        canvas.drawRRect(rect, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridBackgroundPainter old) =>
      old.rows != rows || old.cols != cols;
}

/// CustomPainter для рисования линии соединения
class PathLinePainter extends CustomPainter {
  final List<GridPoint> path;
  final double cellSize;
  final double offset;

  PathLinePainter({
    required this.path,
    required this.cellSize,
    this.offset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;

    final paint = Paint()
      ..color = AppColors.pathLine
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();

    for (int i = 0; i < path.length; i++) {
      // Конвертируем виртуальные координаты в пиксельные
      // физ. координата = виртуальная - gridOffset, плюс overflow-отступ
      final px =
          (path[i].col - GridConfig.colOffset) * cellSize +
          cellSize / 2 +
          offset;
      final py =
          (path[i].row - GridConfig.rowOffset) * cellSize +
          cellSize / 2 +
          offset;

      if (i == 0) {
        linePath.moveTo(px, py);
      } else {
        linePath.lineTo(px, py);
      }
    }

    canvas.drawPath(linePath, paint);

    // Рисуем круги на концах для визуального акцента
    final dotPaint = Paint()
      ..color = AppColors.pathLine
      ..style = PaintingStyle.fill;

    final firstPx =
        (path.first.col - GridConfig.colOffset) * cellSize +
        cellSize / 2 +
        offset;
    final firstPy =
        (path.first.row - GridConfig.rowOffset) * cellSize +
        cellSize / 2 +
        offset;
    canvas.drawCircle(Offset(firstPx, firstPy), 5, dotPaint);

    final lastPx =
        (path.last.col - GridConfig.colOffset) * cellSize +
        cellSize / 2 +
        offset;
    final lastPy =
        (path.last.row - GridConfig.rowOffset) * cellSize +
        cellSize / 2 +
        offset;
    canvas.drawCircle(Offset(lastPx, lastPy), 5, dotPaint);
  }

  @override
  bool shouldRepaint(PathLinePainter oldDelegate) {
    return oldDelegate.path != path || oldDelegate.offset != offset;
  }
}

/// Виджет одной плитки
class _TileWidget extends StatelessWidget {
  final int tileType;
  final bool isSelected;
  final bool isHint;
  final VoidCallback? onTap;

  const _TileWidget({
    required this.tileType,
    required this.isSelected,
    required this.isHint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Пустая ячейка
    if (tileType == 0) {
      return SizedBox(
        width: GridConfig.tileSize + GridConfig.tilePadding,
        height: GridConfig.tileSize + GridConfig.tilePadding,
      );
    }

    // Список эмодзи для типов (36 видов)
    const tileEmojis = [
      '🍎',
      '🍊',
      '🍋',
      '🍇',
      '🍉',
      '🍓',
      '🫐',
      '🍒',
      '🥝',
      '🍑',
      '🥭',
      '🍍',
      '🥥',
      '🌽',
      '🥕',
      '🌶️',
      '🫑',
      '🥦',
      '🍄',
      '🧄',
      '🧅',
      '🥔',
      '🍠',
      '🥐',
      '🧁',
      '🍩',
      '🍪',
      '🥬',
      '🍫',
      '🥑',
      '🍌',
      '🍄‍🟫',
      '🧀',
      '🥨',
      '🥯',
      '🍰',
    ];

    final emoji = tileType > 0 && tileType <= tileEmojis.length
        ? tileEmojis[tileType - 1]
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: GridConfig.tileSize,
        height: GridConfig.tileSize,
        margin: EdgeInsets.all(GridConfig.tilePadding / 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.tileSelected
              : isHint
              ? AppColors.warning.withValues(alpha: 0.6)
              : AppColors.tileBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isHint
                ? AppColors.warning
                : AppColors.tileBorder,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
