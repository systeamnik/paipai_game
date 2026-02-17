import 'package:equatable/equatable.dart';

/// Модель игровой плитки
class Tile extends Equatable {
  /// Уникальный ID плитки на поле
  final int id;

  /// Позиция строки (0-indexed)
  final int row;

  /// Позиция столбца (0-indexed)
  final int col;

  /// ID типа плитки (для сопоставления)
  final int tileTypeId;

  /// Флаг: плитка уже совпала и удалена
  final bool isMatched;

  const Tile({
    required this.id,
    required this.row,
    required this.col,
    required this.tileTypeId,
    this.isMatched = false,
  });

  /// Создать копию с изменёнными полями
  Tile copyWith({
    int? id,
    int? row,
    int? col,
    int? tileTypeId,
    bool? isMatched,
  }) {
    return Tile(
      id: id ?? this.id,
      row: row ?? this.row,
      col: col ?? this.col,
      tileTypeId: tileTypeId ?? this.tileTypeId,
      isMatched: isMatched ?? this.isMatched,
    );
  }

  @override
  List<Object?> get props => [id, row, col, tileTypeId, isMatched];

  @override
  String toString() =>
      'Tile(id: $id, row: $row, col: $col, type: $tileTypeId, matched: $isMatched)';
}
