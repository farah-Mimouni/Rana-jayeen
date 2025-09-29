import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:rana_jayeen/infoHandller/LanguageProvider.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/page/navigation_home_screen.dart';
import 'package:rana_jayeen/l10n/language_dialog.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rana_jayeen/models/userModel.dart';
import 'package:rana_jayeen/globel/assistant_methods.dart';
import 'package:rana_jayeen/globel/var_glob.dart';
import 'package:flutter/foundation.dart';
import 'package:sms_autofill/sms_autofill.dart';

const _kMinOtpInterval = Duration(seconds: 30);
const _kAnimationDuration = Duration(milliseconds: 300);
const _kBorderRadius = BorderRadius.all(Radius.circular(16));
const _kPrimaryColor = Color(0xFF2A7C76);
const _kDefaultCountryCode = 'DZ';
const _kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF2A7C76), Color(0xFF4BA8D8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const _kGlassBackground =
    Color(0xB3FFFFFF); // Semi-transparent white for glassmorphism

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  DateTime? _lastOtpRequest;
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isVerifying = false;
  int _countdown = 60;
  String _completePhoneNumber = '';
  String _verificationId = '';
  Timer? _countdownTimer;
  String _name = '';
  int? _resendToken;

  bool get isLoading => _isLoading;
  bool get isOtpSent => _isOtpSent;
  bool get isVerifying => _isVerifying;
  int get countdown => _countdown;
  String get completePhoneNumber => _completePhoneNumber;

  set completePhoneNumber(String value) {
    _completePhoneNumber = value.replaceAll(RegExp(r'\s+'), '');
    notifyListeners();
  }

  void startCountdown() {
    _countdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        _countdown--;
        notifyListeners();
      } else {
        timer.cancel();
        notifyListeners();
      }
    });
  }

  Future<bool> sendOtp(String phoneNumber, String name, BuildContext context,
      {bool isResend = false}) async {
    final lang = AppLocalizations.of(context)!;
    final normalizedPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');

    if (normalizedPhone.isEmpty) {
      showSnackBar(context, lang.invalidPhoneNumber, Colors.redAccent);
      return false;
    }

    if (_lastOtpRequest != null &&
        DateTime.now().difference(_lastOtpRequest!) < _kMinOtpInterval) {
      showSnackBar(context, lang.tooManyRequests, Colors.redAccent);
      return false;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      showSnackBar(context, lang.noInternetConnection, Colors.redAccent);
      return false;
    }

    _isLoading = true;
    _completePhoneNumber = normalizedPhone;
    _name = name.trim();
    notifyListeners();

    try {
      await _sendFirebaseOtp(context, isResend);
      _lastOtpRequest = DateTime.now();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      showSnackBar(context, lang.otpSendFailed, Colors.redAccent);
      return false;
    }
  }

  Future<bool> verifyOtp(
      String otpCode, String name, BuildContext context) async {
    final lang = AppLocalizations.of(context)!;
    if (otpCode.length != 6) {
      showSnackBar(context, lang.invalidOtp, Colors.redAccent);
      return false;
    }

    if (_verificationId.isEmpty ||
        DateTime.now().difference(_lastOtpRequest ?? DateTime.now()) >
            const Duration(minutes: 5)) {
      showSnackBar(context, lang.otpExpired, Colors.redAccent);
      _isVerifying = false;
      notifyListeners();
      return false;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      showSnackBar(context, lang.noInternetConnection, Colors.redAccent);
      return false;
    }

    _name = name.trim().isNotEmpty ? name.trim() : _name;
    _isVerifying = true;
    notifyListeners();

    try {
      await _verifyFirebaseOtp(otpCode, context);
      return true;
    } catch (e) {
      _isVerifying = false;
      notifyListeners();
      showSnackBar(context, lang.otpVerificationFailed, Colors.redAccent);
      return false;
    }
  }

  void resetOtpState() {
    _isOtpSent = false;
    _countdown = 60;
    _verificationId = '';
    _countdownTimer?.cancel();
    _lastOtpRequest = null;
    _resendToken = null;
    _completePhoneNumber = '';
    _name = '';
    notifyListeners();
  }

  void showSnackBar(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Inter',
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _sendFirebaseOtp(BuildContext context, bool isResend) async {
    final lang = AppLocalizations.of(context)!;
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _completePhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _isVerifying = true;
          notifyListeners();
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            await _handleSuccessfulAuth(userCredential, context);
          } catch (e) {
            _isVerifying = false;
            notifyListeners();
            if (context.mounted) {
              showSnackBar(
                  context, lang.otpVerificationFailed, Colors.redAccent);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _isLoading = false;
          notifyListeners();
          String errorMessage;
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = lang.invalidPhoneNumber;
              break;
            case 'too-many-requests':
              errorMessage = lang.tooManyRequests;
              break;
            case 'quota-exceeded':
              errorMessage = lang.quotaExceededError;
              break;
            default:
              errorMessage = lang.otpSendFailed;
          }
          if (context.mounted) {
            showSnackBar(context, errorMessage, Colors.redAccent);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _isOtpSent = true;
          _isLoading = false;
          startCountdown();
          notifyListeners();
          if (context.mounted) {
            showSnackBar(context, lang.otpSentSuccessfully, Colors.green);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: isResend ? _resendToken : null,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        showSnackBar(context, lang.otpSendFailed, Colors.redAccent);
      }
      rethrow;
    }
  }

  Future<void> _verifyFirebaseOtp(String otpCode, BuildContext context) async {
    final lang = AppLocalizations.of(context)!;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otpCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      await _handleSuccessfulAuth(userCredential, context);
    } catch (e) {
      String errorMessage = lang.otpVerificationFailed;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            errorMessage = lang.invalidOtp;
            break;
          case 'session-expired':
            errorMessage = lang.otpExpired;
            break;
        }
      }
      _isVerifying = false;
      notifyListeners();
      if (context.mounted) {
        showSnackBar(context, errorMessage, Colors.redAccent);
      }
      rethrow;
    }
  }

  Future<void> _handleSuccessfulAuth(
      UserCredential userCredential, BuildContext context) async {
    final lang = AppLocalizations.of(context)!;
    if (userCredential.user == null) {
      _isVerifying = false;
      notifyListeners();
      if (context.mounted) {
        showSnackBar(context, lang.otpVerificationFailed, Colors.redAccent);
      }
      return;
    }
    final user = userCredential.user!;
    final uid = user.uid;

    final displayName = _name.isEmpty ? 'User' : _name;
    await user.updateDisplayName(displayName);

    final userRef = _database.child('auth_user').child(uid);
    final userData = {
      'name': displayName,
      'phoneNumber': _completePhoneNumber,
      'uid': uid,
      'createdAt': ServerValue.timestamp,
    };

    await userRef.set(userData);

    currentUser = _auth.currentUser;
    AssistantMethodes.readCurrentOnlineUser();
    userModelCurrentInfo =
        UserModer(first: displayName, phone: _completePhoneNumber, id: uid);

    try {
      await _secureStorage.write(key: 'userToken', value: uid);
    } catch (e) {
      if (context.mounted) {
        // showSnackBar(context, lang.storageError, Colors.redAccent);
      }
    }

    _isVerifying = false;
    _isOtpSent = false;
    _countdownTimer?.cancel();
    notifyListeners();

    if (context.mounted) {
      showSnackBar(context, lang.phoneVerifiedSuccessfully, Colors.green);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NavigationHomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

class ModernInputField extends StatefulWidget {
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final String? Function(PhoneNumber?)? phoneValidator;
  final String? Function(String?)? textValidator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool isRtl;
  final bool isPhoneField;

  const ModernInputField({
    super.key,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.phoneValidator,
    this.textValidator,
    this.textInputAction,
    this.onFieldSubmitted,
    required this.isRtl,
    this.isPhoneField = false,
  });

  @override
  State<ModernInputField> createState() => _ModernInputFieldState();
}

class _ModernInputFieldState extends State<ModernInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: _kAnimationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    widget.focusNode?.addListener(_handleFocusChange);
    widget.controller?.addListener(_handleTextChange);
    _hasContent = widget.controller?.text.isNotEmpty ?? false;
  }

  void _handleFocusChange() {
    final focused = widget.focusNode?.hasFocus ?? false;
    if (focused != _isFocused) {
      setState(() {
        _isFocused = focused;
      });
      if (focused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _handleTextChange() {
    final hasContent = widget.controller?.text.isNotEmpty ?? false;
    if (hasContent != _hasContent) {
      setState(() {
        _hasContent = hasContent;
      });
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_handleFocusChange);
    widget.controller?.removeListener(_handleTextChange);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _kGlassBackground,
          borderRadius: _kBorderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(_isFocused ? 0.2 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: widget.isPhoneField
            ? _buildPhoneField(lang, isTablet)
            : _buildTextField(lang, isTablet),
      ),
    );
  }

  Widget _buildPhoneField(AppLocalizations lang, bool isTablet) {
    return IntlPhoneField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: isTablet ? 18 : 16,
          fontFamily: widget.isRtl ? 'NotoSansArabic' : 'Inter',
          fontWeight: FontWeight.w500,
        ),
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon,
                size: isTablet ? 28 : 24,
                color: _isFocused ? _kPrimaryColor : Colors.grey[500])
            : null,
      ),
      initialCountryCode: _kDefaultCountryCode,
      textAlign: widget.isRtl ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: isTablet ? 18 : 16,
        color: Colors.grey[800],
        fontFamily: widget.isRtl ? 'NotoSansArabic' : 'Inter',
        fontWeight: FontWeight.w500,
      ),
      dropdownIcon: Icon(
        Icons.arrow_drop_down,
        size: isTablet ? 28 : 24,
        color: Colors.grey[500],
      ),
      onChanged: (phone) {
        if (widget.onChanged != null) {
          widget.onChanged!(phone.completeNumber);
        }
      },
      validator: widget.phoneValidator,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onFieldSubmitted,
      invalidNumberMessage: lang.invalidPhoneNumber,
    );
  }

  Widget _buildTextField(AppLocalizations lang, bool isTablet) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textAlign: widget.isRtl ? TextAlign.right : TextAlign.left,
      inputFormatters: widget.inputFormatters,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: isTablet ? 18 : 16,
          fontFamily: widget.isRtl ? 'NotoSansArabic' : 'Inter',
          fontWeight: FontWeight.w500,
        ),
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon,
                size: isTablet ? 28 : 24,
                color: _isFocused ? _kPrimaryColor : Colors.grey[500])
            : null,
      ),
      style: TextStyle(
        fontSize: isTablet ? 18 : 16,
        color: Colors.grey[800],
        fontFamily: widget.isRtl ? 'NotoSansArabic' : 'Inter',
        fontWeight: FontWeight.w500,
      ),
      onChanged: widget.onChanged,
      validator: widget.textValidator,
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}

