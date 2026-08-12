import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/account_screen.dart';
import 'screens/movie_detail_screen.dart';
import 'screens/list_detail_screen.dart';

// Tum route'lar burada, tek bir yerde tanimli. Java/Spring tarafindaki
// @RequestMapping ile path tanimlamaya benziyor - her ekranin path'i
// burada net bir sekilde goruluyor, kod icinde dagilmiyor.
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountScreen(),
    ),
    // :id path parametresi - ornegin /movie/42 -> movieId = 42
    // Bu sayede gercek deep linking mumkun: bir link uzerinden dogrudan
    // bu path'e gidildiginde, MovieDetailScreen id'den filmi kendi
    // veritabaninda arayip gosteriyor (widget nesnesi disaridan tasinmiyor).
    GoRoute(
      path: '/movie/:id',
      builder: (context, state) {
        final movieId = int.parse(state.pathParameters['id']!);
        return MovieDetailScreen(movieId: movieId);
      },
    ),
    GoRoute(
      path: '/list/:id',
      builder: (context, state) {
        final listId = int.parse(state.pathParameters['id']!);
        return ListDetailScreen(listId: listId);
      },
    ),
  ],
);