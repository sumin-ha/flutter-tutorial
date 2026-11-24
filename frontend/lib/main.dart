import 'package:material_ui/material_ui.dart';

import 'bookmark_store.dart';
import 'repository.dart';
import 'home_screen.dart';
import 'bookmark_widgets.dart';

void main() => runApp(FoodmarksApp());

class FoodmarksApp extends StatefulWidget {
  final BookmarkRepository? repository;
  const FoodmarksApp({super.key, this.repository});
  @override
  State<FoodmarksApp> createState() => _FoodmarksAppState();
}

class _FoodmarksAppState extends State<FoodmarksApp> {
  late final BookmarkStore store;
  @override
  void initState() {
    super.initState();
    const demo = bool.fromEnvironment('DEMO_MODE');
    const api = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080/api',
    );
    store = BookmarkStore(
      widget.repository ?? (demo ? DemoRepository() : ApiRepository(api)),
    )..load();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '한입 수첩',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSansKR',
      colorScheme: ColorScheme.fromSeed(seedColor: accent).copyWith(
        primary: accent,
        onPrimary: Colors.white,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      dividerColor: softLine,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink),
        bodyLarge: TextStyle(color: ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: softLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: softLine),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9F6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Color(0xFFFFEEE6),
        height: 70,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    ),
    home: HomeScreen(store: store),
  );
}
