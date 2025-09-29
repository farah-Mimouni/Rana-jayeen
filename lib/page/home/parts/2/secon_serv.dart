import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:rana_jayeen/constants.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/page/home/parts/2/dym_serv.dart';
import 'package:rana_jayeen/page/home/parts/2/gasla.dart';
import 'package:rana_jayeen/globel/section_title.dart';

class secon_serv extends StatelessWidget {
  const secon_serv({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment:
          isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: 16,
          ),
          child: SectionTitle(title: lang.secondaryServices),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: screenWidth > 600 ? 240 : 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildInteractiveCard(
                context,
                title: lang.carWash,
                assetPath: 'assets/images/car_wash.json',
                isLottie: true,
                accentColor: kPrimaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CarWashPage(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),
              _buildInteractiveCard(
                context,
                title: lang.carRental,
                assetPath: 'assets/images/car_rental.gif',
                isLottie: false,
                accentColor: const Color(0xFF10B981),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DynamicServicePage(
                        serviceType: 'car_rental',
                        serviceTitle: AppLocalizations.of(context)!.carRental,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),
              _buildInteractiveCard(
                context,
                title: lang.sparePartsTitle,
                assetPath: 'assets/images/spare_parts.jpg',
                isLottie: false,
                accentColor: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DynamicServicePage(
                        serviceType: 'spare_parts',
                        serviceTitle:
                            AppLocalizations.of(context)!.sparePartsTitle,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),
              _buildInteractiveCard(
                context,
                title: lang.gasStation,
                assetPath: 'assets/images/Naftal1.jpg',
                isLottie: false,
                accentColor: const Color(0xFF4CAF50),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DynamicServicePage(
                        serviceType: 'gas_station',
                        serviceTitle: AppLocalizations.of(context)!.gasStation,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveCard(
    BuildContext context, {
    required String title,
    required String assetPath,
    required bool isLottie,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return _AnimatedServiceCard(
      title: title,
      assetPath: assetPath,
      isLottie: isLottie,
      accentColor: accentColor,
      onTap: onTap,
      isDark: isDark,
      theme: theme,
    );
  }
}

class _AnimatedServiceCard extends StatefulWidget {
  final String title;
  final String assetPath;
  final bool isLottie;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isDark;
  final ThemeData theme;

  const _AnimatedServiceCard({
    required this.title,
    required this.assetPath,
    required this.isLottie,
    required this.accentColor,
    required this.onTap,
    required this.isDark,
    required this.theme,
  });

  @override
  State<_AnimatedServiceCard> createState() => _AnimatedServiceCardState();
}

class _AnimatedServiceCardState extends State<_AnimatedServiceCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _hoverController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _hoverAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _parallaxAnimation;

  bool _isHovered = false;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();

    // Entrance animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // Reduced for speed
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Hover animation
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 150), // Reduced for speed
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOutCubic),
    );
    _parallaxAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    // Ripple animation for tap
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 300), // Reduced for speed
      vsync: this,
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _hoverController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (!mounted) return;
    setState(() => _isHovered = isHovered);
    isHovered ? _hoverController.forward() : _hoverController.reverse();
    if (isHovered) HapticFeedback.lightImpact();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!mounted) return;
    setState(() => _isTapped = true);
    _rippleController.forward();
    HapticFeedback.mediumImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!mounted) return;
    setState(() => _isTapped = false);
    _rippleController.reverse();
    _controller.reverse().then((_) => _controller.forward());
    Future.delayed(const Duration(milliseconds: 100), widget.onTap);
  }

  void _handleTapCancel() {
    if (!mounted) return;
    setState(() => _isTapped = false);
    _rippleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth =
        screenWidth > 600 ? 180.0 : 160.0; // Reduced for performance
    final cardHeight =
        screenWidth > 600 ? 220.0 : 200.0; // Reduced for performance

    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _hoverAnimation,
        _fadeAnimation,
        _rippleAnimation,
        _parallaxAnimation
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _hoverAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _handleHover(true),
            onExit: (_) => _handleHover(false),
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: Semantics(
                label: widget.title,
                button: true,
                child: Stack(
                  children: [
                    // Main card container with glassmorphism effect
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200), // Reduced
                      curve: Curves.easeInOut,
                      width: cardWidth,
                      height: cardHeight,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(20), // Reduced radius
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isHovered
                              ? [
                                  widget.accentColor.withOpacity(0.25),
                                  widget.accentColor.withOpacity(0.1),
                                ]
                              : [
                                  widget.isDark
                                      ? widget.theme.colorScheme
                                          .surfaceContainerHighest
                                          .withOpacity(0.85)
                                      : const Color(0xFFF9FAFB)
                                          .withOpacity(0.8),
                                  widget.isDark
                                      ? widget.theme.colorScheme
                                          .surfaceContainerHigh
                                          .withOpacity(0.85)
                                      : const Color(0xFFEDEEF2)
                                          .withOpacity(0.8),
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor
                                .withOpacity(_isHovered ? 0.3 : 0.15),
                            blurRadius: _isHovered ? 16 : 8,
                            offset: Offset(0, _isHovered ? 6 : 3),
                            spreadRadius: _isHovered ? 1 : 0.5,
                          ),
                          BoxShadow(
                            color: widget.isDark
                                ? Colors.black.withOpacity(0.2)
                                : Colors.grey.shade300.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: _isHovered
                              ? widget.accentColor.withOpacity(0.5)
                              : widget.accentColor.withOpacity(0.15),
                          width: _isHovered ? 1.5 : 1,
                        ),
                      ),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Asset container with parallax effect
                            Transform.translate(
                              offset: Offset(0, -_parallaxAnimation.value),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(12), // Reduced
                                child: Container(
                                  width: cardWidth * 0.85,
                                  height: cardHeight * 0.55,
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        widget.accentColor.withOpacity(
                                            _isHovered ? 0.3 : 0.15),
                                        widget.accentColor.withOpacity(0.05),
                                      ],
                                      radius: 0.9,
                                    ),
                                    boxShadow: _isHovered
                                        ? [
                                            BoxShadow(
                                              color: widget.accentColor
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: widget.accentColor
                                                  .withOpacity(0.15),
                                              blurRadius: 6,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                  ),
                                  child: widget.isLottie
                                      ? Lottie.asset(
                                          widget.assetPath,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          frameRate: FrameRate(30), // Optimized
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: widget.accentColor
                                                  .withOpacity(0.1),
                                              child: Icon(
                                                Icons.error_outline,
                                                size: 36,
                                                color: widget.accentColor,
                                              ),
                                            );
                                          },
                                        )
                                      : Image.asset(
                                          widget.assetPath,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: widget.accentColor
                                                  .withOpacity(0.1),
                                              child: Icon(
                                                Icons.error_outline,
                                                size: 36,
                                                color: widget.accentColor,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8), // Reduced spacing
                            // Title with enhanced typography
                            AnimatedDefaultTextStyle(
                              duration:
                                  const Duration(milliseconds: 150), // Reduced
                              style:
                                  widget.theme.textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.w800,
                                color: _isHovered
                                    ? widget.accentColor
                                    : widget.theme.colorScheme.onSurface
                                        .withOpacity(0.9),
                                fontSize: _isHovered ? 15 : 14, // Adjusted
                                height: 1.3,
                                letterSpacing: 0.5,
                              ),
                              child: Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8), // Reduced spacing
                            // Animated divider with glow
                            AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200), // Reduced
                              width: _isHovered ? 36 : 20, // Adjusted
                              height: 2.5, // Reduced
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                gradient: LinearGradient(
                                  colors: [
                                    widget.accentColor.withOpacity(0.8),
                                    widget.accentColor,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.accentColor
                                        .withOpacity(_isHovered ? 0.4 : 0.25),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Ripple effect
                    if (_isTapped)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20), // Reduced
                          child: AnimatedBuilder(
                            animation: _rippleAnimation,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: widget.accentColor.withOpacity(
                                      0.25 * (1 - _rippleAnimation.value)),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
