import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/app_colors.dart';
import '../../../di/di.dart';
import '../../game_field/cubit/game_field_cubit.dart';
import '../../game_field/view/game_field_screen.dart';
import '../service/game_storage_service.dart';

/// Главный экран меню
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  bool _hasSavedGame = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _checkSavedGame();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedGame() async {
    final storage = getIt<GameStorageService>();
    final has = await storage.hasSavedGame();
    if (mounted) {
      setState(() => _hasSavedGame = has);
    }
  }

  void _startNewGame() async {
    if (_hasSavedGame) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Новая игра'),
          content: const Text(
            'У вас есть сохранённая игра. Начать новую? Прогресс будет потерян.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Нет'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Да'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final storage = getIt<GameStorageService>();
    await storage.clearGameState();
    if (!mounted) return;
    _navigateToGame(initialLevel: 1, initialScore: 0);
  }

  void _continueGame() async {
    final storage = getIt<GameStorageService>();
    final saved = await storage.loadGameState();
    if (!mounted) return;
    if (saved != null) {
      _navigateToGame(
        initialLevel: saved.level,
        initialScore: saved.score,
        initialGrid: saved.grid,
      );
    }
  }

  void _navigateToGame({
    required int initialLevel,
    required int initialScore,
    List<List<int>>? initialGrid,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<GameFieldCubit>(
          create: (_) => getIt<GameFieldCubit>(),
          child: GameFieldScreen(
            initialLevel: initialLevel,
            initialScore: initialScore,
            initialGrid: initialGrid,
          ),
        ),
      ),
    );
    // Обновляем состояние кнопки «Продолжить» при возврате
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _checkSavedGame();
    });
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Stack(
              children: [
                Row(
                  children: [
                    // Левая часть — логотип
                    Expanded(child: Center(child: _buildTitle())),
                    // Правая часть — кнопки
                    Expanded(child: Center(child: _buildMenuButtons())),
                  ],
                ),
                // Версия внизу по центру
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'v1.0',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Эмодзи-логотип
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Center(
            child: Text('🎮', style: TextStyle(fontSize: 32)),
          ),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
          ).createShader(bounds),
          child: const Text(
            'PaiPai',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Connect & Match',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Новая игра
          _MenuButton(
            label: 'Новая игра',
            icon: Icons.play_arrow_rounded,
            gradient: const [AppColors.primary, AppColors.primaryDark],
            onTap: _startNewGame,
          ),
          const SizedBox(height: 10),
          // Продолжить
          if (_hasSavedGame) ...[
            _MenuButton(
              label: 'Продолжить',
              icon: Icons.fast_forward_rounded,
              gradient: const [Color(0xFF00C853), Color(0xFF009624)],
              onTap: _continueGame,
            ),
            const SizedBox(height: 10),
          ],
          // Выйти
          _MenuButton(
            label: 'Выйти',
            icon: Icons.exit_to_app_rounded,
            gradient: const [Color(0xFF455A64), Color(0xFF37474F)],
            onTap: _exitApp,
          ),
        ],
      ),
    );
  }
}

/// Стилизованная кнопка меню
class _MenuButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.gradient),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.first.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
