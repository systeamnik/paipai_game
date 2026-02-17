// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'PaiPai';

  @override
  String get score => 'Очки';

  @override
  String get time => 'Время';

  @override
  String get level => 'Уровень';

  @override
  String get shuffle => 'Перемешать';

  @override
  String get hint => 'Подсказка';

  @override
  String get gameOver => 'Игра окончена';

  @override
  String get congratulations => 'Поздравляем!';
}
