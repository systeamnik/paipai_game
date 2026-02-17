import 'package:equatable/equatable.dart';

/// Состояние статистики игры
class StatsState extends Equatable {
  /// Текущий счёт
  final int score;

  /// Оставшееся время в секундах
  final int remainingTime;

  /// Текущий уровень
  final int level;

  /// Активен ли таймер
  final bool isTimerRunning;

  const StatsState({
    this.score = 0,
    this.remainingTime = 300,
    this.level = 1,
    this.isTimerRunning = false,
  });

  StatsState copyWith({
    int? score,
    int? remainingTime,
    int? level,
    bool? isTimerRunning,
  }) {
    return StatsState(
      score: score ?? this.score,
      remainingTime: remainingTime ?? this.remainingTime,
      level: level ?? this.level,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
    );
  }

  /// Форматированное время MM:SS
  String get formattedTime {
    final minutes = remainingTime ~/ 60;
    final seconds = remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [score, remainingTime, level, isTimerRunning];
}
