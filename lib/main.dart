import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'services/current_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: CurrentUser.instance,
      // MaterialApp yerine MaterialApp.router kullanıyoruz - bu, navigasyonu
      // go_router'a devretmek için gerekli. routerConfig: appRouter, tüm
      // route tanımlarını app_router.dart'tan alıyor.
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1E1233),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}