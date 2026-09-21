import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/api_endpoints.dart';

/// Holds the latest app version info from the server.
class AppVersionInfo {
  final String latestVersion;
  final int versionCode;
  final String downloadUrl;
  final String? releaseNotes;
  final bool updateAvailable;
  final bool forceUpdate;

  const AppVersionInfo({
    required this.latestVersion,
    required this.versionCode,
    required this.downloadUrl,
    this.releaseNotes,
    required this.updateAvailable,
    this.forceUpdate = false,
  });
}

/// State for the update process.
class AppUpdateState {
  final bool isChecking;
  final bool isDownloading;
  final double downloadProgress;
  final String? errorMessage;
  final AppVersionInfo? versionInfo;

  const AppUpdateState({
    this.isChecking = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.errorMessage,
    this.versionInfo,
  });

  AppUpdateState copyWith({
    bool? isChecking,
    bool? isDownloading,
    double? downloadProgress,
    String? errorMessage,
    AppVersionInfo? versionInfo,
    bool clearError = false,
  }) {
    return AppUpdateState(
      isChecking: isChecking ?? this.isChecking,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      versionInfo: versionInfo ?? this.versionInfo,
    );
  }
}

/// Current app version (must match pubspec.yaml "version: X.Y.Z+build")
/// Update this ONLY when you bump pubspec.yaml — e.g. 1.0.0 → '1.0.0'
const String kCurrentAppVersion = '1.0.0';

/// Derived version code using semver math: major*10000 + minor*100 + patch
/// v1.0.0 → 10000, v1.0.1 → 10001, v1.2.3 → 10203, v2.0.0 → 20000
/// This MUST match the tag you publish on GitHub (e.g. tag "v1.0.0" → 10000)
const int kCurrentVersionCode = 10000;

/// Helper: parse "1.2.3" or "v1.2.3" → integer version code
int parseVersionCode(String version) {
  final clean = version.replaceAll(RegExp(r'^v'), '').trim();
  final parts = clean.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final major = parts.isNotEmpty ? parts[0] : 1;
  final minor = parts.length > 1 ? parts[1] : 0;
  final patch = parts.length > 2 ? parts[2] : 0;
  return major * 10000 + minor * 100 + patch;
}

/// Default APK direct download URL (GitHub Releases fallback)
const String kDefaultApkDownloadUrl =
    'https://github.com/Vasanthan-2005/FoodBillX/releases/latest/download/app-release.apk';

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  static const MethodChannel _installerChannel =
      MethodChannel('com.foodbillx.app/apk_installer');

  AppUpdateNotifier() : super(const AppUpdateState());

  /// Check the server for latest version info.
  Future<void> checkForUpdate() async {
    if (state.isChecking) return;
    state = state.copyWith(isChecking: true, clearError: true);

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
      ));

      // Attempt 1: GET /api/app-version (standard endpoint)
      final serverRoot = ApiEndpoints.baseUrl.replaceAll('/api/v1', '');
      final primaryUrl = '$serverRoot/api/app-version';
      Response? response;

      try {
        response = await dio.get(primaryUrl);
      } catch (err) {
        // Attempt 2: Fallback to /api/v1/app/version
        final fallbackUrl = '${ApiEndpoints.baseUrl}${ApiEndpoints.appVersionCheck}';
        response = await dio.get(fallbackUrl);
      }

      final body = response.data;
      Map data = {};
      if (body is Map) {
        if (body['data'] is Map) {
          data = body['data'] as Map;
        } else {
          data = body;
        }
      }

      final latestVersion = (data['latestVersion'] ?? data['version'] ?? kCurrentAppVersion).toString();
      // Backend sends versionCode derived from semver tag (same parseVersionCode logic)
      final remoteVersionCode = (data['versionCode'] as num?)?.toInt()
          ?? parseVersionCode(latestVersion);
      final downloadUrl = (data['downloadUrl'] ?? kDefaultApkDownloadUrl).toString();
      final releaseNotes = data['releaseNotes']?.toString() ??
          '• Performance improvements\n• Bug fixes and UI refinements';
      final forceUpdate = data['forceUpdate'] == true;

      // Update available if remote versionCode is strictly greater than current
      final updateAvailable = remoteVersionCode > kCurrentVersionCode;

      state = state.copyWith(
        isChecking: false,
        versionInfo: AppVersionInfo(
          latestVersion: latestVersion,
          versionCode: remoteVersionCode,
          downloadUrl: downloadUrl,
          releaseNotes: releaseNotes,
          updateAvailable: updateAvailable,
          forceUpdate: forceUpdate,
        ),
      );
    } on DioException catch (e) {
      String message;
      final statusCode = e.response?.statusCode;
      if (statusCode == 404) {
        message = 'Update server not configured yet. Check your connection or use manual download.';
      } else if (statusCode != null && statusCode >= 500) {
        message = 'Server error ($statusCode). Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Connection timed out. Check your internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Cannot reach server. Check your internet connection.';
      } else {
        message = 'Unable to check for updates right now.';
      }
      state = state.copyWith(isChecking: false, errorMessage: message);
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        errorMessage: 'Unable to check for updates right now.',
      );
    }
  }

  /// Check if the app has permission to install unknown APKs on Android.
  Future<bool> canRequestPackageInstalls() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool canInstall =
          await _installerChannel.invokeMethod('canRequestPackageInstalls') ?? true;
      return canInstall;
    } catch (_) {
      return true;
    }
  }

  /// Open Android system settings to grant "Install unknown apps" permission.
  Future<void> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _installerChannel.invokeMethod('openInstallPermissionSettings');
    } catch (_) {}
  }

  /// Download the APK from downloadUrl and launch the native Android APK installer.
  Future<bool> downloadAndInstall() async {
    final info = state.versionInfo;
    if (info == null || state.isDownloading) return false;

    state = state.copyWith(isDownloading: true, downloadProgress: 0.0, clearError: true);

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/foodbillx_v${info.versionCode}.apk';

      // Delete any stale existing download first
      final existingFile = File(filePath);
      if (await existingFile.exists()) {
        try {
          await existingFile.delete();
        } catch (_) {}
      }

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 5),
      ));

      await dio.download(
        info.downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            state = state.copyWith(
              downloadProgress: (received / total).clamp(0.0, 1.0),
            );
          }
        },
      );

      state = state.copyWith(isDownloading: false, downloadProgress: 1.0);

      final downloadedFile = File(filePath);
      if (!await downloadedFile.exists()) {
        state = state.copyWith(errorMessage: 'Downloaded APK file could not be found.');
        return false;
      }

      if (Platform.isAndroid) {
        // Check "Install unknown apps" permission
        final canInstall = await canRequestPackageInstalls();
        if (!canInstall) {
          await openInstallPermissionSettings();
          state = state.copyWith(
            errorMessage: 'Please toggle "Allow from this source" in Settings, then tap Update Now again.',
          );
          return false;
        }

        // Launch system package installer via FileProvider
        final bool launched = await _installerChannel.invokeMethod('installApk', {
          'filePath': filePath,
        }) ?? false;

        return launched;
      }

      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isDownloading: false,
        errorMessage: e.message ?? 'Download failed. Please check internet connection.',
      );
      return false;
    } catch (e) {
      if (kDebugMode) print('Download error: $e');
      state = state.copyWith(
        isDownloading: false,
        errorMessage: 'Download failed: $e',
      );
      return false;
    }
  }

  /// Reset error or progress state
  void resetState() {
    state = state.copyWith(clearError: true, downloadProgress: 0.0, isDownloading: false);
  }
}

final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  return AppUpdateNotifier();
});
