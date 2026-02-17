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
          title: BlocBuilder<GameFieldCubit, GameFieldState>(
            buildWhen: (prev, curr) =>
                prev.level != curr.level || prev.score != curr.score,
            builder: (context, state) {
              return Text('Ур. ${state.level}  |  Очки: ${state.score}');
            },
          ),
          actions: [
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Оставшиеся плитки
              // Padding(
              //   padding: const EdgeInsets.only(bottom: 8),
              //   child: Text(
              //     'Осталось: ${state.remainingTiles}',
              //     style: const TextStyle(
              //       color: AppColors.textSecondary,
              //       fontSize: 14,
              //     ),
              //   ),
              // ),
              // Сетка
              _GridWidget(state: state),
            ],
          ),
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

/// Виджет игровой сетки с overlay для линии пути
class _GridWidget extends StatelessWidget {
  final GameFieldState state;

  const _GridWidget({required this.state});

  @override
  Widget build(BuildContext context) {
    final rows = GridConfig.physicalRows;
    final cols = GridConfig.physicalCols;

    final cellSize = GridConfig.tileSize + GridConfig.tilePadding;

    return SizedBox(
      width: cols * cellSize,
      height: rows * cellSize,
      child: Stack(
        children: [
          // Слой 1: Сетка плиток
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(rows, (physRow) {
              final virtualRow = physRow + GridConfig.rowOffset;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(cols, (physCol) {
                  final virtualCol = physCol + GridConfig.colOffset;
                  final tileType = state.grid[virtualRow][virtualCol];
                  final pos = GridPoint(virtualRow, virtualCol);

                  final isSelected = state.selectedPos == pos;
                  final isHint = state.hintPair?.contains(pos) ?? false;

                  return _TileWidget(
                    tileType: tileType,
                    isSelected: isSelected,
                    isHint: isHint,
                    onTap: tileType > 0
                        ? () {
                            context.read<GameFieldCubit>().selectTile(
                              virtualRow,
                              virtualCol,
                            );
                          }
                        : null,
                  );
                }),
              );
            }),
          ),
          // Слой 2: Линия пути (поверх плиток)
          if (state.matchPath != null && state.matchPath!.length >= 2)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: PathLinePainter(
                    path: state.matchPath!,
                    cellSize: cellSize,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// CustomPainter для рисования линии соединения
class PathLinePainter extends CustomPainter {
  final List<GridPoint> path;
  final double cellSize;

  PathLinePainter({required this.path, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;

    final paint = Paint()
      ..color = AppColors.pathLine
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();

    for (int i = 0; i < path.length; i++) {
      // Конвертируем виртуальные координаты в пиксельные
      // физ. координата = виртуальная - offset
      final px = (path[i].col - GridConfig.colOffset) * cellSize + cellSize / 2;
      final py = (path[i].row - GridConfig.rowOffset) * cellSize + cellSize / 2;

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
        (path.first.col - GridConfig.colOffset) * cellSize + cellSize / 2;
    final firstPy =
        (path.first.row - GridConfig.rowOffset) * cellSize + cellSize / 2;
    canvas.drawCircle(Offset(firstPx, firstPy), 5, dotPaint);

    final lastPx =
        (path.last.col - GridConfig.colOffset) * cellSize + cellSize / 2;
    final lastPy =
        (path.last.row - GridConfig.rowOffset) * cellSize + cellSize / 2;
    canvas.drawCircle(Offset(lastPx, lastPy), 5, dotPaint);
  }

  @override
  bool shouldRepaint(PathLinePainter oldDelegate) {
    return oldDelegate.path != path;
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
      '🎂',
      '🍫',
      '�',
      '�',
      '🍮',
      '🧀',
      '🥨',
      '🥯',
      '🥮',
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
            width: isSelected || isHint ? 2 : 1,
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
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
