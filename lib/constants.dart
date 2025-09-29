import 'package:flutter/material.dart';

const kPrimaryColor = Color(0xFF26C6DA);
const kPrimaryLightColor = Color(0xFFE0F7FA);
const kPrimaryGradientColor = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF26C6DA),
    Color(0xFF00ACC1),
  ],
);
const kSecondaryColor = Color(0xFF90A4AE);
const kTextColor = Color(0xFF1A2529);
const kPrimary = Color(0xFF26C6DA);
const kAccent = Color(0xFF4DB6AC);
const kBackground = Color(0xFFF8FBFE);
const kSurface = Color(0xFFF1F5F9);
const kError = Color(0xFFF44336);
const kEmergency = Color(0xFFEF5350);
const kSuccess = Color(0xFF2E7D32);
const kTextPrimary = Color(0xFF1A2529);
const kTextSecondary = Color(0xFF607D8B);
const kGradientStart = Color(0xFF00ACC1);
const kGradientEnd = Color(0xFFB2EBF2);
const kCardBackground = Color(0xFFF1F5F9);

const headingStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w700,
  fontFamily: 'WorkSans',
  color: kTextPrimary,
  height: 1.4,
  letterSpacing: 0.2,
);

const String font = 'WorkSans';
const defaultDuration = Duration(milliseconds: 300);
const kAnimationDuration = Duration(milliseconds: 250);
const kBorderRadius = BorderRadius.all(Radius.circular(12));
const kModernGradient = LinearGradient(
  colors: [Color(0xFF26C6DA), Color(0xFF0288D1)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const Color notWhite = Color(0xFFECEFF1);
const Color nearlyWhite = Color(0xFFF8FBFE);
const Color nearlyBlue = Color(0xFF00ACC1);
const Color nearlyBlack = Color(0xFF1A2529);
const Color grey = Color(0xFF607D8B);
const Color darkGrey = Color(0xFF37474F);
const Color darkText = Color(0xFF1A2529);
const Color darkerText = Color(0xFF0D171B);
const Color lightText = Color(0xFF78909C);
const Color deactivatedText = Color(0xFF90A4AE);
const Color dismissibleBackground = Color(0xFF37474F);
const Color chipBackground = Color(0xFFE0F7FA);
const Color spacer = Color(0xFFF1F5F9);

const TextStyle bodyLargeAccessible = TextStyle(
  fontFamily: 'WorkSans',
  fontWeight: FontWeight.w600,
  fontSize: 20,
  letterSpacing: 0.2,
  color: darkText,
);

const TextStyle bodyMediumAccessible = TextStyle(
  fontFamily: 'WorkSans',
  fontWeight: FontWeight.w500,
  fontSize: 18,
  letterSpacing: 0.2,
  color: darkText,
);

TextTheme textTheme(BuildContext context) {
  final scale = MediaQuery.of(context).textScaleFactor;
  return TextTheme(
    headlineMedium: display1.copyWith(fontSize: 38 * scale),
    headlineSmall: headline.copyWith(fontSize: 26 * scale),
    titleLarge: title.copyWith(fontSize: 18 * scale),
    titleSmall: subtitle.copyWith(fontSize: 16 * scale),
    bodyLarge: body2.copyWith(fontSize: 16 * scale),
    bodyMedium: body1.copyWith(fontSize: 18 * scale),
    bodySmall: caption.copyWith(fontSize: 14 * scale),
  );
}

ThemeData highContrastTheme(BuildContext context) {
  return ThemeData(
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: kBackground,
    textTheme: TextTheme(
      headlineMedium: display1.copyWith(color: Colors.black, fontSize: 42),
      headlineSmall: headline.copyWith(color: Colors.black, fontSize: 30),
      titleLarge: title.copyWith(color: Colors.black, fontSize: 20),
      titleSmall: subtitle.copyWith(color: Colors.black, fontSize: 18),
      bodyLarge: body2.copyWith(color: Colors.black, fontSize: 18),
      bodyMedium: body1.copyWith(color: Colors.black, fontSize: 20),
      bodySmall: caption.copyWith(color: Colors.black, fontSize: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
        textStyle: const TextStyle(
          fontFamily: 'WorkSans',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: kPrimaryColor,
      secondary: kSecondaryColor,
      error: kEmergency,
    ),
  );
}

const TextStyle display1 = TextStyle(
  fontFamily: 'WorkSans',
  fontWeight: FontWeight.w700,
  fontSize: 38,
  letterSpacing: 0.2,
  height: 1.2,
  color: darkerText,
);

const TextStyle headline = TextStyle(
  fontFamily: 'WorkSans',
  fontWeight: FontWeight.w700,
  fontSize: 26,
  letterSpacing: 0.2,
  color: darkerText,
);

const TextStyle title = TextStyle(
  fontFamily: 'WorkSans',
  fontWeight: FontWeight.w600,
  fontSize: 18,
  letterSpacing: 0.2,
  color: darkerText,
);

const TextStyle subtitle = TextStyle(
  fontFamily: 'WorkSans',
  fontWeight: FontWeight.w500,
  fontSize: 16,
  letterSpacing: 0.1,
  color: darkText,
);

const TextStyle body2 = TextStyle(
  fontFamily: 'WorkSans',
  fontWeight: FontWeight.w400,
  fontSize: 16,
  letterSpacing: 0.2,
  color: darkText,
);

const TextStyle body1 = TextStyle(
  fontFamily: 'WorkSans',
  fontWeight: FontWeight.w400,
  fontSize: 18,
  letterSpacing: 0.1,
  color: darkText,
);

const TextStyle caption = TextStyle(
  fontFamily: 'WorkSans',
  fontWeight: FontWeight.w400,
  fontSize: 14,
  letterSpacing: 0.2,
  color: lightText,
);

final otpInputDecoration = InputDecoration(
  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
  border: outlineInputBorder(),
  focusedBorder: outlineInputBorder(focused: true),
  enabledBorder: outlineInputBorder(),
  filled: true,
  fillColor: kCardBackground,
  hintStyle: const TextStyle(
    fontFamily: 'WorkSans',
    fontSize: 16,
    color: kTextSecondary,
  ),
);

ThemeData lightTheme(BuildContext context) {
  return ThemeData(
    scaffoldBackgroundColor: kBackground,
    fontFamily: 'WorkSans',
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: kTextPrimary),
      titleTextStyle: TextStyle(
        color: kTextPrimary,
        fontFamily: 'WorkSans',
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: textTheme(context),
    inputDecorationTheme: InputDecorationTheme(
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      enabledBorder: outlineInputBorder(),
      focusedBorder: outlineInputBorder(focused: true),
      border: outlineInputBorder(),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
        textStyle: const TextStyle(
          fontFamily: 'WorkSans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: kPrimaryColor,
      secondary: kSecondaryColor,
      error: kError,
      surface: kSurface,
      background: kBackground,
    ),
  );
}

OutlineInputBorder outlineInputBorder({bool focused = false}) {
  return OutlineInputBorder(
    borderRadius: kBorderRadius,
    borderSide: BorderSide(
      color: focused ? kPrimaryColor : kTextSecondary.withOpacity(0.5),
      width: focused ? 2 : 1,
    ),
  );
}
