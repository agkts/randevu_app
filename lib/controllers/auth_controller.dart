import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import '/models/hairdresser.dart';
import '/services/api_service.dart';

enum UserRole { hairdresser, salonOwner, none }

class AuthController extends GetxController {
  final ApiService _apiService = ApiService();

  // Kullanıcı bilgileri
  final Rx<String?> _userId = Rx<String?>(null);
  final Rx<String?> _userName = Rx<String?>(null);
  final Rx<UserRole> _userRole = Rx<UserRole>(UserRole.none);
  final Rx<String?> _userToken = Rx<String?>(null);
  final Rx<String?> _salonId = Rx<String?>(null);

  // Yükleniyor durumu
  final RxBool isLoading = false.obs;

  // Getter metotları
  String? get userId => _userId.value;
  String? get userName => _userName.value;
  UserRole get userRole => _userRole.value;
  String? get userToken => _userToken.value;
  String? get salonId => _salonId.value;

  // Giriş yapmış durumda mı?
  bool get isLoggedIn => _userToken.value != null;

  // Kuaför mü?
  bool get isHairdresser =>
      isLoggedIn && _userRole.value == UserRole.hairdresser;

  // Salon sahibi mi?
  bool get isSalonOwner => isLoggedIn && _userRole.value == UserRole.salonOwner;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  // Kullanıcı verisini SharedPreferences'dan yükleme
  Future<void> _loadUserData() async {
    isLoading.value = true;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final String? userId = prefs.getString('userId');
      final String? userName = prefs.getString('userName');
      final String? userRoleStr = prefs.getString('userRole');
      final String? userToken = prefs.getString('userToken');
      final String? salonId = prefs.getString('salonId');

      _userId.value = userId;
      _userName.value = userName;
      _userRole.value = _parseUserRole(userRoleStr);
      _userToken.value = userToken;
      _salonId.value = salonId;

      // Token varsa API service'e ayarla
      if (userToken != null) {
        _apiService.setToken(userToken);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // String'i UserRole enum'una çevirme
  UserRole _parseUserRole(String? roleStr) {
    if (roleStr == 'hairdresser') {
      return UserRole.hairdresser;
    } else if (roleStr == 'salonOwner') {
      return UserRole.salonOwner;
    }
    return UserRole.none;
  }

  // Giriş yapma
  Future<bool> login(String username, String password) async {
    isLoading.value = true;

    try {
      final response = await _apiService.login(username, password);

      if (response['success'] == true) {
        final userData = response['data'];

        final String userId = userData['user_id'];
        final String userName = userData['user_name'];
        final String userRoleStr = userData['user_role'];
        final String userToken = userData['token'];
        final String salonId = userData['salon_id'];

        // Kullanıcı verilerini ayarla
        _userId.value = userId;
        _userName.value = userName;
        _userRole.value = _parseUserRole(userRoleStr);
        _userToken.value = userToken;
        _salonId.value = salonId;

        // API service'e token'ı ayarla
        _apiService.setToken(userToken);

        // Kullanıcı verilerini SharedPreferences'a kaydet
        await _saveUserData(userId, userName, userRoleStr, userToken, salonId);

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Kullanıcı verilerini SharedPreferences'a kaydetme
  Future<void> _saveUserData(
    String userId,
    String userName,
    String userRole,
    String token,
    String salonId,
  ) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('userId', userId);
      await prefs.setString('userName', userName);
      await prefs.setString('userRole', userRole);
      await prefs.setString('userToken', token);
      await prefs.setString('salonId', salonId);
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  // Çıkış yapma
  Future<void> logout() async {
    isLoading.value = true;

    try {
      // SharedPreferences'dan kullanıcı verilerini sil
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('userName');
      await prefs.remove('userRole');
      await prefs.remove('userToken');
      await prefs.remove('salonId');

      // Kullanıcı verilerini sıfırla
      _userId.value = null;
      _userName.value = null;
      _userRole.value = UserRole.none;
      _userToken.value = null;
      _salonId.value = null;

      // API service'den token'ı kaldır
      _apiService.clearToken();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
