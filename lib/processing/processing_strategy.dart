import '../device/device_profile.dart';
import '../router/intent_router.dart';

enum ProcessingMethod {
  lightweight,
  balanced,
  fullAi,
}

class ProcessingStrategy {
  static ProcessingMethod selectMethod(
    DeviceLevel deviceLevel,
    IntentType intent,
  ) {
    // Calculator queries are lightweight regardless of device level.
    if (intent == IntentType.calculator) {
      return ProcessingMethod.lightweight;
    }

    // Document queries use balanced processing.
    if (intent == IntentType.document) {
      return ProcessingMethod.balanced;
    }

    // General AI queries depend on the device capability.
    switch (deviceLevel) {
      case DeviceLevel.low:
        return ProcessingMethod.lightweight;

      case DeviceLevel.medium:
        return ProcessingMethod.balanced;

      case DeviceLevel.high:
        return ProcessingMethod.fullAi;
    }
  }

  static String methodText(ProcessingMethod method) {
    switch (method) {
      case ProcessingMethod.lightweight:
        return 'Lightweight processing';

      case ProcessingMethod.balanced:
        return 'Balanced processing';

      case ProcessingMethod.fullAi:
        return 'Full on-device AI';
    }
  }
}