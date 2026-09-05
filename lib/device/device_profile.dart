import 'package:device_info_plus/device_info_plus.dart';

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

  static Future<DeviceProfile> getProfile() async {
    final deviceInfo = DeviceInfoPlugin();

    final androidInfo = await deviceInfo.androidInfo;

    final deviceName = androidInfo.model;
    final platform = 'Android';
    final architecture = androidInfo.supportedAbis.isNotEmpty
        ? androidInfo.supportedAbis.first
        : 'Unknown';

    // Android does not directly provide total RAM through
    // device_info_plus, so we use a safe demo value for now.
    const ram = 8;

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