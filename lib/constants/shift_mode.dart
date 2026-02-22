/// Режим смещения плиток после удаления пары
enum ShiftMode {
  /// Уровень 1 — без смещения
  none,

  /// Уровень 2 — падают вниз
  down,

  /// Уровень 3 — всплывают вверх
  up,

  /// Уровень 4 — смещение влево
  left,

  /// Уровень 5 — смещение вправо
  right,

  /// Уровень 6 — расходятся от центра к краям (по горизонтали)
  fromCenter,

  /// Уровень 7 — стягиваются к центру (по горизонтали)
  toCenter,

  /// Уровень 8 — верхняя половина падает вниз к середине, нижняя — вверх к середине
  splitVertical,

  /// Уровни 9-10 — левая половина смещается вправо к центру, правая — влево к центру
  splitHorizontal,
}

/// Определить режим смещения по номеру уровня (1-indexed)
ShiftMode shiftModeForLevel(int level) {
  switch (level) {
    case 1:
      return ShiftMode.none;
    case 2:
      return ShiftMode.down;
    case 3:
      return ShiftMode.up;
    case 4:
      return ShiftMode.left;
    case 5:
      return ShiftMode.right;
    case 6:
      return ShiftMode.fromCenter;
    case 7:
      return ShiftMode.toCenter;
    case 8:
      return ShiftMode.splitVertical;
    case 9:
    case 10:
    default:
      return ShiftMode.splitHorizontal;
  }
}
