import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'stats_state.dart';

/// Cubit для управления статистикой (таймер, очки, уровень)
///
/// TODO: Реализовать в Этапе 4:
/// - Управление таймером (старт, пауза, остановка)
/// - Подсчёт очков
/// - Переход между уровнями
class StatsCubit extends Cubit<StatsState> {
  Timer? _timer;

  StatsCubit() : super(const StatsState());

  /// Начать таймер
  void startTimer() {
    _timer?.cancel();
    emit(state.copyWith(isTimerRunning: true));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingTime > 0) {
        emit(state.copyWith(remainingTime: state.remainingTime - 1));
      } else {
        stopTimer();
      }
    });
  }

  /// Остановить таймер
  void stopTimer() {
    _timer?.cancel();
    emit(state.copyWith(isTimerRunning: false));
  }

  /// Пауза
  void pauseTimer() {
    _timer?.cancel();
    emit(state.copyWith(isTimerRunning: false));
  }

  /// Добавить очки
  void addScore(int points) {
    emit(state.copyWith(score: state.score + points));
  }

  /// Установить уровень
  void setLevel(int level) {
    emit(state.copyWith(level: level, remainingTime: 300, score: 0));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
