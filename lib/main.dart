import 'package:cinetrack_process/screens/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'data/movie_dao.dart';
import 'data/movie_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MovieDao().seedMoviesIfEmpty(dummyMovies);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1233),
      ),
      home: const LoginScreen(),
    );
  }
}