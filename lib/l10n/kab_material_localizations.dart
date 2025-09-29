import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class KabMaterialLocalizations extends DefaultMaterialLocalizations {
  const KabMaterialLocalizations();

  @override
  String get okButtonLabel => 'IH';

  @override
  String get cancelButtonLabel => 'Sefsex';

  @override
  String get closeButtonLabel => 'Mdel';

  @override
  String get backButtonTooltip => 'Uɣal';

  @override
  String get searchFieldLabel => 'Nadi';

  @override
  String get selectAllButtonLabel => 'Fren akk';

  @override
  String get pasteButtonLabel => 'Senteḍ';

  @override
  String get copyButtonLabel => 'Nɣel';

  @override
  String get cutButtonLabel => 'Gzem';

  // Add more overrides as needed for your app's UI
}

class KabMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const KabMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'kab';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return const KabMaterialLocalizations();
  }

  @override
  bool shouldReload(
          covariant LocalizationsDelegate<MaterialLocalizations> old) =>
      false;
}
