import 'package:chronex/navigation/app_router_path.dart';
import 'package:chronex/presentation/main/histrory_page.dart';
import 'package:chronex/presentation/main/home_page.dart';
import 'package:chronex/presentation/main/main_page.dart';
import 'package:chronex/presentation/main/connection_page.dart';
import 'package:chronex/presentation/main/profile_page.dart';
import 'package:chronex/presentation/onboard/personal_information_screen.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: AppRouterPath.initial,
  routes: [
    GoRoute(path: AppRouterPath.initial, builder: (context, state) => const PersonalInformation()),
    StatefulShellRoute.indexedStack(
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: AppRouterPath.home, builder: (context, state) => const HomePage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: AppRouterPath.connection, builder: (context, state) => const ConnectionPage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: AppRouterPath.profile, builder: (context, state) => const ProfilePage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: AppRouterPath.history, builder: (context, state) => const HistroryPage())],
        ),
      ],
      builder: (context, state, navigationShell) => MainPage(child: navigationShell),
    ),
  ],
);
