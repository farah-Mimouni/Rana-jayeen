import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rana_jayeen/constants.dart' as theme;
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/constants.dart';
import 'package:rana_jayeen/globel/section_title.dart';
import 'package:rana_jayeen/page/home/parts/1/urgence.dart';
import 'package:rana_jayeen/infoHandller/app_info.dart';
import 'package:provider/provider.dart';

// Enum to identify service types
enum ServiceType { police, gendarmerie, civilProtection, ambulance }

class Categories extends StatefulWidget {
  const Categories({Key? key}) : super(key: key);

  @override
  _CategoriesState createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Faster animation
      vsync: this,
    )..forward();

    // Precache images to improve loading performance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = _getCategories(AppLocalizations.of(context)!);
      for (var category in categories) {
        precacheImage(AssetImage(category["icon"]), context);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getCategories(AppLocalizations lang) {
    return [
      {
        "icon": "assets/images/logopolice-removebg-preview.png",
        "text": lang.police,
        "route": "/police",
        "color": Colors.blue[700],
        "gradient": const LinearGradient(
          colors: [Colors.blue, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        "page": const ServicePage(serviceType: ServiceType.police),
        "heroTag": "police_logo",
      },
      {
        "icon": "assets/design_course/loggen.png",
        "text": lang.gendarmerie,
        "route": "/gendarmerie",
        "color": Colors.green[700],
        "gradient": const LinearGradient(
          colors: [Colors.green, Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        "page": const ServicePage(serviceType: ServiceType.gendarmerie),
        "heroTag": "gendarmerie_logo",
      },
      {
        "icon": "assets/design_course/himayalogo.png",
        "text": lang.civilProtection,
        "route": "/civil_protection",
        "color": Colors.red[700],
        "gradient": const LinearGradient(
          colors: [Colors.red, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        "page": const ServicePage(serviceType: ServiceType.civilProtection),
        "heroTag": "civil_protection_logo",
      },
      {
        "icon": "assets/design_course/hilal.png",
        "text": lang.ambulance,
        "route": "/ambulance",
        "color": Colors.red[600],
        "gradient": const LinearGradient(
          colors: [Colors.redAccent, Colors.pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        "page": const ServicePage(serviceType: ServiceType.ambulance),
        "heroTag": "ambulance_logo",
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final categories = _getCategories(lang);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.nearlyWhite,
            theme.nearlyWhite.withOpacity(0.9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04,
              vertical: 10,
            ),
            child: SectionTitle(
              title: lang.serviceCategories,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth =
                    (constraints.maxWidth - 36) / categories.length;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  children: List.generate(
                    categories.length,
                    (index) => SizedBox(
                      width: itemWidth,
                      child: CategoryCard(
                        icon: categories[index]["icon"],
                        text: categories[index]["text"],
                        page: categories[index]["page"],
                        color: categories[index]["color"],
                        gradient: categories[index]["gradient"],
                        heroTag: categories[index]["heroTag"],
                        animation: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              0.1 * index,
                              0.4 + 0.1 * index,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryCard extends StatefulWidget {
  const CategoryCard({
    Key? key,
    required this.icon,
    required this.text,
    required this.page,
    this.color,
    required this.gradient,
    required this.heroTag,
    required this.animation,
  }) : super(key: key);

  final String icon, text, heroTag;
  final Widget page;
  final Color? color;
  final Gradient gradient;
  final Animation<double> animation;

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  final _isHovered = ValueNotifier<bool>(false);
  final _isTapped = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isHovered.dispose();
    _isTapped.dispose();
    super.dispose();
  }

  void _navigateToPage() {
    final isOffline = Provider.of<AppInfo>(context, listen: false).isOffline;
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.noInternetConnection ??
                'This service requires internet. Please connect.',
            style: const TextStyle(
              fontFamily: 'WorkSans',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: theme.kError,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration:
            const Duration(milliseconds: 400), // Faster transition
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => widget.page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isOffline = Provider.of<AppInfo>(context).isOffline;

    return MouseRegion(
      onEnter: (_) => _isHovered.value = true,
      onExit: (_) => _isHovered.value = false,
      child: GestureDetector(
        onTapDown: (_) {
          _isTapped.value = true;
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          _isTapped.value = false;
          _navigateToPage();
        },
        onTapCancel: () => _isTapped.value = false,
        child: Semantics(
          label: '${lang.select} ${widget.text}',
          button: true,
          enabled: !isOffline,
          child: FadeTransition(
            opacity: widget.animation,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isTapped,
              builder: (context, isTapped, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _isHovered,
                  builder: (context, isHovered, child) {
                    return Transform.scale(
                      scale: isTapped ? 0.97 : 1.0,
                      child: Column(
                        children: [
                          Tooltip(
                            message: widget.text,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: widget.gradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(isHovered ? 0.2 : 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                  if (isHovered && !isOffline)
                                    BoxShadow(
                                      color: widget.color?.withOpacity(0.3) ??
                                          kPrimaryColor.withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                ],
                                color: isOffline
                                    ? Colors.grey.withOpacity(0.5)
                                    : null,
                              ),
                              child: ClipOval(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(35),
                                    onTap: _navigateToPage,
                                    child: Hero(
                                      tag: widget.heroTag,
                                      child: Image.asset(
                                        widget.icon,
                                        fit: BoxFit.contain,
                                        width: 45,
                                        height: 45,
                                        color: isOffline
                                            ? Colors.grey.withOpacity(0.7)
                                            : null,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              widget.text,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium!.copyWith(
                                fontFamily: isRtl
                                    ? GoogleFonts.amiri().fontFamily
                                    : GoogleFonts.roboto().fontFamily,
                                fontWeight: FontWeight.w500,
                                color: isOffline
                                    ? Colors.grey
                                    : isHovered
                                        ? widget.color ?? kPrimaryColor
                                        : Colors.black87,
                                fontSize: 13,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
