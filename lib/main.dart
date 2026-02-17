import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'di/di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Фиксируем горизонтальную ориентацию
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Загрузка переменных окружения
  await dotenv.load(fileName: '.env');

  // Настройка DI
  setupDI();

  runApp(const App());
}
