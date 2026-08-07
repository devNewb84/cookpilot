import 'package:flutter/material.dart';
import 'menu_screen.dart';
import 'database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cook Pilot',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFE8F5E9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 144, 202, 149),
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
      ),
      home: const MenuScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My App'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Three buttons row at the top of the body
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8E6C9),
                  ),
                  child: const Text(
                    'Button 1',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8E6C9),
                  ),
                  child: const Text(
                    'Button 2',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8E6C9),
                  ),
                  child: const Text(
                    'Button 3',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
            // Centered content
            const Expanded(
              child: Center(
                child: Text(
                  'Hello World',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
