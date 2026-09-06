import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/screens.dart';
import 'theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FoliateApp());
}

class FoliateApp extends StatelessWidget {
  const FoliateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final appTheme = ref.watch(appThemeProvider);
          return MaterialApp(
            title: 'Foliate',
            debugShowCheckedModeBanner: false,
            theme: AdwaitaTheme.light(accentColor: appTheme.accent.color),
            darkTheme: AdwaitaTheme.dark(accentColor: appTheme.accent.color),
            themeMode: appTheme.mode,
            home: const MainShell(),
          );
        },
      ),
    );
  }
}


