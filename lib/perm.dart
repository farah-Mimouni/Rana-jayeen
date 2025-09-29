import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';

import 'constants.dart';

class PermissionService {
  static Future<bool> requestPermission(
      Permission permission, BuildContext context) async {
    final status = await permission.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      final result = await permission.request();
      if (!result.isGranted && context.mounted) {
        final lang = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang?.locationPermissionDenied ??
                  'Location permission denied. Please enable it for ride-sharing features.',
              style: TextStyle(
                // fontFamily: _getFontFamily(lang?.localeName),
                color: kTextPrimary,
                fontSize: 14,
              ),
            ),
            action: SnackBarAction(
              label: lang?.settings ?? 'Settings',
              onPressed: openAppSettings,
              textColor: kPrimary,
            ),
            backgroundColor: kBackground,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return result.isGranted;
    }
    return status.isGranted;
  }
}
