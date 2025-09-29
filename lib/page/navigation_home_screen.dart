import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rana_jayeen/globel/var_glob.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rana_jayeen/constants.dart' as AppColors;
import 'package:rana_jayeen/globel/assistant_methods.dart';
import 'package:rana_jayeen/infoHandller/app_info.dart';
import 'package:rana_jayeen/l10n/language_dialog.dart';
import 'package:rana_jayeen/models/direction.dart';
import 'package:rana_jayeen/page/MapScreen.dart';
import 'package:rana_jayeen/page/tips.dart';
import 'package:rana_jayeen/notif/ChatScreen.dart';
import 'package:rana_jayeen/page/feedback.dart';
import 'package:rana_jayeen/page/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badges/badges.dart' as badges;
import 'package:connectivity_plus/connectivity_plus.dart';

class NavigationHomeScreen extends StatefulWidget {
  static const String routeName = "/navig";
  const NavigationHomeScreen({super.key});

  @override
  _NavigationHomeScreenState createState() => _NavigationHomeScreenState();
}

class _NavigationHomeScreenState extends State<NavigationHomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _drawerController;
  late AnimationController _menuIconController;
  late Animation<double> _menuIconScaleAnimation;
  late Animation<double> _fadeAnimation;
  late List<Animation<double>> _drawerItemAnimations;
  final ValueNotifier<int> _greetingIndex = ValueNotifier(0);
  int _unreadCount = 0;
  Position? currentPositionUser;
  bool _hasShownTutorial = false;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const CarFixesTipsScreen(),
    UnifiedScreen(),
    const ChatsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUnreadCount();
    _checkConnectivityAndLocation();
    // _checkTutorial();
  }

  void _initializeAnimations() {
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // Faster animation
    );
    _drawerItemAnimations = List.generate(
      6,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _drawerController,
          curve:
              Interval(0.1 * index, 0.4 + 0.1 * index, curve: Curves.easeOut),
        ),
      ),
    );

    _menuIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // Faster animation
    );
    _menuIconScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _menuIconController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _menuIconController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Periodic greeting update
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _greetingIndex.value = (_greetingIndex.value + 1) % 3;
      }
    });
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    _hasShownTutorial = prefs.getBool('hasShownTutorial') ?? false;
    if (!_hasShownTutorial && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CarFixesTipsScreen()),
        );
        prefs.setBool('hasShownTutorial', true);
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('unreadCount_${userModelCurrentInfo?.id}') ?? 0;
    if (mounted) {
      setState(() => _unreadCount = count);
    }
  }

  Future<void> _checkConnectivityAndLocation() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);
    if (isOffline && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.noInternetConnectionWithCache ??
                'No internet. Using offline mode.',
            style: const TextStyle(
              fontFamily: 'WorkSans',
              color: AppColors.kTextPrimary,
              fontSize: 14,
            ),
          ),
          backgroundColor: AppColors.kBackground,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      getCurrentLocation();
    }
  }

  Future<void> getCurrentLocation() async {
    AssistantMethodes.readCurrentOnlineUser();
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDialog(false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      bool? shouldRequest = await _showLocationDialog(true);
      if (shouldRequest == true) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationDialog(true);
          return;
        }
      } else {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSettingsDialog();
      return;
    }

    try {
      Position positionUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() => currentPositionUser = positionUser);
        await getAddressFromLatLng();
      }
    } catch (e) {
      debugPrint("Error getting current location: $e");
      _showErrorSnackBar(
        AppLocalizations.of(context)?.locationError ??
            'Failed to get location. Please try again.',
      );
    }
  }

  Future<void> getAddressFromLatLng() async {
    if (currentPositionUser == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        currentPositionUser!.latitude,
        currentPositionUser!.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty && mounted) {
        Placemark placemark = placemarks.first;
        String humanReadableAddress =
            placemark.street ?? placemark.name ?? 'Unknown';

        Directions userPickUpAddress = Directions()
          ..locationLatitude = currentPositionUser!.latitude
          ..locationLongitude = currentPositionUser!.longitude
          ..locationName = humanReadableAddress;

        Provider.of<AppInfo>(context, listen: false)
            .updatePickUpLocationAddress(userPickUpAddress);
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
      _showErrorSnackBar(
        AppLocalizations.of(context)?.locationError ??
            'Failed to get address. Please try again.',
      );
    }
  }

  Future<bool?> _showLocationDialog(bool isRequestable) async {
    final lang = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.kSurface.withOpacity(0.95),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.locationPermission,
              style: const TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.kTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isRequestable
                  ? lang.locationPermissionMessage
                  : lang.locationServiceDisabled,
              style: const TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.kTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    lang.cancel,
                    style: const TextStyle(
                      fontFamily: 'WorkSans',
                      fontSize: 14,
                      color: AppColors.kTextPrimary,
                    ),
                  ),
                ),
                if (isRequestable)
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      lang.allow,
                      style: const TextStyle(
                        fontFamily: 'WorkSans',
                        fontSize: 14,
                        color: AppColors.kPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSettingsDialog() async {
    final lang = AppLocalizations.of(context)!;
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.kSurface.withOpacity(0.95),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.locationPermission,
              style: const TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.kTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              lang.locationPermissionMessage,
              style: const TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.kTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    lang.cancel ?? 'Cancel',
                    style: const TextStyle(
                      fontFamily: 'WorkSans',
                      fontSize: 14,
                      color: AppColors.kTextPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Geolocator.openAppSettings();
                  },
                  child: Text(
                    lang.settings ?? 'Settings',
                    style: const TextStyle(
                      fontFamily: 'WorkSans',
                      fontSize: 14,
                      color: AppColors.kPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'WorkSans',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: AppColors.kError,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userToken');
      await prefs.remove('unreadCount_${userModelCurrentInfo?.id}');
      userModelCurrentInfo = null;
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/splash');
      }
    } catch (e) {
      _showErrorSnackBar(
        AppLocalizations.of(context)?.logoutError ??
            'Logout failed. Try again.',
      );
    }
  }

  String _getGreeting(AppLocalizations lang, String? userName) {
    switch (_greetingIndex.value) {
      case 0:
        return userName?.isNotEmpty ?? false
            ? lang.greetingPersonal(userName!)
            : lang.guest;
      case 1:
        return lang.weAreHereToHelp;
      case 2:
        return lang.greetingAvailability;
      default:
        return lang.greetingPersonal(userName ?? 'User');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final user = userModelCurrentInfo;
    final isOffline = Provider.of<AppInfo>(context).isOffline;

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          kToolbarHeight + MediaQuery.of(context).padding.top,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.kPrimaryGradientColor,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => GestureDetector(
                      onTapDown: (_) => _menuIconController.forward(),
                      onTapUp: (_) => _menuIconController.reverse(),
                      onTapCancel: () => _menuIconController.reverse(),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Scaffold.of(context).openDrawer();
                        _drawerController.forward();
                      },
                      child: ScaleTransition(
                        scale: _menuIconScaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.kPrimaryColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.menu_outlined,
                            color: Colors.white,
                            size: 26,
                            semanticLabel: lang.openMenu,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: _greetingIndex,
                    builder: (context, index, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          _getGreeting(lang, user?.first),
                          style: const TextStyle(
                            fontFamily: 'WorkSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.language_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black.withOpacity(0.5),
                        builder: (context) => const LanguageDialog(),
                      );
                    },
                    tooltip: lang.chooseLanguage,
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: _buildNavigationDrawer(context, lang),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200), // Faster transition
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: isOffline && (_selectedIndex == 1 || _selectedIndex == 4)
            ? _buildOfflinePlaceholder(lang)
            : _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.kPrimaryColor,
          unselectedItemColor: AppColors.kTextSecondary,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'WorkSans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'WorkSans',
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (isOffline && (index == 1 || index == 4)) {
              _showErrorSnackBar(
                lang.noInternetConnection,
              );
              return;
            }
            _onItemTapped(index);
          },
          items: [
            _buildNavItem(
              Icons.home_outlined,
              lang.home,
              0,
            ),
            _buildNavItem(
              Icons.map_outlined,
              lang.map,
              1,
            ),
            _buildNavItem(
              Icons.tips_and_updates_outlined,
              lang.advice,
              2,
            ),
            _buildNavItem(
              Icons.support_agent_outlined,
              lang.help,
              3,
            ),
            _buildNavItem(
              Icons.chat_bubble_outlined,
              lang.chat,
              4,
              badgeCount: _unreadCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflinePlaceholder(AppLocalizations lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 60,
              color: AppColors.kPrimaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              lang.noInternetConnection,
              style: const TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.kTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _checkConnectivityAndLocation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                lang.retry,
                style: const TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index, {
    int badgeCount = 0,
  }) {
    final isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: badges.Badge(
        showBadge: badgeCount > 0,
        badgeContent: Text(
          badgeCount.toString(),
          style: const TextStyle(
            fontFamily: 'WorkSans',
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        badgeStyle: badges.BadgeStyle(
          badgeColor: AppColors.kError,
          padding: const EdgeInsets.all(5),
          borderRadius: BorderRadius.circular(10),
        ),
        position: badges.BadgePosition.topEnd(top: -10, end: -10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? AppColors.kPrimaryColor.withOpacity(0.2)
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: isSelected ? 28 : 24,
            color:
                isSelected ? AppColors.kPrimaryColor : AppColors.kTextSecondary,
            semanticLabel: label,
          ),
        ),
      ),
      label: label,
    );
  }

  Widget _buildNavigationDrawer(BuildContext context, AppLocalizations lang) {
    final user = userModelCurrentInfo;
    return Drawer(
      backgroundColor: AppColors.kSurface.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: AppColors.kPrimaryGradientColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: Text(
                    user?.first?.isNotEmpty ?? false
                        ? user!.first![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontFamily: 'WorkSans',
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.first?.isNotEmpty ?? false ? user!.first! : lang.guest,
                  style: const TextStyle(
                    fontFamily: 'WorkSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  user?.phone ?? lang.noPhone,
                  style: TextStyle(
                    fontFamily: 'WorkSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home_outlined,
            title: lang.home,
            isSelected: _selectedIndex == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 0);
            },
            animation: _drawerItemAnimations[0],
          ),
          _buildDrawerItem(
            context,
            icon: Icons.map_outlined,
            title: lang.map,
            isSelected: _selectedIndex == 1,
            onTap: () {
              if (Provider.of<AppInfo>(context, listen: false).isOffline) {
                _showErrorSnackBar(
                  lang.noInternetConnection,
                );
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context);
              setState(() => _selectedIndex = 1);
            },
            animation: _drawerItemAnimations[1],
          ),
          _buildDrawerItem(
            context,
            icon: Icons.tips_and_updates_outlined,
            title: lang.advice,
            isSelected: _selectedIndex == 2,
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
            },
            animation: _drawerItemAnimations[2],
          ),
          _buildDrawerItem(
            context,
            icon: Icons.support_agent_outlined,
            title: lang.help ?? 'Help',
            isSelected: _selectedIndex == 3,
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 3);
            },
            animation: _drawerItemAnimations[3],
          ),
          _buildDrawerItem(
            context,
            icon: Icons.chat_bubble_outlined,
            title: lang.chat,
            isSelected: _selectedIndex == 4,
            onTap: () {
              if (Provider.of<AppInfo>(context, listen: false).isOffline) {
                _showErrorSnackBar(
                  lang.noInternetConnection,
                );
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context);
              setState(() => _selectedIndex = 4);
            },
            animation: _drawerItemAnimations[4],
            badgeCount: _unreadCount,
          ),
          Divider(color: Colors.white.withOpacity(0.2), height: 16),
          _buildDrawerItem(
            context,
            icon: Icons.logout_outlined,
            title: lang.logout,
            isSelected: false,
            onTap: _logout,
            color: AppColors.kError,
            animation: _drawerItemAnimations[5],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Animation<double> animation,
    Color? color,
    int badgeCount = 0,
    bool isSelected = false,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(animation),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Icon(
              icon,
              color: color ??
                  (isSelected
                      ? AppColors.kPrimaryColor
                      : AppColors.kTextPrimary),
              size: 26,
            ),
            title: Text(
              title,
              style: TextStyle(
                fontFamily: 'WorkSans',
                color: color ??
                    (isSelected
                        ? AppColors.kPrimaryColor
                        : AppColors.kTextPrimary),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor:
                isSelected ? AppColors.kPrimaryColor.withOpacity(0.1) : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            trailing: badgeCount > 0
                ? badges.Badge(
                    badgeContent: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        fontFamily: 'WorkSans',
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    badgeStyle: badges.BadgeStyle(
                      badgeColor: AppColors.kError,
                      padding: const EdgeInsets.all(5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    position: badges.BadgePosition.topEnd(top: -8, end: -8),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _menuIconController.dispose();
    _greetingIndex.dispose();
    super.dispose();
  }
}
