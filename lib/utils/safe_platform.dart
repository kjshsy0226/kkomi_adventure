// lib/utils/safe_platform.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;

/// 웹/모바일/데스크톱 어디서든 안전하게 플랫폼 체크
class SafePlatform {
  static bool get isWeb => kIsWeb;

  // 데스크톱
  static bool get isWindows => !kIsWeb && io.Platform.isWindows;
  static bool get isMacOS => !kIsWeb && io.Platform.isMacOS;
  static bool get isLinux => !kIsWeb && io.Platform.isLinux;
  static bool get isDesktop => isWindows || isMacOS || isLinux;

  // 모바일
  static bool get isAndroid => !kIsWeb && io.Platform.isAndroid;
  static bool get isIOS => !kIsWeb && io.Platform.isIOS;
  static bool get isMobile => isAndroid || isIOS;
}
