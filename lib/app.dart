import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:igboman/screens/home_screen.dart';
import 'package:igboman/state/app_state.dart';
import 'package:igboman/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    this.appState,
  });

  final AppState? appState;

  @override
  Widget build(BuildContext context) {
    final materialApp = MaterialApp(
      title: 'Igboman',
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );

    if (appState != null) {
      return ChangeNotifierProvider<AppState>.value(
        value: appState!,
        child: materialApp,
      );
    }

    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState(),
      child: materialApp,
    );
  }
}
