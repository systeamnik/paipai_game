/// Пути к ассетам приложения
class AppAssets {
  AppAssets._();

  // Базовые пути
  static const String _imagesPath = 'assets/images';
  static const String _iconsPath = 'assets/icons';

  // Фоны
  static const String backgroundImage = '$_imagesPath/background.png';

  // Иконки плиток
  static const String tilesPath = '$_iconsPath/tiles';

  /// Получить путь к иконке плитки по ID типа
  static String tileIcon(int typeId) => '$tilesPath/tile_$typeId.png';
}
