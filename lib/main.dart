import 'package:flutter/material.dart';
import 'l10n/app_strings.dart';
import 'screens/disclaimer_screen.dart';
import 'services/remote_data_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Chequeo OTA silencioso en background: no bloquea el arranque.
  // Si hay datos nuevos en GitHub, se descargan y la próxima
  // pantalla que los pida verá la versión actualizada.
  RemoteDataService.checkAndUpdate();
  runApp(const B737ToolsApp());
}

class B737ToolsApp extends StatelessWidget {
  const B737ToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      // DARK MODE: follows the OS setting automatically
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0033A0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0033A0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DisclaimerScreen(),
    );
  }
}
