import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rana_jayeen/perm.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'firebase_options.dart';
import 'globel/var_glob.dart';
import 'infoHandller/app_info.dart';
import 'infoHandller/LanguageProvider.dart';
import 'l10n/app_localizations.dart';
import 'l10n/kab_material_localizations.dart';
import 'models/userModel.dart';
import 'notif/NotificationService.dart';
import 'page/navigation_home_screen.dart';
import 'page/splash_screen.dart';
import 'routes.dart';

String _getFontFamily(String? localeName) {
  switch (localeName) {
    case 'kab':
      return 'NotoSansTifinagh';
    case 'ar':
      return 'NotoSansArabic';
    default:
      return 'Inter';
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling background message: ${message.data}");
  await NotificationService().showBackgroundNotification(message.data);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
    with WidgetsBindingObserver, RestorationMixin {
  final RestorableString _lastRoute = RestorableString('');
  late final SharedPreferences _prefs;

  @override
  String? get restorationId => 'app_root_scope';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_lastRoute, 'last_route');
    if (oldBucket != null) {
      final lastRoute = oldBucket.read<String>('last_route');
      if (lastRoute != null &&
          lastRoute != '/' &&
          lastRoute != SplashScreen.routeName &&
          context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, lastRoute);
          debugPrint('Restored route: $lastRoute');
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lastRoute.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveAppState();
    } else if (state == AppLifecycleState.resumed) {
      _loadAppState();
    }
  }

  Future<void> _saveAppState() async {
    final currentRoute =
        ModalRoute.of(navigatorKey.currentContext!)?.settings.name;
    await _prefs.setString('last_route', currentRoute ?? '/');
    _lastRoute.value = currentRoute ?? '/';
    debugPrint('App state saved: route=$currentRoute');
  }

  Future<void> _loadAppState() async {
    final lastRoute = _prefs.getString('last_route');
    if (lastRoute != null &&
        lastRoute != '/' &&
        lastRoute != SplashScreen.routeName &&
        context.mounted) {
      Navigator.pushReplacementNamed(context, lastRoute);
      _lastRoute.value = lastRoute;
      debugPrint('Restored route: $lastRoute');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppInfo()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationService().initialize(context);
            PermissionService.requestPermission(
                Permission.locationWhenInUse, context);
          });
          return RestorationScope(
            restorationId: restorationId,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Rana Jayeen',
              theme: _buildThemeData(languageProvider.locale.languageCode),
              locale: languageProvider.locale,
              supportedLocales: const [
                Locale('en'),
                Locale('fr'),
                Locale('ar'),
                Locale('kab'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                KabMaterialLocalizationsDelegate(),
                //   KabCupertinoLocalizationsDelegate(),
              ],
              localeResolutionCallback: (locale, supportedLocales) =>
                  languageProvider.locale,
              home: const AuthCheck(),
              routes: routes,
              navigatorKey: navigatorKey,
            ),
          );
        },
      ),
    );
  }

  ThemeData _buildThemeData(String localeCode) {
    return lightTheme(context).copyWith(
      scaffoldBackgroundColor: kBackground,
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontFamily: _getFontFamily(localeCode),
          color: const Color.fromARGB(255, 253, 253, 253),
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          fontFamily: _getFontFamily(localeCode),
          color: kTextPrimary.withOpacity(0.8),
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        titleLarge: TextStyle(
          fontFamily: _getFontFamily(localeCode),
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: kTextPrimary,
        ),
        labelLarge: TextStyle(
          fontFamily: _getFontFamily(localeCode),
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: kPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: kPrimary,
          shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck>
    with TickerProviderStateMixin, RestorationMixin {
  String? _userToken;
  bool _isLoading = true;
  String? _errorMessage;
  int _retryCount = 0;
  final int _maxRetries = 3;
  String _loadingMessage = '';
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _progressController;
  final _storage = const FlutterSecureStorage();
  late final SharedPreferences _prefs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Restorable properties
  final _restorableUserToken = RestorableStringN(null);
  final _restorableIsLoading = RestorableBool(true);
  final _restorableErrorMessage = RestorableStringN(null);
  final _restorableRetryCount = RestorableInt(0);
  final _restorableLoadingMessage = RestorableString('');

  @override
  String? get restorationId => 'auth_check';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restorableUserToken, 'user_token');
    registerForRestoration(_restorableIsLoading, 'is_loading');
    registerForRestoration(_restorableErrorMessage, 'error_message');
    registerForRestoration(_restorableRetryCount, 'retry_count');
    registerForRestoration(_restorableLoadingMessage, 'loading_message');

    if (oldBucket != null) {
      _userToken =
          _restorableUserToken.value ?? oldBucket.read<String?>('user_token');
      _isLoading = _restorableIsLoading.value;
      _errorMessage = _restorableErrorMessage.value ??
          oldBucket.read<String?>('error_message');
      _retryCount = _restorableRetryCount.value;
      _loadingMessage = _restorableLoadingMessage.value;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(duration: kAnimationDuration, vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _progressController =
        AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _animationController.forward();
    _initPrefs();
    _setupConnectivityListener();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkUserLoginStatus());
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .debounceTime(const Duration(seconds: 1))
        .listen((results) {
      if (!results.contains(ConnectivityResult.none) &&
          _errorMessage != null &&
          mounted) {
        setState(() {
          _isLoading = true;
          _restorableIsLoading.value = true;
          _errorMessage = null;
          _restorableErrorMessage.value = null;
          _loadingMessage = AppLocalizations.of(context)?.checkingNetwork ??
              'Checking network...';
          _restorableLoadingMessage.value = _loadingMessage;
          _progressController.repeat();
        });
        _checkUserLoginStatus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadingMessage =
        AppLocalizations.of(context)?.checkingNetwork ?? 'Checking network...';
    _restorableLoadingMessage.value = _loadingMessage;
  }

  Future<void> _checkUserLoginStatus() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final cachedUserData = _prefs.getString('cachedUserData');

      // Handle cached data for offline mode
      if (cachedUserData != null && mounted) {
        await _handleCachedUserData(cachedUserData, connectivityResult);
        if (connectivityResult.contains(ConnectivityResult.none)) return;
      }

      if (connectivityResult.contains(ConnectivityResult.none)) {
        _handleNoInternet();
        return;
      }

      final token = await _storage.read(key: 'userToken');
      if (token == null) {
        await _prefs.remove('userId');
        _navigateToSplashScreen();
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      final fcmFuture = _requestFcmToken();
      final userRef =
          FirebaseDatabase.instance.ref().child('auth_user').child(token);
      final snap = await userRef.once().timeout(
            const Duration(seconds: 2),
            onTimeout: () =>
                throw TimeoutException('Failed to fetch user data'),
          );

      if (snap.snapshot.value == null || !mounted) {
        await _prefs.remove('userId');
        _navigateToSplashScreen();
        return;
      }

      final userData = UserModer.fromSnapshot(snap.snapshot);
      await _prefs.setString('userId', user?.uid ?? token);
      await _prefs.setString('cachedUserData', jsonEncode(userData.toJson()));

      await _handleFcmToken(fcmFuture, userRef, token);
      if (user != null && user.uid == token && mounted) {
        setState(() {
          userModelCurrentInfo = userData;
          currentUser = user;
          _userToken = token;
          _restorableUserToken.value = token;
          _isLoading = false;
          _restorableIsLoading.value = false;
          _progressController.stop();
        });
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          await userRef.update(
              {'fcmToken': newToken, 'lastUpdated': ServerValue.timestamp});
          debugPrint('FCM token refreshed for user: $token');
          unawaited(NotificationService().retryPendingNotifications(token));
        });
      } else {
        await _prefs.remove('userId');
        _navigateToSplashScreen();
      }
    } catch (e, stackTrace) {
      await _handleAuthError(e, stackTrace);
    }
  }

  Future<void> _handleCachedUserData(String cachedUserData,
      List<ConnectivityResult> connectivityResult) async {
    try {
      final cachedUser = UserModer.fromJson(cachedUserData);
      setState(() {
        userModelCurrentInfo = cachedUser;
        _userToken = _prefs.getString('userId');
        _restorableUserToken.value = _userToken;
      });
      if (connectivityResult.contains(ConnectivityResult.none)) {
        setState(() {
          _isLoading = false;
          _restorableIsLoading.value = false;
          _progressController.stop();
        });
        Provider.of<AppInfo>(context, listen: false).setOfflineMode(true);
        if (mounted) {
          _showSnackBar(
            AppLocalizations.of(context)?.noInternetConnectionWithCache ??
                'No internet. Using offline mode.',
            duration: const Duration(seconds: 3),
          );
          Navigator.pushReplacementNamed(
              context, NavigationHomeScreen.routeName);
        }
        unawaited(_syncUserDataInBackground());
      }
    } catch (jsonError) {
      debugPrint('Error parsing cached user data: $jsonError');
    }
  }

  void _handleNoInternet() {
    setState(() {
      _isLoading = false;
      _restorableIsLoading.value = false;
      _errorMessage = AppLocalizations.of(context)?.noInternetConnection ??
          'No internet connection. Please enable Wi-Fi or mobile data and try again.';
      _restorableErrorMessage.value = _errorMessage;
      _progressController.stop();
    });
  }

  void _navigateToSplashScreen() {
    setState(() {
      _userToken = null;
      _restorableUserToken.value = null;
      _isLoading = false;
      _restorableIsLoading.value = false;
      _progressController.stop();
    });
    Navigator.pushReplacementNamed(context, SplashScreen.routeName);
  }

  Future<String?> _requestFcmToken() async {
    final settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      return FirebaseMessaging.instance.getToken();
    }
    return null;
  }

  Future<void> _handleFcmToken(Future<String?> fcmFuture,
      DatabaseReference userRef, String token) async {
    final fcmToken = await fcmFuture;
    if (fcmToken != null) {
      await userRef
          .update({'fcmToken': fcmToken, 'lastUpdated': ServerValue.timestamp});
      debugPrint('FCM token updated for user: $token');
      unawaited(NotificationService().retryPendingNotifications(token));
    } else if (mounted) {
      _showSnackBar(
        AppLocalizations.of(context)?.enable_notifications ??
            'Please enable notifications',
        actionLabel: AppLocalizations.of(context)?.settings ?? 'Settings',
        action: openAppSettings,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _handleAuthError(dynamic e, StackTrace stackTrace) async {
    debugPrint('Error fetching user data: $e\nStackTrace: $stackTrace');
    final cachedUserData = _prefs.getString('cachedUserData');
    if (cachedUserData != null && mounted) {
      await _handleCachedUserData(cachedUserData, [ConnectivityResult.none]);
      return;
    }
    if (_retryCount < _maxRetries && mounted) {
      await Future.delayed(Duration(milliseconds: 500 * (1 << _retryCount)));
      _retryCount++;
      _restorableRetryCount.value = _retryCount;
      _checkUserLoginStatus();
      return;
    }
    if (mounted) {
      await _prefs.remove('userId');
      setState(() {
        _userToken = null;
        _restorableUserToken.value = null;
        _isLoading = false;
        _restorableIsLoading.value = false;
        _errorMessage = e is TimeoutException
            ? (AppLocalizations.of(context)?.serverTimeout ??
                'Server took too long to respond. Please try again.')
            : (AppLocalizations.of(context)?.authError ??
                'Failed to verify login. Please try again.');
        _restorableErrorMessage.value = _errorMessage;
        _progressController.stop();
      });
    }
  }

  Future<void> _syncUserDataInBackground() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) return;

      final token = await _storage.read(key: 'userToken');
      if (token == null) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != token) return;

      final userRef =
          FirebaseDatabase.instance.ref().child('auth_user').child(token);
      final snap = await userRef.once().timeout(
            const Duration(seconds: 2),
            onTimeout: () => throw TimeoutException('Failed to sync user data'),
          );

      if (snap.snapshot.value != null && mounted) {
        final userData = UserModer.fromSnapshot(snap.snapshot);
        await _prefs.setString('cachedUserData', jsonEncode(userData.toJson()));
        await _prefs.setString('userId', user.uid);
        debugPrint('Background sync completed for user: $token');
        Provider.of<AppInfo>(context, listen: false).setOfflineMode(false);
        if (mounted) {
          _showSnackBar(
            AppLocalizations.of(context)?.dataSynced ??
                'Your data has been updated.',
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Background sync error: $e\nStackTrace: $stackTrace');
    }
  }

  void _showSnackBar(String message,
      {String? actionLabel,
      VoidCallback? action,
      Duration duration = const Duration(seconds: 3)}) {
    final lang = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: _getFontFamily(lang?.localeName),
            color: kTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
        duration: duration,
        action: action != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: action,
                textColor: kPrimary,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);
    if (_isLoading) {
      if (!_progressController.isAnimating) _progressController.repeat();
      return _buildLoadingScreen(lang);
    }

    if (_errorMessage != null) {
      if (_progressController.isAnimating) _progressController.stop();
      return _buildErrorScreen(lang);
    }

    if (_progressController.isAnimating) _progressController.stop();
    return _userToken != null
        ? const NavigationHomeScreen()
        : const SplashScreen();
  }

  Widget _buildLoadingScreen(AppLocalizations? lang) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kModernGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: kBorderRadius,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loadingMessage,
                    style: TextStyle(
                      fontFamily: _getFontFamily(lang?.localeName),
                      color: kTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    semanticsLabel: _loadingMessage,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(AppLocalizations? lang) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kModernGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: kBorderRadius,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 60,
                    color: kPrimary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontFamily: _getFontFamily(lang?.localeName),
                      fontSize: 16,
                      color: kTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    semanticsLabel: _errorMessage,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _restorableIsLoading.value = true;
                        _errorMessage = null;
                        _restorableErrorMessage.value = null;
                        _loadingMessage =
                            lang?.checkingNetwork ?? 'Checking network...';
                        _restorableLoadingMessage.value = _loadingMessage;
                        _retryCount = 0;
                        _restorableRetryCount.value = 0;
                      });
                      _checkUserLoginStatus();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape:
                          RoundedRectangleBorder(borderRadius: kBorderRadius),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      lang?.retry ?? 'Retry',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _connectivitySubscription?.cancel();
    _restorableUserToken.dispose();
    _restorableIsLoading.dispose();
    _restorableErrorMessage.dispose();
    _restorableRetryCount.dispose();
    _restorableLoadingMessage.dispose();
    super.dispose();
  }
}
