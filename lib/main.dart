import 'package:cinetrack_process/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/current_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider.value: mevcut singleton'ı (CurrentUser.instance)
    // Provider ağacına ekliyoruz. .value kullanıyoruz çünkü nesneyi burada
    // YENİ oluşturmuyoruz, zaten var olan singleton'ı paylaşıyoruz.
    //
    // Bundan sonra widget ağacındaki HERHANGİ bir yerden context.watch<CurrentUser>()
    // ile bu nesneyi dinleyebiliriz - user değiştiğinde o widget otomatik yeniden çizilir.
    return ChangeNotifierProvider.value(
      value: CurrentUser.instance,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1E1233),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}