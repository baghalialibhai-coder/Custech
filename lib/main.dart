// lib/main.dart

import 'package:custech/services/one_Signal_Service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'Presentations/Auth_Screens/splash_screen.dart';
import 'Presentations/user_detail_form/role_selection_screen.dart';
import 'Presentations/user_detail_form/user_info.dart';
import 'firebase_options.dart';
import 'languages/localization/app_localizations.dart';
import 'languages/localization/locale_provider.dart';
import 'languages/widget/language_selection_screen.dart';
import 'services/ai_matching_service.dart';
import 'services/localization_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'Presentations/Auth_Screens/login_screen.dart';
import 'Presentations/Auth_Screens/signup_screen.dart';
import 'Presentations/Auth_Screens/forget_password_screen.dart';
import 'Presentations/customer_screen/customer_dashboard.dart';
import 'Presentations/technicianscreen/Technician_dashboard.dart';
import 'Presentations/technicianscreen/technician_categories_screen.dart';
import 'Presentations/chat/Screens/chat_screen.dart';
import 'Presentations/chat/Screens/media_viewer_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load .env file
  await dotenv.load(fileName: ".env");

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Check MapBox token
  final String? mapBoxToken = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
  if (mapBoxToken != null && mapBoxToken.isNotEmpty) {
    print('✅ MAPBOX_PUBLIC_TOKEN found: ${mapBoxToken.substring(0, 10)}...');
  } else {
    print('❌ MAPBOX_PUBLIC_TOKEN not found in .env file');
  }

  // ✅ Initialize Gemini AI
  final String? apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey != null && apiKey.isNotEmpty) {
    AIMatchingService().initializeGemini(apiKey: apiKey);
    print('✅ Gemini AI initialized successfully');
  } else {
    print('❌ GEMINI_API_KEY not found in .env file');
  }

  // ✅ Check Google Maps API Key
  final String? googleMapsKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
  if (googleMapsKey != null && googleMapsKey.isNotEmpty) {
    print('✅ Google Maps API Key found');
  } else {
    print('❌ Google Maps API Key not found');
  }

  // ✅ Check OneSignal credentials
  _checkOneSignalCredentials();

  // ✅ Initialize OneSignal
  await OneSignalNotificationService.initialize();

  // ✅ Retry OneSignal ID after 3 seconds
  Future.delayed(const Duration(seconds: 3), () {
    OneSignalNotificationService.saveCurrentUserOneSignalId();
  });

  // ✅ Run App with Lifecycle Observer
  runApp(const ProviderScope(child: MyApp()));
}

// ✅ Check OneSignal Credentials
void _checkOneSignalCredentials() {
  final appId = dotenv.env['OneSignal_App_ID'] ?? '';
  final apiKey = dotenv.env['one_Signal_Api_Key'] ?? '';

  print('🔍 OneSignal Credentials Check:');
  print('App ID: ${appId.isNotEmpty ? appId.substring(0, 8) : 'MISSING'}... (Length: ${appId.length})');
  print('API Key: ${apiKey.isNotEmpty ? apiKey.substring(0, 8) : 'MISSING'}... (Length: ${apiKey.length})');

  if (appId.isEmpty || apiKey.isEmpty) {
    print('❌ OneSignal credentials MISSING!');
    print('💡 Add to .env file:');
    print('   OneSignal_App_ID=your_app_id');
    print('   one_Signal_Api_Key=your_rest_api_key');
  } else {
    print('✅ OneSignal credentials found');
  }
}

// ============================================================
// ✅ MY APP WITH LIFECYCLE OBSERVER
// ============================================================
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // ✅ Add lifecycle observer for notification handling
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // ✅ Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // ✅ Get locale from provider
    final localeState = ref.watch(localeProvider);
    final locale = localeState.locale;

    return MaterialApp(
      title: 'Custech',
      debugShowCheckedModeBanner: false,

      // ✅ Navigation Key
      navigatorKey: navigatorKey,

      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // ✅ THESE ARE REQUIRED FOR MATERIAL WIDGETS
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,

      // ✅ Theme
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),

      // ✅ Home
      home: const SplashScreen(),

      // ✅ Routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/role-select': (context) => const RoleSelectionScreen(),
        '/user-info': (context) => const UserInfoScreen(userRole: 'customer'),
        '/customer-dashboard': (context) => const CustomerDashboard(),
        '/technician-dashboard': (context) => const TechnicianDashboard(),
        '/technician-categories': (context) => const TechnicianCategoriesScreen(
          userName: '',
          phoneNumber: '',
          address: '',
          pincode: '',
          latitude: 0,
          longitude: 0,
          serviceRadius: 0,
        ),
        '/language-select': (context) => const LanguageSelectionScreen(),
        '/media-viewer': (context) => const MediaViewerScreen(
          url: '',
          isImage: true,
        ),
      },

      // ✅ Dynamic route handling
      onGenerateRoute: (settings) {
        // ✅ Chat screen with arguments
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => ChatScreen(
                taskId: args['taskId'] ?? '',
                taskTitle: args['taskTitle'] ?? 'Chat',
                otherUserName: args['otherUserName'] ?? 'User',
                otherUserId: args['otherUserId'] ?? '',
                otherUserImage: args['otherUserImage'],
                otherUserRole: args['otherUserRole'],
              ),
            );
          }
          return MaterialPageRoute(
            builder: (context) => const ChatScreen(
              taskId: '',
              taskTitle: 'Chat',
              otherUserName: 'User',
              otherUserId: '',
            ),
          );
        }

        // ✅ Media viewer with arguments
        if (settings.name == '/media-viewer') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => MediaViewerScreen(
                url: args['url'] ?? '',
                isImage: args['isImage'] ?? true,
                isAudio: args['isAudio'] ?? false,
              ),
            );
          }
        }

        // ✅ User info with role
        if (settings.name == '/user-info') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => UserInfoScreen(
                userRole: args['userRole'] ?? 'customer',
              ),
            );
          }
        }

        return null;
      },

      // ✅ Unknown route
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const NotFoundScreen(),
        );
      },
    );
  }
}

// ============================================================
// ✅ NOT FOUND SCREEN
// ============================================================
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Page Not Found',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The page you are looking for does not exist.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  'Go Back',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}