import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/fuwa_colors.dart';
import 'presentation/screens/main_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置沉浸式透明状态栏
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: FuwaColors.pureWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const FuwaFuwaApp());
}

/// 「ふわふわ（FuwaFuwa）」主应用程序
/// 纯本地 Android 衣柜管理应用 · 甘系（Sweet Lolita）及日常穿搭数字化归档
class FuwaFuwaApp extends StatelessWidget {
  const FuwaFuwaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ふわふわ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: FuwaColors.creamWhite,
        primaryColor: FuwaColors.balletPink,
        colorScheme: const ColorScheme.light(
          primary: FuwaColors.balletPink,
          secondary: FuwaColors.sugarCandyGold,
          surface: FuwaColors.pureWhite,
          background: FuwaColors.creamWhite,
          onPrimary: Colors.white,
          onSurface: FuwaColors.chocolateDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: FuwaColors.creamWhite,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: FuwaColors.chocolateDark),
          titleTextStyle: TextStyle(
            color: FuwaColors.chocolateDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        dividerColor: FuwaColors.subtleBorder,
      ),
      home: const MainScaffold(),
    );
  }
}
