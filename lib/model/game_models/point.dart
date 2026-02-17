import 'package:equatable/equatable.dart';

/// Точка на игровой сетке
class GridPoint extends Equatable {
  final int row;
  final int col;

  const GridPoint(this.row, this.col);

  @override
  List<Object?> get props => [row, col];

  @override
  String toString() => 'GridPoint($row, $col)';
}
