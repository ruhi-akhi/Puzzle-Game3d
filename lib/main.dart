import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/services/audio_service.dart';
import 'game/services/progress_service.dart';
import 'theme/app_theme.dart';
import 'ui/screens/menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioService.init();
  await ProgressService.syncFromStars();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const EchoLabyrinthApp());
}

class EchoLabyrinthApp extends StatelessWidget {
  const EchoLabyrinthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echo Labyrinth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkSciFi,
      home: const MenuScreen(),
    );
  }
}
