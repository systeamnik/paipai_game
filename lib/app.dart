import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'l10n/app_localizations.dart';

import 'constants/app_theme.dart';
import 'di/di.dart';
import 'features/main_menu/view/main_menu_screen.dart';
import 'features/stats/cubit/stats_cubit.dart';

/// Корневой виджет приложения
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<StatsCubit>(create: (_) => getIt<StatsCubit>())],
      child: MaterialApp(
        title: 'PaiPai',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MainMenuScreen(),
      ),
    );
  }
}
