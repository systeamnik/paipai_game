import 'package:flutter_test/flutter_test.dart';
import 'package:pai_pai/constants/grid_config.dart';
import 'package:pai_pai/features/game_field/cubit/game_field_cubit.dart';
import 'package:pai_pai/features/game_field/cubit/game_field_state.dart';
import 'package:pai_pai/features/main_menu/service/game_storage_service.dart';

void main() {
  group('GameFieldCubit', () {
    late GameFieldCubit cubit;

    setUp(() {
      cubit = GameFieldCubit(storage: GameStorageService());
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state.status, GameFieldStatus.initial);
      expect(cubit.state.grid, isEmpty);
      expect(cubit.state.level, 1);
      expect(cubit.state.score, 0);
    });

    group('initLevel', () {
      test('creates a playing state with filled grid', () {
        cubit.initLevel(1);
        final state = cubit.state;

        expect(state.status, GameFieldStatus.playing);
        expect(state.level, 1);
        expect(state.score, 0);
        expect(state.grid.length, GridConfig.virtualRows);
        expect(state.grid[0].length, GridConfig.virtualCols);
      });

      test('grid has even number of tiles', () {
        cubit.initLevel(1);

        int tileCount = 0;
        for (final row in cubit.state.grid) {
          for (final cell in row) {
            if (cell > 0) tileCount++;
          }
        }

        expect(tileCount % 2, 0, reason: 'Tile count must be even');
      });

      test('every tile type appears in pairs', () {
        cubit.initLevel(1);

        final typeCounts = <int, int>{};
        for (final row in cubit.state.grid) {
          for (final cell in row) {
            if (cell > 0) {
              typeCounts[cell] = (typeCounts[cell] ?? 0) + 1;
            }
          }
        }

        for (final entry in typeCounts.entries) {
          expect(
            entry.value % 2,
            0,
            reason: 'Type ${entry.key} has odd count ${entry.value}',
          );
        }
      });

      test('virtual border rows/cols are empty', () {
        cubit.initLevel(1);
        final grid = cubit.state.grid;

        // Top border row
        for (int c = 0; c < GridConfig.virtualCols; c++) {
          expect(grid[0][c], 0, reason: 'Top border at col $c should be 0');
        }
        // Bottom border row
        for (int c = 0; c < GridConfig.virtualCols; c++) {
          expect(
            grid[GridConfig.virtualRows - 1][c],
            0,
            reason: 'Bottom border at col $c should be 0',
          );
        }
        // Left border col
        for (int r = 0; r < GridConfig.virtualRows; r++) {
          expect(grid[r][0], 0, reason: 'Left border at row $r should be 0');
        }
        // Right border col
        for (int r = 0; r < GridConfig.virtualRows; r++) {
          expect(
            grid[r][GridConfig.virtualCols - 1],
            0,
            reason: 'Right border at row $r should be 0',
          );
        }
      });

      test('works for all 10 levels', () {
        for (int level = 1; level <= 10; level++) {
          cubit.initLevel(level);
          expect(
            cubit.state.status,
            GameFieldStatus.playing,
            reason: 'Level $level should start playing',
          );
          expect(cubit.state.level, level);
        }
      });
    });

    group('selectTile', () {
      test('first tap selects a tile', () {
        cubit.initLevel(1);
        final grid = cubit.state.grid;

        // Находим первую ненулевую ячейку
        int? r, c;
        outer:
        for (int row = 0; row < GridConfig.virtualRows; row++) {
          for (int col = 0; col < GridConfig.virtualCols; col++) {
            if (grid[row][col] > 0) {
              r = row;
              c = col;
              break outer;
            }
          }
        }

        expect(r, isNotNull);
        cubit.selectTile(r!, c!);
        expect(cubit.state.selectedPos, isNotNull);
        expect(cubit.state.selectedPos!.row, r);
        expect(cubit.state.selectedPos!.col, c);
      });

      test('tapping same tile deselects it', () {
        cubit.initLevel(1);
        final grid = cubit.state.grid;

        int? r, c;
        outer:
        for (int row = 0; row < GridConfig.virtualRows; row++) {
          for (int col = 0; col < GridConfig.virtualCols; col++) {
            if (grid[row][col] > 0) {
              r = row;
              c = col;
              break outer;
            }
          }
        }

        cubit.selectTile(r!, c!);
        expect(cubit.state.selectedPos, isNotNull);

        cubit.selectTile(r, c);
        expect(cubit.state.selectedPos, isNull);
      });

      test('tapping empty cell does nothing', () {
        cubit.initLevel(1);

        // Виртуальная рамка всегда пуста
        cubit.selectTile(0, 0);
        expect(cubit.state.selectedPos, isNull);
      });
    });

    group('showHint', () {
      test('returns a hint pair when moves available', () {
        cubit.initLevel(1);
        cubit.showHint();

        expect(cubit.state.hintPair, isNotNull);
        expect(cubit.state.hintPair!.length, 2);
      });
    });

    group('shuffle', () {
      test('preserves tile count after shuffle', () {
        cubit.initLevel(1);
        final tilesBefore = cubit.state.remainingTiles;

        cubit.shuffle();
        final tilesAfter = cubit.state.remainingTiles;

        expect(tilesAfter, tilesBefore);
      });
    });
  });
}
