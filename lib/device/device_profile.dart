import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

enum DeviceLevel {
  low,
  medium,
  high,
}

class DeviceProfile {
  final String deviceName;
  final String platform;
  final String architecture;
  final int ram;
  final DeviceLevel level;

  DeviceProfile({
    required this.deviceName,
    required this.platform,
    required this.architecture,
    required this.ram,
    required this.level,
  });

  static const MethodChannel _channel = MethodChannel('nira/device');

  static Future<DeviceProfile> getProfile() async {
    final deviceInfo = DeviceInfoPlugin();

    final androidInfo = await deviceInfo.androidInfo;

    final deviceName = androidInfo.model;
    final platform = 'Android';
    final architecture = androidInfo.supportedAbis.isNotEmpty
        ? androidInfo.supportedAbis.first
        : 'Unknown';

    final ramValue = await _channel.invokeMethod<double>('getRamGb');

    final ram = ramValue?.round() ?? 8;

    DeviceLevel level;

    if (ram <= 4) {
      level = DeviceLevel.low;
    } else if (ram <= 6) {
      level = DeviceLevel.medium;
    } else {
      level = DeviceLevel.high;
    }

    return DeviceProfile(
      deviceName: deviceName,
      platform: platform,
      architecture: architecture,
      ram: ram,
      level: level,
    );
  }

  String get levelText {
    switch (level) {
      case DeviceLevel.low:
        return 'LOW';
      case DeviceLevel.medium:
        return 'MEDIUM';
      case DeviceLevel.high:
        return 'HIGH';
    }
  }
}