import 'package:flutter/foundation.dart';

class FirebaseDebugHelper {
  static void logOperation({
    required String operation,
    required String path,
    Map<String, dynamic>? data,
    dynamic result,
    dynamic error,
  }) {
    if (!kDebugMode) return;

    debugPrint('🔥 FIREBASE OPERATION: $operation');
    debugPrint('📁 PATH: $path');

    if (data != null) {
      debugPrint('📦 DATA: ${data.toString()}');
    }

    if (result != null) {
      debugPrint('✅ RESULT: $result');
    }

    if (error != null) {
      debugPrint('❌ ERROR: $error');

      // Add stack trace if available
      if (error is Error) {
        debugPrint('📚 STACK TRACE: ${error.stackTrace}');
      }
    }

    debugPrint('------------------------------');
  }

  static void logStorageOperation({
    required String operation,
    required String path,
    String? contentType,
    int? fileSize,
    dynamic result,
    dynamic error,
  }) {
    if (!kDebugMode) return;

    debugPrint('📤 STORAGE OPERATION: $operation');
    debugPrint('📁 PATH: $path');

    if (contentType != null) {
      debugPrint('📄 CONTENT TYPE: $contentType');
    }

    if (fileSize != null) {
      debugPrint('📏 FILE SIZE: ${(fileSize / 1024).toStringAsFixed(2)} KB');
    }

    if (result != null) {
      debugPrint('✅ RESULT: $result');
    }

    if (error != null) {
      debugPrint('❌ ERROR: $error');

      // Add stack trace if available
      if (error is Error) {
        debugPrint('📚 STACK TRACE: ${error.stackTrace}');
      }
    }

    debugPrint('------------------------------');
  }
}
