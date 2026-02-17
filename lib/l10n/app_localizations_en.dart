// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PaiPai';

  @override
  String get score => 'Score';

  @override
  String get time => 'Time';

  @override
  String get level => 'Level';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get hint => 'Hint';

  @override
  String get gameOver => 'Game Over';

  @override
  String get congratulations => 'Congratulations!';
}