class CompleteProfileScreen extends StatefulWidget {
  static const String routeName = "/complete_profile";
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen>
    with TickerProviderStateMixin, CodeAutoFill {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: _kAnimationDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Initialize SMS autofill
    SmsAutoFill().listenForCode();
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      _otpController.text = code!;
      final authService = Provider.of<AuthService>(context, listen: false);
      if (_formKey.currentState!.validate()) {
        authService.verifyOtp(
          _otpController.text.trim(),
          _nameController.text.trim(),
          context,
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    _nameFocusNode.dispose();
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations lang, bool isRtl,
      AuthService authService) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Column(
      children: [
        Hero(
          tag: 'app_logo',
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: isTablet ? 140 : 120,
              height: isTablet ? 140 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kGlassBackground,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/Screenshot_2024-04-26_195702-removebg-preview.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          authService.isOtpSent ? lang.confirmVerificationCode : lang.signIn,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: isTablet ? 28 : 24,
            letterSpacing: -0.5,
            fontFamily: 'Inter',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          authService.isOtpSent
              ? lang.enterCodeSentTo(authService.completePhoneNumber.isNotEmpty
                  ? authService.completePhoneNumber
                  : lang.unknownNumber)
              : lang.completeRegistrationMessage,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontSize: isTablet ? 16 : 14,
            height: 1.5,
            fontFamily: 'Inter',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: Consumer2<AuthService, LanguageProvider>(
        builder: (context, authService, languageProvider, child) {
          final theme = Theme.of(context);
          final lang = AppLocalizations.of(context)!;
          final isRtl = languageProvider.locale.languageCode == 'ar' ||
              languageProvider.locale.languageCode == 'kab';

          return Scaffold(
            backgroundColor: Colors.grey[100],
            body: SafeArea(
              child: Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Color(0xFFF5F7FA)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? screenWidth * 0.1 : 24,
                            vertical: 32,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isTablet ? 600 : screenWidth * 0.9,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: _kGlassBackground,
                                borderRadius: _kBorderRadius,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.language,
                                            color: Colors.grey[700],
                                            size: isTablet ? 28 : 24,
                                          ),
                                          onPressed: () => showDialog(
                                            context: context,
                                            barrierColor:
                                                Colors.black.withOpacity(0.4),
                                            builder: (context) =>
                                                const LanguageDialog(),
                                          ),
                                          tooltip: lang.chooseLanguage,
                                        ),
                                      ],
                                    ),
                                    _buildHeader(
                                        theme, lang, isRtl, authService),
                                    const SizedBox(height: 32),
                                    AnimatedSwitcher(
                                      duration: _kAnimationDuration,
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0.2, 0),
                                              end: Offset.zero,
                                            ).animate(
                                              CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeOut,
                                              ),
                                            ),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Column(
                                        key: ValueKey<bool>(
                                            authService.isOtpSent),
                                        children: [
                                          if (!authService.isOtpSent) ...[
                                            ModernInputField(
                                              label: lang.fullNameOptional,
                                              hintText: lang.enterYourName,
                                              prefixIcon: Icons.person_outline,
                                              controller: _nameController,
                                              focusNode: _nameFocusNode,
                                              textInputAction:
                                                  TextInputAction.next,
                                              onFieldSubmitted: (_) =>
                                                  FocusScope.of(context)
                                                      .requestFocus(
                                                          _phoneFocusNode),
                                              isRtl: isRtl,
                                            ),
                                            const SizedBox(height: 16),
                                            ModernInputField(
                                              label: lang.phoneNumber,
                                              hintText:
                                                  lang.pleaseEnterValidPhone,
                                              controller: _phoneController,
                                              focusNode: _phoneFocusNode,
                                              isRtl: isRtl,
                                              isPhoneField: true,
                                              onChanged: (value) => authService
                                                  .completePhoneNumber = value,
                                              phoneValidator: (phone) {
                                                if (phone == null ||
                                                    phone.number.isEmpty) {
                                                  return lang
                                                      .invalidPhoneNumber;
                                                }
                                                return null;
                                              },
                                              textInputAction:
                                                  TextInputAction.done,
                                              onFieldSubmitted: (_) {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  authService.sendOtp(
                                                    authService
                                                        .completePhoneNumber,
                                                    _nameController.text.trim(),
                                                    context,
                                                  );
                                                }
                                              },
                                            ),
                                          ] else ...[
                                            ModernInputField(
                                              label: lang.verificationCode,
                                              hintText: '123456',
                                              prefixIcon: Icons.security,
                                              controller: _otpController,
                                              focusNode: _otpFocusNode,
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                                LengthLimitingTextInputFormatter(
                                                    6),
                                              ],
                                              isRtl: isRtl,
                                              textValidator: (value) {
                                                if (value == null ||
                                                    value.length != 6) {
                                                  return lang.invalidOtp;
                                                }
                                                return null;
                                              },
                                              textInputAction:
                                                  TextInputAction.done,
                                              onFieldSubmitted: (_) {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  authService.verifyOtp(
                                                    _otpController.text.trim(),
                                                    _nameController.text.trim(),
                                                    context,
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    ScaleTransition(
                                      scale: _pulseAnimation,
                                      child: ElevatedButton(
                                        onPressed: (authService.isLoading ||
                                                authService.isVerifying)
                                            ? null
                                            : () async {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  HapticFeedback.mediumImpact();
                                                  if (authService.isOtpSent) {
                                                    await authService.verifyOtp(
                                                      _otpController.text
                                                          .trim(),
                                                      _nameController.text
                                                          .trim(),
                                                      context,
                                                    );
                                                  } else {
                                                    await authService.sendOtp(
                                                      authService
                                                          .completePhoneNumber,
                                                      _nameController.text
                                                          .trim(),
                                                      context,
                                                    );
                                                  }
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: _kBorderRadius),
                                          elevation: 0,
                                        ),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: (authService.isLoading ||
                                                    authService.isVerifying)
                                                ? LinearGradient(
                                                    colors: [
                                                      Colors.grey[400]!,
                                                      Colors.grey[500]!
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                : _kPrimaryGradient,
                                            borderRadius: _kBorderRadius,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            height: isTablet ? 60 : 56,
                                            alignment: Alignment.center,
                                            child: authService.isLoading ||
                                                    authService.isVerifying
                                                ? const CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  )
                                                : Text(
                                                    authService.isOtpSent
                                                        ? lang.confirmCode
                                                        : lang
                                                            .sendVerificationCode,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (authService.isOtpSent) ...[
                                      const SizedBox(height: 16),
                                      TextButton(
                                        onPressed: authService.countdown == 0
                                            ? () {
                                                HapticFeedback.lightImpact();
                                                authService.sendOtp(
                                                  authService
                                                      .completePhoneNumber,
                                                  _nameController.text.trim(),
                                                  context,
                                                  isResend: true,
                                                );
                                              }
                                            : null,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                        child: Text(
                                          authService.countdown > 0
                                              ? lang.resendInSeconds(
                                                  authService.countdown)
                                              : lang.resendCode,
                                          style: TextStyle(
                                            color: authService.countdown == 0
                                                ? _kPrimaryColor
                                                : Colors.grey[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          authService.resetOtpState();
                                          _otpController.clear();
                                          _nameController.clear();
                                          _phoneController.clear();
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                        child: Text(
                                          lang.changePhoneNumber,
                                          style: const TextStyle(
                                            color: _kPrimaryColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        // TODO: Implement terms and conditions navigation
                                      },
                                      child: Text(
                                        lang.termsAndConditions,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Inter',
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
      ),
    );
  }
}
