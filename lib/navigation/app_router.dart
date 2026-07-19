import 'package:chronex/model/run.dart';
import 'package:chronex/navigation/app_router_path.dart';
import 'package:chronex/presentation/active_run/active_run_track.dart';
import 'package:chronex/presentation/active_run/run_summary.dart';
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
    GoRoute(path: AppRouterPath.activeRunTrack, builder: (context, state) => const ActiveRunTrack()),
    GoRoute(
      path: AppRouterPath.runSummary,
      builder: (context, state) => RunSummary(run: state.extra as Run),
    ),
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
          routes: [GoRoute(path: AppRouterPath.history, builder: (context, state) => const HistoryPage())],
        ),
      ],
      builder: (context, state, navigationShell) => MainPage(child: navigationShell),
    ),
  ],
);
