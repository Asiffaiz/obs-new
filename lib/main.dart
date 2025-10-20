import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:get_it/get_it.dart';
import 'package:voicealerts_obs/core/services/text_recognition_service.dart';
import 'package:voicealerts_obs/core/utils/http_interceptor.dart';
import 'package:go_router/go_router.dart';
import 'package:voicealerts_obs/features/agreements/data/services/agreements_service.dart';
import 'package:voicealerts_obs/features/auth/data/services/auth_service.dart';
import 'package:voicealerts_obs/features/auth/domain/repositories/auth_repository.dart';
import 'package:voicealerts_obs/features/bussiness%20card/domain/repositories/business_card_repository.dart';
import 'package:voicealerts_obs/features/bussiness%20card/presentation/bloc/business_card_bloc.dart';
import 'package:voicealerts_obs/features/dashboard/domain/Repositories/dashboard_repository.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/bloc/bloc/dashboard_bloc.dart';
import 'package:voicealerts_obs/features/documents/data/repositories/document_repository.dart';
import 'package:voicealerts_obs/features/documents/presentation/bloc/document_bloc.dart';
import 'package:voicealerts_obs/features/forms/domain/repositories/form_repository.dart';
import 'package:voicealerts_obs/features/forms/presentation/bloc/forms_bloc.dart';
import 'package:voicealerts_obs/features/products/data/repositories/product_repository.dart';
import 'package:voicealerts_obs/features/products/presentation/bloc/product_bloc.dart';
import 'package:voicealerts_obs/features/profile/data/repositories/profile_repository.dart';
import 'package:voicealerts_obs/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:voicealerts_obs/features/reports/domain/repositories/reports_repository.dart';
import 'package:voicealerts_obs/features/reports/presentation/bloc/reports_bloc.dart';

import 'firebase_options.dart';
import 'config/dependency_injection.dart';
import 'config/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/services/token_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/agreements/presentation/bloc/agreements_bloc.dart';
import 'features/agreements/data/repositories/mock_agreements_repository_impl.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // HttpInterceptor.navigatorKey = rootNavigatorKey;
  // Set preferred orientations
  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);

  // Set system UI overlay style for status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  await FlutterDownloader.initialize(
    debug: true, // show logs in console
    ignoreSsl: true, // allow http if needed
  );

  // Initialize Firebase
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize dependencies
  await initializeDependencies();

  // Initialize API token with error handling
  try {
    // Get the TokenService from dependency injection
    final tokenService = GetIt.I<TokenService>();
    final token = await tokenService.getAccessToken();
    if (token == null) {
      print(
        'WARNING: Failed to get initial access token. Some features may not work properly.',
      );
    } else {
      print('Successfully initialized API access token');
    }
  } catch (e) {
    print('Error initializing API token: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create AuthBloc instance first to ensure it's available throughout the app
    final authBloc = GetIt.I<AuthBloc>();
    final textRecognitionService = GetIt.I<TextRecognitionService>();
    final businessCardRepository = GetIt.I<BusinessCardRepository>();
    final authRepository = GetIt.I<AuthRepository>();
    final businessCardBloc = BusinessCardBloc(
      repository: businessCardRepository,
      textRecognitionService: textRecognitionService,
      authRepository: authRepository,
    );
    // Create the router
    final router = createRouter(authBloc);

    // Register the router with GetIt for use in HttpInterceptor
    if (!GetIt.I.isRegistered<GoRouter>()) {
      GetIt.I.registerSingleton<GoRouter>(router);
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => authBloc),
        BlocProvider<BusinessCardBloc>(create: (context) => businessCardBloc),
        BlocProvider<AgreementsBloc>(
          create:
              (context) => AgreementsBloc(
                agreementsRepository: MockAgreementsRepositoryImpl(
                  agreementsService: GetIt.I<AgreementService>(),
                ),
              ),
        ),

        BlocProvider<DashboardBloc>(
          create:
              (context) => DashboardBloc(
                dashboardRepository: GetIt.I<DashboardRepository>(),
              ),
        ),

        BlocProvider<ReportsBloc>(
          create:
              (context) =>
                  ReportsBloc(reportsRepository: GetIt.I<ReportsRepository>()),
        ),
        BlocProvider<FormsBloc>(
          create:
              (context) =>
                  FormsBloc(formsRepository: GetIt.I<FormsRepository>()),
        ),
        BlocProvider<DocumentBloc>(
          create:
              (context) => DocumentBloc(
                documentRepository: GetIt.I<DocumentRepository>(),
              ),
        ),
        BlocProvider<ProductBloc>(
          create:
              (context) =>
                  ProductBloc(productRepository: GetIt.I<ProductRepository>()),
        ),
        BlocProvider<ProfileBloc>(
          create:
              (context) =>
                  ProfileBloc(profileRepository: GetIt.I<ProfileRepository>()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Convoso',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
        builder: (context, child) {
          // Apply responsive breakpoints
          return ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: const [
              Breakpoint(start: 0, end: 450, name: MOBILE),
              Breakpoint(start: 451, end: 800, name: TABLET),
              Breakpoint(start: 801, end: 1920, name: DESKTOP),
              Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
          );
        },
      ),
    );
  }
}

/// Custom page transition switcher for smooth transitions
class PageTransitionSwitcher extends StatelessWidget {
  final Widget child;

  const PageTransitionSwitcher({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
