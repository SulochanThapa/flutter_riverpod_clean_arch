import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_constants.dart';

class TokenService {
  final SharedPreferences _prefs;
  final Duration _refreshThreshold = const Duration(minutes: 5);

  TokenService(this._prefs);

  String? getAccessToken() => _prefs.getString(StorageConstants.accessToken);
  String? getRefreshToken() => _prefs.getString(StorageConstants.refreshToken);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
    
    await Future.wait([
      _prefs.setString(StorageConstants.accessToken, accessToken),
      _prefs.setString(StorageConstants.refreshToken, refreshToken),
      _prefs.setInt(StorageConstants.tokenExpiry, expiryTime.millisecondsSinceEpoch),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _prefs.remove(StorageConstants.accessToken),
      _prefs.remove(StorageConstants.refreshToken),
      _prefs.remove(StorageConstants.tokenExpiry),
    ]);
  }

  bool get hasValidToken {
    final expiry = _getTokenExpiry();
    if (expiry == null) return false;
    return DateTime.now().isBefore(expiry);
  }

  bool get needsRefresh {
    final expiry = _getTokenExpiry();
    if (expiry == null) return false;
    
    final refreshTime = expiry.subtract(_refreshThreshold);
    return DateTime.now().isAfter(refreshTime);
  }

  DateTime? _getTokenExpiry() {
    final expiryMs = _prefs.getInt(StorageConstants.tokenExpiry);
    if (expiryMs == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(expiryMs);
  }
}