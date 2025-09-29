import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../globel/var_glob.dart';

class LanguageProvider with ChangeNotifier {
  bool _isHighContrastMode = false;
  static const _supportedLocales = ['en', 'ar', 'fr', 'kab'];
  static const _localeKey = 'selected_locale';
  Locale _locale = const Locale('ar');
  bool get isHighContrastMode => _isHighContrastMode;

  void setHighContrastMode(bool value) {
    _isHighContrastMode = value;
    notifyListeners();
  }

  Locale get locale => _locale;

  LanguageProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    if (savedLocale != null && _supportedLocales.contains(savedLocale)) {
      _locale = Locale(savedLocale);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale, {BuildContext? context}) async {
    if (!_supportedLocales.contains(locale.languageCode)) return;

    if (_locale != locale) {
      _locale = locale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
      notifyListeners();

      // Show confirmation snackbar
      if (context != null) {
        final lang = AppLocalizations.of(context);
        final snackBar = SnackBar(
          content: Text(
            lang?.languageChanged ??
                'Language changed to ${locale.languageCode}',
            style: TextStyle(
              fontFamily:
                  locale.languageCode == 'ar' || locale.languageCode == 'kab'
                      ? 'NotoSansArabic'
                      : 'Inter',
              color: Colors.white,
            ),
            semanticsLabel: lang?.languageChanged ?? 'Language changed',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          duration: const Duration(seconds: 2),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        // Announce language change for accessibility
        SemanticsService.announce(
          lang?.languageChanged ?? 'Language changed to ${locale.languageCode}',
          TextDirection.ltr,
        );
      }
    }
  }
}
