import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../globel/assistant_methods.dart';
import '../globel/var_glob.dart';

class UnifiedScreen extends StatefulWidget {
  @override
  _UnifiedScreenState createState() => _UnifiedScreenState();
}

class _UnifiedScreenState extends State<UnifiedScreen>
    with TickerProviderStateMixin {
  final TextEditingController helpController = TextEditingController();
  final TextEditingController feedbackController = TextEditingController();
  int currentSection = 0;
  double _rating = 0.0;

  late AnimationController _floatingController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _floatingAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _floatingController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOutSine,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuint,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideController.forward();
    _scaleController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    helpController.dispose();
    feedbackController.dispose();
    _floatingController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> getCurrentLocation() async {
    AssistantMethodes.readCurrentOnlineUser();
  }

  void _makePhoneCall(String phoneNumber) async {
    Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not launch $phoneNumber');
    }
  }

  void _sendMessageToDatabase(String message) {
    DatabaseReference messageRef =
        FirebaseDatabase.instance.ref().child('messages');
    messageRef.push().set({
      'message': message,
      'timestamp': ServerValue.timestamp,
      'iduser': userModelCurrentInfo!.id,
      'name': userModelCurrentInfo!.first,
      'phone': userModelCurrentInfo!.phone,
    }).then((_) {
      _showSaveDialog(
        AppLocalizations.of(context)!.messageSent,
        AppLocalizations.of(context)!.messageSuccess,
      );
      helpController.clear();
    }).catchError((error) {
      print('Error saving message: $error');
    });
  }

  void _sendFeedback() {
    if (_rating == 0.0) {
      _showSaveDialog(
        AppLocalizations.of(context)!.error,
        AppLocalizations.of(context)!.pleaseSelectRating,
      );
      return;
    }
    DatabaseReference feedbackRef =
        FirebaseDatabase.instance.ref().child('feedback');
    feedbackRef.push().set({
      'rating': _rating,
      'text': feedbackController.text.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }).then((_) {
      _showSaveDialog(
        AppLocalizations.of(context)!.thankYou,
        AppLocalizations.of(context)!.feedbackSuccess,
      );
      setState(() {
        _rating = 0.0;
        feedbackController.clear();
      });
    }).catchError((error) {
      print('Error saving feedback: $error');
    });
  }

  void _showSaveDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Theme.of(context).cardColor,
            elevation: 12,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kPrimaryColor.withOpacity(0.1),
                          ),
                          child: Icon(
                            title == AppLocalizations.of(context)!.error
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            color: kPrimaryColor,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        AppLocalizations.of(context)!.ok,
                        style: TextStyle(
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLightMode
                ? [Colors.white, Color(0xFFF5F7FA)]
                : [Color(0xFF121212), Color(0xFF1E1E1E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isLightMode),
              _buildTabNavigation(isLightMode),
              SizedBox(height: 24),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _buildContent(isLightMode),
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

  Widget _buildHeader(bool isLightMode) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        kPrimaryColor.withOpacity(0.15),
                        kPrimaryColor.withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withOpacity(0.2),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.support_agent,
                    size: 48,
                    color: kPrimaryColor,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.support,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: isLightMode ? Colors.black87 : Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.weAreHereToHelp,
            style: TextStyle(
              fontSize: 16,
              color: isLightMode ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation(bool isLightMode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isLightMode
            ? Colors.white.withOpacity(0.9)
            : Colors.grey[850]!.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTab(0, Icons.help_outline, AppLocalizations.of(context)!.help,
              isLightMode),
          _buildTab(1, Icons.star_border,
              AppLocalizations.of(context)!.feedback, isLightMode),
          _buildTab(2, Icons.info_outline,
              AppLocalizations.of(context)!.aboutUs, isLightMode),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String title, bool isLightMode) {
    bool isSelected = currentSection == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            currentSection = index;
          });
          _slideController.reset();
          _fadeController.reset();
          _slideController.forward();
          _fadeController.forward();
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? kPrimaryColor.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? kPrimaryColor.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? kPrimaryColor
                      : (isLightMode ? Colors.grey[600] : Colors.grey[400]),
                  size: isSelected ? 24 : 22,
                ),
              ),
              SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? kPrimaryColor
                      : (isLightMode ? Colors.grey[600] : Colors.grey[400]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isLightMode) {
    switch (currentSection) {
      case 0:
        return _buildHelpSection(isLightMode);
      case 1:
        return _buildFeedbackSection(isLightMode);
      case 2:
        return _buildAboutUsSection(isLightMode);
      default:
        return Container();
    }
  }

  Widget _buildHelpSection(bool isLightMode) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isLightMode
            ? Colors.white.withOpacity(0.95)
            : Colors.grey[850]!.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.help_center,
                  size: 28,
                  color: kPrimaryColor,
                ),
              ),
              SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.howCanWeHelp,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isLightMode ? Colors.black87 : Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.helpDescription,
            style: TextStyle(
              fontSize: 16,
              color: isLightMode ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          _buildTextField(
            controller: helpController,
            label: AppLocalizations.of(context)!.helpText,
            hint: AppLocalizations.of(context)!.writeHere,
            icon: Icons.edit,
            isLightMode: isLightMode,
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  onPressed: () => _makePhoneCall("0562190600"),
                  icon: Icons.phone,
                  text: "0562190600",
                  isLightMode: isLightMode,
                  backgroundColor:
                      isLightMode ? Colors.green : Colors.green[800]!,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  onPressed: () {
                    String message = helpController.text.trim();
                    if (message.isNotEmpty) {
                      _sendMessageToDatabase(message);
                    }
                  },
                  icon: Icons.send,
                  text: AppLocalizations.of(context)!.send,
                  isLightMode: isLightMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(bool isLightMode) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isLightMode
            ? Colors.white.withOpacity(0.95)
            : Colors.grey[850]!.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.star,
                  size: 28,
                  color: kPrimaryColor,
                ),
              ),
              SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.appRating,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isLightMode ? Colors.black87 : Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.yourOpinionMatters,
            style: TextStyle(
              fontSize: 16,
              color: isLightMode ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Center(
            child: _buildStarRating(isLightMode),
          ),
          SizedBox(height: 24),
          _buildTextField(
            controller: feedbackController,
            label: AppLocalizations.of(context)!.additionalFeedback,
            hint: AppLocalizations.of(context)!.enterFeedback,
            icon: Icons.edit,
            isLightMode: isLightMode,
            maxLines: 4,
          ),
          SizedBox(height: 24),
          _buildActionButton(
            onPressed: _sendFeedback,
            icon: Icons.send,
            text: AppLocalizations.of(context)!.send,
            isLightMode: isLightMode,
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(bool isLightMode) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isLightMode ? Colors.grey[100]! : Colors.grey[800]!,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _rating = index + 1.0;
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Icon(
                  _rating >= index + 1 ? Icons.star : Icons.star_border,
                  color: _rating >= index + 1
                      ? Colors.amber
                      : (isLightMode ? Colors.grey[400] : Colors.grey[600]),
                  size: 32,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAboutUsSection(bool isLightMode) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isLightMode
            ? Colors.white.withOpacity(0.95)
            : Colors.grey[850]!.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.info,
                  size: 28,
                  color: kPrimaryColor,
                ),
              ),
              SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.whoWeAre,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isLightMode ? Colors.black87 : Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildFeatureCard(
            icon: Icons.directions_car,
            title: AppLocalizations.of(context)!.appDescription,
            isLightMode: isLightMode,
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            icon: Icons.flash_on,
            title: AppLocalizations.of(context)!.weAreComing,
            isLightMode: isLightMode,
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            icon: Icons.location_on,
            title: AppLocalizations.of(context)!.becauseWeCome,
            isLightMode: isLightMode,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isLightMode,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: isLightMode ? Colors.black87 : Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isLightMode ? Colors.grey[300]! : Colors.grey[700]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isLightMode ? Colors.grey[300]! : Colors.grey[700]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: kPrimaryColor,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: kPrimaryColor,
        ),
        hintStyle: TextStyle(
          color: isLightMode ? Colors.grey[500] : Colors.grey[400],
        ),
        filled: true,
        fillColor: isLightMode
            ? Colors.grey[50]!.withOpacity(0.8)
            : Colors.grey[900]!.withOpacity(0.8),
        contentPadding: EdgeInsets.symmetric(
          vertical: maxLines > 1 ? 16 : 0,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String text,
    required bool isLightMode,
    Color? backgroundColor,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? kPrimaryColor,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        shadowColor:
            backgroundColor?.withOpacity(0.3) ?? Colors.white.withOpacity(0.3),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.white,
          ),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required bool isLightMode,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLightMode
            ? Colors.grey[50]!.withOpacity(0.8)
            : Colors.grey[800]!.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLightMode ? Colors.grey[200]! : Colors.grey[700]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kPrimaryColor.withOpacity(0.1),
            ),
            child: Icon(
              icon,
              color: kPrimaryColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isLightMode ? Colors.black87 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
