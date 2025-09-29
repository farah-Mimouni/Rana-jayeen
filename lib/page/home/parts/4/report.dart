import 'package:flutter/material.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/constants.dart';
import '../../../../globel/section_title.dart';

class RoadIssueReport extends StatefulWidget {
  const RoadIssueReport({Key? key}) : super(key: key);

  @override
  State<RoadIssueReport> createState() => _RoadIssueReportState();
}

class _RoadIssueReportState extends State<RoadIssueReport> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        precacheImage(
          const AssetImage(
              'assets/images/set-temporary-elements-emergency-fencing-260nw-2453361135 (2).png'),
          context,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SectionTitle(
            title: l10n.notifications_title,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: [
              RoadIssueCard(
                image:
                    "assets/images/set-temporary-elements-emergency-fencing-260nw-2453361135 (2).png",
                category: l10n.report_category,
                description: l10n.pothole_report_description,
                press: () {
                  Navigator.pushNamed(context, Detailtest.routeName);
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class RoadIssueCard extends StatelessWidget {
  const RoadIssueCard({
    Key? key,
    required this.category,
    required this.image,
    required this.description,
    required this.press,
  }) : super(key: key);

  final String category, image, description;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: EdgeInsets.only(
        left: isRTL ? 0 : 16,
        right: isRTL ? 16 : 0,
        bottom: 16,
      ),
      child: GestureDetector(
        onTap: press,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuad,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            width: 300,
            height: 140,
            decoration: BoxDecoration(
              color: kSurface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.asset(
                    image,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: kTextSecondary.withOpacity(0.2),
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: kTextSecondary,
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: isRTL
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
                              fontFamily: 'WorkSans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                            textAlign: isRTL ? TextAlign.right : TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontFamily: 'WorkSans',
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            textAlign: isRTL ? TextAlign.right : TextAlign.left,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
    );
  }
}

class Detailtest extends StatelessWidget {
  static const String routeName = "/detailtest";

  const Detailtest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: kSurface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.report_pothole,
          style: const TextStyle(
            fontFamily: 'WorkSans',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  kPrimaryColor.withOpacity(0.1),
                  kSurface,
                ],
              ),
            ),
          ),
          // Input UI
          SingleChildScrollView(
            child: Column(
              children: [
                _buildImageSection(),
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kSurface.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageButtons(l10n),
                      const SizedBox(height: 16),
                      _buildDescriptionField(l10n, isRTL),
                      const SizedBox(height: 16),
                      _buildLocationSection(l10n),
                      const SizedBox(height: 16),
                      _buildSubmitButton(l10n),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Service Not Available Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: kSurface.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.service_not_available,
                        style: const TextStyle(
                          fontFamily: 'WorkSans',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.service_not_available_message,
                        style: const TextStyle(
                          fontFamily: 'WorkSans',
                          fontSize: 14,
                          color: kTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          l10n.back,
                          style: const TextStyle(
                            fontFamily: 'WorkSans',
                            fontSize: 16,
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 200,
      color: kTextSecondary.withOpacity(0.2),
      child: Image.asset(
        'assets/images/animated_flashing_construction_barracade.gif',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.image_not_supported,
          size: 50,
          color: kTextSecondary,
        ),
      ),
    );
  }

  Widget _buildImageButtons(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor.withOpacity(0.5),
              foregroundColor: Colors.white.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.photo_library),
            label: Text(
              l10n.add_from_gallery,
              style: const TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor.withOpacity(0.5),
              foregroundColor: Colors.white.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.camera_alt),
            label: Text(
              l10n.add_from_gallery,
              style: const TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(AppLocalizations l10n, bool isRTL) {
    return TextFormField(
      enabled: false,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: l10n.additional_info,
        labelStyle: const TextStyle(
          fontFamily: 'WorkSans',
          fontSize: 14,
          color: kTextSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kTextSecondary.withOpacity(0.5)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kTextSecondary.withOpacity(0.5)),
        ),
      ),
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
    );
  }

  Widget _buildLocationSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.your_location,
          style: const TextStyle(
            fontFamily: 'WorkSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, color: kPrimaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.locating,
                style: const TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 14,
                  color: kTextSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor.withOpacity(0.5),
          foregroundColor: Colors.white.withOpacity(0.7),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          l10n.submit,
          style: const TextStyle(
            fontFamily: 'WorkSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
