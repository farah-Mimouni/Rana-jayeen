import 'package:flutter/material.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/constants.dart';
import 'package:rana_jayeen/page/home/parts/3/dyn_princ.dart';

import '../../../../globel/section_title.dart';

class princi_service_page extends StatefulWidget {
  const princi_service_page({Key? key}) : super(key: key);

  @override
  _princi_service_pageState createState() => _princi_service_pageState();
}

class _princi_service_pageState extends State<princi_service_page>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final screenWidth = MediaQuery.of(context).size.width;

    final List<Map<String, String>> services = [
      {
        'type': 'wheel_change',
        'title': lang.wheelChangeTitle,
        'description': lang.wheelChangeDescription,
        'image': 'assets/design_course/whel.png',
      },
      {
        'type': 'towing',
        'title': lang.towTruckTitle,
        'description': lang.towTruckDescription,
        'image': 'assets/images/dep7-removebg-preview.png',
      },
      {
        'type': 'battery_charge',
        'title': lang.batteryChargeTitle,
        'description': lang.batteryChargeDescription,
        'image': 'assets/images/istockphoto-1757212225-612x612.jpg',
      },
      {
        'type': 'car_mechanic',
        'title': lang.carMechanicTitle,
        'description': lang.carMechanicDescription,
        'image':
            'assets/images/psd-with-transparent-3d-race-car-mechanic-cartoon-tuning-high-speed-vehicle_1052902-8118-removebg-preview.png',
      },
      {
        'type': 'car_electrician',
        'title': lang.carElectricianTitle,
        'description': lang.carElectricianDescription,
        'image':
            'assets/images/car-repairman-wearing-white-uniform-standing-holding-wrench-that-is-essential-tool-mechanic.jpg',
      },
      {
        'type': 'car_inspection',
        'title': lang.carInspectionTitle,
        'description': lang.carInspectionDescription,
        'image': 'assets/images/istockphoto-492016506-612x612.jpg',
      },
      {
        'type': 'key_programming',
        'title': lang.keyProgrammingTitle,
        'description': lang.keyProgrammingDescription,
        'image': 'assets/images/istockphoto-1371586558-612x612.jpg',
      },
      {
        'type': 'car_ac_service',
        'title': lang.carACServiceTitle,
        'description': lang.carACServiceDescription,
        'image': 'assets/images/car_ac_service.png',
      },
    ];

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment:
              isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: 12,
              ),
              child: SectionTitle(
                title: lang.popularServices,
              ),
            ),
            _buildServiceGrid(
                services.take(screenWidth > 600 ? 6 : 4).toList()),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: 12,
              ),
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AllServicesPage(services: services),
                      ),
                    );
                  },
                  child: Text(
                    lang.seeMore,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildServiceGrid(List<Map<String, String>> services) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: 8,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenWidth > 600 ? 3 : 2,
        childAspectRatio: screenWidth > 600 ? 0.8 : 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(services[index], index);
      },
    );
  }

  Widget _buildServiceCard(Map<String, String> service, int index) {
    final lang = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animationValue =
            Curves.easeOut.transform(_animationController.value);
        return Transform.translate(
          offset: Offset(0, 16 * (1 - animationValue)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Semantics(
        label: 'Service: ${service['title']}',
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DynamicServicePage(
                  serviceType: service['type'],
                  serviceTitle: service['title'],
                  serviceImage: service['image'],
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: kPrimaryColor.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    service['image']!,
                    height: 70,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.error_outline,
                        color: kPrimaryColor.withOpacity(0.5),
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  service['title']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  service['description']!,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AllServicesPage extends StatelessWidget {
  final List<Map<String, String>> services;

  const AllServicesPage({Key? key, required this.services}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.allServices,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: kPrimaryColor,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: 16,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth > 600 ? 3 : 2,
          childAspectRatio: screenWidth > 600 ? 0.8 : 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return _buildServiceCard(context, services[index], index);
        },
      ),
    );
  }

  Widget _buildServiceCard(
      BuildContext context, Map<String, String> service, int index) {
    final lang = AppLocalizations.of(context)!;
    return Semantics(
      label: 'Service: ${service['title']}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DynamicServicePage(
                serviceType: service['type'],
                serviceTitle: service['title'],
                serviceImage: service['image'],
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: kPrimaryColor.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  service['image']!,
                  height: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: kPrimaryColor.withOpacity(0.5),
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                service['title']!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                service['description']!,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
