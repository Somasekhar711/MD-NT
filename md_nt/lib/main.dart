import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:md_nt/authentication/login_page.dart';
import 'package:md_nt/home/dashboard.dart';

void main() async {
  // 1. Ensures Flutter is ready to use platform plugins like shared_preferences
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Open the storage and look for saved user data
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');
  final String? userName = prefs.getString('userName');

  // 3. Start the app with the retrieved data
  runApp(MyApp(
    savedToken: token,
    savedName: userName,
  ));
}

class MyApp extends StatefulWidget {
  final String? savedToken;
  final String? savedName;

  const MyApp({super.key, this.savedToken, this.savedName});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),

      // 4. If token exists, go to Dashboard. Otherwise, go to Login.
      home: (widget.savedToken != null && widget.savedName != null)
          ? DashboardPage(
              toggleTheme: toggleTheme,
              userName: widget.savedName!,
            )
          : LoginPage(toggleTheme: toggleTheme),

      routes: {
        '/login': (context) => LoginPage(toggleTheme: toggleTheme),
      },
    );
  }
}