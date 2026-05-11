import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoUtil {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return 'Android ${info.version.release ?? 'unknown'}, ${info.model ?? 'unknown'}, ${info.manufacturer ?? 'unknown'}';
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return 'iOS ${info.systemVersion ?? 'unknown'}, ${info.model ?? 'unknown'}, ${info.name ?? 'unknown'}';
      } else if (Platform.isWindows) {
        final info = await _deviceInfo.windowsInfo;
        return 'Windows ${info.productName ?? 'unknown'}';
      } else if (Platform.isLinux) {
        final info = await _deviceInfo.linuxInfo;
        return 'Linux ${info.prettyName ?? 'unknown'}';
      } else if (Platform.isMacOS) {
        final info = await _deviceInfo.macOsInfo;
        return 'macOS ${info.computerName ?? 'unknown'}';
      }
    } catch (e) {
      // ignore
    }
    return 'Unknown Device';
  }

  static Future<String> getPublicIP() async {
    // In a real implementation, use a service or skip
    return '0.0.0.0';
  }
}

