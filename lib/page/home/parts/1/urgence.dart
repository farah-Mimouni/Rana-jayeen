import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rana_jayeen/constants.dart' as theme;

import 'package:rana_jayeen/page/home/parts/1/cat_urg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';

class ServicePage extends StatefulWidget {
  final ServiceType serviceType;

  const ServicePage({Key? key, required this.serviceType}) : super(key: key);

  @override
  _ServicePageState createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage>
    with TickerProviderStateMixin {
  final double infoHeight = 400.0;
  AnimationController? animationController;
  Animation<double>? animation;
  Animation<double>? _logoAnimation;
  double opacity1 = 0.0;
  double opacity2 = 0.0;
  double opacity3 = 0.0;
  TextEditingController textEditingController = TextEditingController();
  bool isContainerClicked1 = false;
  bool isContainerClicked = false;
  late AnimationController _messageController;
  late AnimationController _alertController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoAnimation = CurvedAnimation(
      parent: animationController!,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    );
    _messageController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _alertController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController!,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    setData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _alertController.dispose();
    animationController?.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  Future<void> setData() async {
    animationController?.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => opacity1 = 1.0);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => opacity2 = 1.0);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => opacity3 = 1.0);
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not launch $phoneNumber');
    }
  }

  void _showPhoneNumbersDialog() {
    final lang = AppLocalizations.of(context)!;
    final phoneNumbers = _getPhoneNumbers();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 16,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: _getGradient(),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${lang.call} ${_getTitle()}',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Phone numbers list
              Text(
                lang.selectNumber,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: theme.darkerText,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              ...phoneNumbers
                  .map((number) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          borderRadius: BorderRadius.circular(12),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.of(context).pop();
                              _makePhoneCall(number);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.phone,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    number,
                                    style: GoogleFonts.roboto(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: theme.darkerText,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),

              const SizedBox(height: 20),

              // Cancel button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  lang.cancel,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    final lang = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 16,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with animation
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.construction,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                lang.comingSoon,
                style: GoogleFonts.roboto(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.darkerText,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                lang.featureNotAvailable,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: theme.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Thank you message
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lang.thankYouPatience,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.nearlyBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    lang.understood,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    final lang = AppLocalizations.of(context)!;
    switch (widget.serviceType) {
      case ServiceType.police:
        return lang.police;
      case ServiceType.gendarmerie:
        return lang.gendarmerie;
      case ServiceType.civilProtection:
        return lang.civilProtection;
      case ServiceType.ambulance:
        return lang.ambulance;
    }
  }

  String _getDescription() {
    final lang = AppLocalizations.of(context)!;
    switch (widget.serviceType) {
      case ServiceType.police:
        return lang.policeDescription;
      case ServiceType.gendarmerie:
        return lang.gendarmerieDescription;
      case ServiceType.civilProtection:
        return lang.civilProtectionDescription;
      case ServiceType.ambulance:
        return lang.ambulanceDescription;
    }
  }

  String _getLogoPath() {
    switch (widget.serviceType) {
      case ServiceType.police:
        return 'assets/images/logopolice-removebg-preview.png';
      case ServiceType.gendarmerie:
        return 'assets/design_course/loggen.png';
      case ServiceType.civilProtection:
        return 'assets/design_course/himayalogo.png';
      case ServiceType.ambulance:
        return 'assets/design_course/hilal.png';
    }
  }

  String _getHeroTag() {
    switch (widget.serviceType) {
      case ServiceType.police:
        return 'police_logo';
      case ServiceType.gendarmerie:
        return 'gendarmerie_logo';
      case ServiceType.civilProtection:
        return 'civil_protection_logo';
      case ServiceType.ambulance:
        return 'ambulance_logo';
    }
  }

  Gradient _getGradient() {
    switch (widget.serviceType) {
      case ServiceType.police:
        return const LinearGradient(
          colors: [Colors.blue, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ServiceType.gendarmerie:
        return const LinearGradient(
          colors: [Colors.green, Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ServiceType.civilProtection:
        return const LinearGradient(
          colors: [Colors.red, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ServiceType.ambulance:
        return const LinearGradient(
          colors: [Colors.redAccent, Colors.pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  List<String> _getPhoneNumbers() {
    switch (widget.serviceType) {
      case ServiceType.police:
        return ['1548', '104'];
      case ServiceType.gendarmerie:
        return ['1055'];
      case ServiceType.civilProtection:
        return ['14', '1021'];
      case ServiceType.ambulance:
        return ['14', '1021'];
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String text,
    required VoidCallback onPressed,
    bool isAvailable = true,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color, Color.lerp(color, Colors.white, 0.2)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonButton({
    required IconData icon,
    required Color color,
    required String text,
    required String feature,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade300,
              Colors.grey.shade200,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showComingSoonDialog(feature),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.grey.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Soon',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.nearlyWhite,
            theme.nearlyWhite.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            // Header with gradient background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 220,
                decoration: BoxDecoration(
                  gradient: _getGradient(),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: ScaleTransition(
                    scale: _logoAnimation!,
                    child: Hero(
                      tag: _getHeroTag(),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            _getLogoPath(),
                            fit: BoxFit.contain,
                            width: 80,
                            height: 80,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Main content area
            Positioned(
              top: 180,
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: animationController!,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0.0,
                      (1.0 - (animation?.value ?? 1.0)) * 40,
                    ),
                    child: child,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: isRtl
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: <Widget>[
                        // Title with fade animation
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: opacity1,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 16),
                            child: Text(
                              _getTitle(),
                              textAlign:
                                  isRtl ? TextAlign.right : TextAlign.left,
                              style: TextStyle(
                                fontFamily: isRtl
                                    ? GoogleFonts.amiri().fontFamily
                                    : GoogleFonts.roboto().fontFamily,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: theme.darkerText,
                              ),
                            ),
                          ),
                        ),

                        // Description with fade animation
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: opacity2,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: Text(
                              _getDescription(),
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontFamily: isRtl
                                    ? GoogleFonts.amiri().fontFamily
                                    : GoogleFonts.roboto().fontFamily,
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                color: theme.grey,
                                height: 1.5,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        // Action buttons section
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: opacity3,
                          child: Column(
                            children: [
                              // Call button - shows phone numbers dialog
                              _buildActionButton(
                                icon: Icons.phone,
                                color: Colors.green,
                                text: lang.call,
                                onPressed: _showPhoneNumbersDialog,
                                isAvailable: true,
                              ),

                              const SizedBox(height: 16),

                              // Message button - coming soon
                              _buildComingSoonButton(
                                icon: Icons.message,
                                color: theme.nearlyBlue,
                                text: lang.message,
                                feature: lang.message,
                              ),

                              const SizedBox(height: 16),

                              // Alert button - coming soon
                              _buildComingSoonButton(
                                icon: Icons.warning,
                                color: Colors.redAccent,
                                text: lang.alert,
                                feature: lang.alert,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Additional info section
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: opacity3,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade50,
                                  Colors.blue.shade100.withOpacity(0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade600,
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    lang.emergencyInfo,
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: Colors.blue.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
