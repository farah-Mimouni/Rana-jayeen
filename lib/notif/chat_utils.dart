import 'package:flutter/material.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';

class ChatUtils {
  static String getChatId(String userId, String providerId) {
    final ids = [userId, providerId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  static IconData getServiceIcon(String serviceType) {
    const iconMap = {
      'stationaryCarWash': Icons.local_car_wash,
      'mobileCarWash': Icons.local_car_wash,
      'gas_station': Icons.local_gas_station,
      'spare_parts': Icons.build,
      'car_rental': Icons.car_rental,
      'wheel_change': Icons.tire_repair,
      'towing': Icons.local_shipping,
      'battery_charge': Icons.battery_charging_full,
      'car_mechanic': Icons.build_circle,
      'car_electrician': Icons.electrical_services,
      'car_inspection': Icons.car_repair,
      'key_programming': Icons.key,
      'car_ac_service': Icons.ac_unit,
      'tire_change': Icons.tire_repair,
      'full_repair': Icons.build_circle,
      'routine_maintenance': Icons.tune,
      'glass_repair': Icons.window,
    };
    return iconMap[serviceType] ?? Icons.directions_car;
  }

  static String getLocalizedServiceTitle(
      AppLocalizations? lang, String? serviceType) {
    const serviceTitleKeys = {
      'wheel_change': 'wheelChangeTitle',
      'towing': 'towTruckTitle',
      'battery_charge': 'batteryChargeTitle',
      'car_mechanic': 'carMechanicTitle',
      'car_electrician': 'carElectricianTitle',
      'car_inspection': 'carInspectionTitle',
      'key_programming': 'keyProgrammingTitle',
      'car_ac_service': 'carACServiceTitle',
      'stationaryCarWash': 'stationary_car_wash',
      'mobileCarWash': 'mobile_car_wash',
      'gas_station': 'gasStation',
      'spare_parts': 'sparePartsTitle',
      'car_rental': 'carRentalTitle',
      'tire_change': 'tireRepairTitle',
      'full_repair': 'fullRepairTitle',
      'routine_maintenance': 'routineMaintenanceTitle',
      'glass_repair': 'glassRepairTitle',
    };

    final key = serviceTitleKeys[serviceType] ?? 'new_service_request';
    if (lang == null) return serviceType ?? 'Service';
    switch (key) {
      case 'wheelChangeTitle':
        return lang.wheelChangeTitle;
      case 'towTruckTitle':
        return lang.towTruckTitle;
      case 'batteryChargeTitle':
        return lang.batteryChargeTitle;
      case 'carMechanicTitle':
        return lang.carMechanicTitle;
      case 'carElectricianTitle':
        return lang.carElectricianTitle;
      case 'carInspectionTitle':
        return lang.carInspectionTitle;
      case 'keyProgrammingTitle':
        return lang.keyProgrammingTitle;
      case 'carACServiceTitle':
        return lang.carACServiceTitle;
      case 'stationary_car_wash':
        return lang.carWashTitle;
      case 'mobile_car_wash':
        return lang.mobile_car_wash;
      case 'gasStation':
        return lang.gasStation;
      case 'sparePartsTitle':
        return lang.sparePartsTitle;
      case 'carRentalTitle':
        return lang.carRentalTitle;
      case 'tireRepairTitle':
        return lang.tireRepairTitle;
      case 'fullRepairTitle':
        return lang.fullRepairTitle;
      case 'routineMaintenanceTitle':
        return lang.routineMaintenanceTitle;
      case 'glassRepairTitle':
        return lang.glassRepairTitle;
      default:
        return lang.requestService;
    }
  }
}
