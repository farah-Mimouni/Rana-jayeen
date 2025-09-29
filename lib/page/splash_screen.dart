import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/infoHandller/LanguageProvider.dart';
import 'package:rana_jayeen/l10n/app_localizations_en.dart';
import 'package:rana_jayeen/l10n/language_dialog.dart';
import 'package:rana_jayeen/page/auth.dart';

import 'package:provider/provider.dart';

// Constants with more white space
const _animationDuration = Duration(milliseconds: 600);
const _pageTransitionDuration = Duration(milliseconds: 400);
const _buttonHeight = 56.0;
const _dotHeight = 32.0;
const _horizontalPadding = 32.0;
const _verticalPadding = 24.0;
const _contentSpacing = 24.0;

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  late PageController _pageController;
  late AnimationController _buttonController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _buttonAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialAnimations();
  }

  void _initializeAnimations() {
    _pageController = PageController();

    _buttonController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _buttonAnimation = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOutBack,
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: _animationDuration ~/ 2,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuint),
    );
  }

  void _startInitialAnimations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
        _buttonController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    HapticFeedback.lightImpact();
    _resetAndRestartAnimations();
  }

  void _resetAndRestartAnimations() {
    _fadeController.reset();
    _slideController.reset();
    _buttonController.reset();
    _fadeController.forward();
    _slideController.forward();
    _buttonController.forward();
  }

  void _navigateToNextPage() {
    if (_currentPage == _getSplashData().length - 1) {
      Navigator.pushReplacementNamed(context, CompleteProfileScreen.routeName);
    } else {
      _pageController.nextPage(
        duration: _pageTransitionDuration,
        curve: Curves.easeInOutCubicEmphasized,
      );
    }
  }

  List<Map<String, dynamic>> _getSplashData() {
    final locale = AppLocalizations.of(context);
    if (locale == null) return [];

    return [
      {
        'title': locale.welcome1Title,
        'text': locale.welcome1Desc,
        'image': 'assets/images/03e2fb6e8d44cb56fed5d1df0051ee91.gif',
        'color': Color.fromARGB(255, 53, 197, 197),
        'gradient': [
          Color.fromARGB(255, 79, 243, 255),
          const Color(0xFF8B78FF)
        ],
      },
      {
        'title': locale.welcome2Title,
        'text': locale.welcome2Desc,
        'image': 'assets/images/cf6fcf14be2cd01dd4923b36445ca632.gif',
        'color': const Color.fromARGB(255, 75, 192, 207),
        'gradient': [
          const Color.fromRGBO(87, 193, 214, 1),
          const Color.fromARGB(255, 11, 146, 155)
        ],
      },
      {
        'title': locale.welcome3Title,
        'text': locale.welcome3Desc,
        'image': 'assets/images/13893666.gif',
        'color': const Color.fromARGB(255, 0, 233, 245),
        'gradient': [
          const Color.fromARGB(255, 0, 216, 245),
          const Color.fromARGB(255, 0, 213, 255)
        ],
      },
      {
        'title': locale.welcome4Title,
        'text': locale.welcome4Desc,
        'image': 'assets/images/sg-blog-trdshw-pr-p1.gif',
        'color': const Color(0xFF0288D1),
        'gradient': [const Color(0xFF0288D1), const Color(0xFF03A9F4)],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final splashData = _getSplashData();
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    if (locale == null) {
      return _buildLoadingScreen(theme);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: FadeTransition(
          opacity: _fadeAnimation,
          child: IconButton(
            icon: Icon(
              Icons.language,
              color: splashData[_currentPage]['color'],
            ),
            onPressed: () => showDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.4),
              builder: (context) => const LanguageDialog(),
            ),
            tooltip: locale.chooseLanguage,
          ),
        ),
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Semantics(
            label: 'Page ${_currentPage + 1} of ${splashData.length}',
            child: Text(
              '${_currentPage + 1}/${splashData.length}',
              style: TextStyle(
                color: splashData[_currentPage]['color'],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          if (_currentPage != splashData.length - 1)
            FadeTransition(
              opacity: _fadeAnimation,
              child: TextButton(
                onPressed: () => _pageController.animateToPage(
                  splashData.length - 1,
                  duration: _pageTransitionDuration,
                  curve: Curves.easeInOutCubic,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: splashData[_currentPage]['color'],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  locale.skipButton,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildMainContent(splashData),
            ),
            _buildBottomSection(splashData, locale, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(List<Map<String, dynamic>> splashData) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: splashData.length,
      itemBuilder: (_, index) => FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: OptimizedSplashContent(
            image: splashData[index]['image'],
            text: splashData[index]['text'],
            title: splashData[index]['title'],
            color: splashData[index]['color'],
            gradient: splashData[index]['gradient'],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(
    List<Map<String, dynamic>> splashData,
    AppLocalizations locale,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: _verticalPadding,
      ),
      child: Column(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildDotIndicators(splashData.length, theme),
          ),
          const SizedBox(height: _contentSpacing),
          ScaleTransition(
            scale: _buttonAnimation,
            child: _buildContinueButton(splashData, locale, theme),
          ),
          const SizedBox(height: _contentSpacing),
        ],
      ),
    );
  }

  Widget _buildDotIndicators(int count, ThemeData theme) {
    return SizedBox(
      height: _dotHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = _currentPage == index;
          return AnimatedContainer(
            duration: _animationDuration ~/ 2,
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: isActive
                  ? LinearGradient(colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ])
                  : null,
              color: isActive
                  ? null
                  : theme.colorScheme.onSurface.withOpacity(0.1),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContinueButton(
    List<Map<String, dynamic>> splashData,
    AppLocalizations locale,
    ThemeData theme,
  ) {
    final isLastPage = _currentPage == splashData.length - 1;
    final color = splashData[_currentPage]['color'];

    return Semantics(
      button: true,
      label: isLastPage ? locale.continueButton : locale.nextButton,
      child: Container(
        width: double.infinity,
        height: _buttonHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: splashData[_currentPage]['gradient'],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _navigateToNextPage,
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastPage ? locale.continueButton : locale.nextButton,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontFamily: locale.localeName == 'ar' ||
                              locale.localeName == 'kab'
                          ? 'NotoSansArabic'
                          : 'Inter',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLastPage ? Icons.check : Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OptimizedSplashContent extends StatelessWidget {
  final String image;
  final String text;
  final String title;
  final Color color;
  final List<Color> gradient;

  const OptimizedSplashContent({
    super.key,
    required this.image,
    required this.text,
    required this.title,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context) ?? AppLocalizationsEn();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Column(
        children: [
          const SizedBox(height: _contentSpacing),
          Semantics(
            image: true,
            label: 'App logo',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.08),
              ),
              child: Hero(
                tag: 'app-logo',
                child: Image.asset(
                  'assets/images/Screenshot_2024-04-26_195702-removebg-preview.png',
                  height: 30,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: _contentSpacing),
          ShaderMask(
            shaderCallback: (bounds) =>
                LinearGradient(colors: gradient).createShader(bounds),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 28,
                height: 1.3,
                color: Colors.white,
                fontFamily:
                    locale.localeName == 'ar' || locale.localeName == 'kab'
                        ? 'NotoSansArabic'
                        : 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.6,
                fontSize: 16,
                fontFamily:
                    locale.localeName == 'ar' || locale.localeName == 'kab'
                        ? 'NotoSansArabic'
                        : 'Inter',
              ),
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              image,
              height: 169,
              fit: BoxFit.contain,
              cacheHeight: 300,
              cacheWidth: 400,
            ),
          ),
          const SizedBox(height: _contentSpacing),
        ],
      ),
    );
  }
}
