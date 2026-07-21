import 'package:chronex/base/theme/app_theme.dart';
import 'package:chronex/model/pace_split_data.dart';
import 'package:chronex/model/run.dart';
import 'package:chronex/model/user_profile.dart';
import 'package:chronex/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(RunAdapter());
  Hive.registerAdapter(PaceSplitDataAdapter());
  await Hive.openBox('profileBox');
  await Hive.openBox('runBox');
  await Hive.openBox('paceSplitBox');
  runApp(const ProviderScope(child: MyApp()));
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      useInheritedMediaQuery: true,
      minTextAdapt: true,
      designSize: const Size(412, 927),
      splitScreenMode: false,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowMaterialGrid: false,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          title: "Chronex",
          routerConfig: appRouter,
          theme: AppTheme.lightTheme(context),
          themeMode: ThemeMode.light,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.noScaling),
              child: AnnotatedRegion(
                value: SystemUiOverlayStyle.light,
                child: child!,
              ),
            );
          },
        );
      },
    );
  }
}
