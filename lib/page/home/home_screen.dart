import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/infoHandller/LanguageProvider.dart';
import 'package:rana_jayeen/constants.dart';
import 'package:rana_jayeen/page/home/parts/1/cat_urg.dart';
import 'package:rana_jayeen/page/home/parts/3/princ_serv.dart';
import 'package:rana_jayeen/page/home/parts/2/secon_serv.dart';
import 'package:rana_jayeen/page/home/parts/4/report.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = "/home";
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late AnimationController _headerController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _headerOpacity;
  late Animation<double> _floatingAnimation;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _showFloatingHeader = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _headerOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: Curves.easeInOut,
      ),
    );

    _floatingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeOut,
      ),
    );
  }

  void _setupScrollListener() {
    _scrollController.addListener(_onScroll);
  }

  void _startAnimations() {
    if (mounted) {
      _animationController.forward();
    }
  }

  void _onScroll() {
    if (!mounted) return;

    final offset = _scrollController.offset;
    setState(() => _scrollOffset = offset);

    // Header animation
    final headerProgress = (offset / 100).clamp(0.0, 1.0);
    _headerController.animateTo(headerProgress);

    // Floating header logic
    final shouldShowFloating = offset > 120;
    if (shouldShowFloating != _showFloatingHeader) {
      setState(() => _showFloatingHeader = shouldShowFloating);
      shouldShowFloating
          ? _floatingController.forward()
          : _floatingController.reverse();
    }

    // Update system UI
    _updateSystemUI(offset);
  }

  void _updateSystemUI(double offset) {
    final isDark = offset > 70;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: const Color(0xFFF5F7FA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    _headerController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF5F7FA), Color(0xFFFFFFFF)],
              ),
            ),
          ),

          // Main Content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            cacheExtent: 1800,
            slivers: [
              // App Bar
              SliverAppBar(
                floating: false,
                pinned: true,
                expandedHeight: 160,
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final expandRatio =
                        ((constraints.maxHeight - kToolbarHeight) /
                                (160 - kToolbarHeight))
                            .clamp(0.0, 1.0);
                    return AnimatedBuilder(
                      animation: _headerOpacity,
                      builder: (context, child) => FlexibleSpaceBar(
                        background: _ModernHomeHeader(
                          scrollOffset: _scrollOffset,
                          expandRatio: expandRatio,
                          opacity: _headerOpacity.value,
                          isRtl: isRtl,
                          lang: lang,
                        ),
                        collapseMode: CollapseMode.parallax,
                      ),
                    );
                  },
                ),
              ),

              // Main Content
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) => FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.04,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSection(
                              label: lang.serviceCategories,
                              child: const Categories(),
                              delay: 0,
                            ),
                            const SizedBox(height: 20),
                            _buildSection(
                              label: lang.secondaryServices,
                              child: const secon_serv(),
                              delay: 200,
                            ),
                            const SizedBox(height: 20),
                            _buildSection(
                              label: lang.popularProducts,
                              child: princi_service_page(
                                key: ValueKey(
                                    'popular_products_${Provider.of<LanguageProvider>(context).locale}'),
                              ),
                              delay: 400,
                            ),
                            const SizedBox(height: 20),
                            _buildSection(
                              label: lang.notifications_title,
                              child: const RoadIssueReport(),
                              delay: 600,
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).padding.bottom + 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Floating Header
          if (_showFloatingHeader)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -40 * (1 - _floatingAnimation.value)),
                  child: Opacity(
                    opacity: _floatingAnimation.value,
                    child: _FloatingHeader(isRtl: isRtl, lang: lang),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String label,
    required Widget child,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, _) => Transform.translate(
        offset: Offset(0, 12 * (1 - value)),
        child: Opacity(
          opacity: value,
          child: Semantics(label: label, child: child),
        ),
      ),
    );
  }
}

class _ModernHomeHeader extends StatelessWidget {
  final double scrollOffset;
  final double expandRatio;
  final double opacity;
  final bool isRtl;
  final AppLocalizations lang;

  const _ModernHomeHeader({
    required this.scrollOffset,
    required this.expandRatio,
    required this.opacity,
    required this.isRtl,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kPrimaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative Background
              Positioned(
                top: -50,
                right: isRtl ? null : -30,
                left: isRtl ? -30 : null,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        kPrimaryColor.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main Content
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0, scrollOffset * 0.06),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Hero(
                          tag: 'main_logo',
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: opacity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/Screenshot_2024-04-26_195702-removebg-preview.png',
                                height: 60 + (expandRatio * 25),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 60 + (expandRatio * 25),
                                  height: 60 + (expandRatio * 25),
                                  color: kPrimaryColor,
                                  child: const Icon(
                                    Icons.shield_outlined,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Brand Indicator

                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                kPrimaryColor,
                                kPrimaryColor.withOpacity(0.8)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}

class _FloatingHeader extends StatelessWidget {
  final bool isRtl;
  final AppLocalizations lang;

  const _FloatingHeader({required this.isRtl, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/Screenshot_2024-04-26_195702-removebg-preview.png',
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.shield_outlined,
                    size: 32,
                    color: kPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                lang.home,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
