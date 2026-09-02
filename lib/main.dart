import 'package:flutter/material.dart';
import 'package:igboman/app.dart';
import 'package:igboman/services/progress_service.dart';
import 'package:igboman/state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const progressService = ProgressService();
  final progress = await progressService.load();
  final appState = AppState(
    initial: progress,
    progressService: progressService,
  );
  runApp(App(appState: appState));
}
