import 'package:flutter_test/flutter_test.dart';
import 'package:nira/device/device_profile.dart';

void main() {
  group('Device Level Classification', () {
    test('4 GB device should be LOW', () {
      expect(
        classifyDeviceLevel(4),
        DeviceLevel.low,
      );
    });

    test('6 GB device should be MEDIUM', () {
      expect(
        classifyDeviceLevel(6),
        DeviceLevel.medium,
      );
    });

    test('8 GB device should be HIGH', () {
      expect(
        classifyDeviceLevel(8),
        DeviceLevel.high,
      );
    });
  });
}

DeviceLevel classifyDeviceLevel(int ram) {
  if (ram <= 4) {
    return DeviceLevel.low;
  } else if (ram <= 6) {
    return DeviceLevel.medium;
  } else {
    return DeviceLevel.high;
  }
}