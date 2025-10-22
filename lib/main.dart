import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 데스크톱 창 컨트롤 초기화 + 시작부터 풀스크린
  await windowManager.ensureInitialized();
  const opts = WindowOptions(
    title: '꼬미와 알록달록 채소 과일',
    backgroundColor: Colors.transparent,
    fullScreen: false,
  );
  windowManager.waitUntilReadyToShow(opts, () async {
    // await windowManager.setFullScreen(true);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const BaseApp());
}

class BaseApp extends StatelessWidget {
  const BaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '꼬미와 알록달록 채소 과일',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
