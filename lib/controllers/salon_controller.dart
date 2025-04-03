import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/salon.dart';
import '../models/hairdresser.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';

class SalonController extends GetxController {
  final ApiService _apiService = ApiService();
  final AuthController _authController = Get.find<AuthController>();

  // Salon bilgisi
  final Rx<Salon?> salon = Rx<Salon?>(null);

  // Yükleniyor durumu
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Kullanıcı giriş yapmışsa salon bilgilerini yükle
    if (_authController.isLoggedIn && _authController.salonId != null) {
      loadSalon();
    }
  }

  // Salon bilgilerini yükle
  Future<void> loadSalon() async {
    if (_authController.salonId == null) {
      return;
    }

    isLoading.value = true;

    try {
      final response = await _apiService.getSalon(_authController.salonId!);

      if (response['success'] == true) {
        final salonData = response['data'];
        salon.value = Salon.fromJson(salonData);
      }
    } catch (e) {
      debugPrint('Error loading salon: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Salon bilgilerini güncelle
  Future<bool> updateSalon(Map<String, dynamic> data) async {
    if (_authController.salonId == null || !_authController.isSalonOwner) {
      return false;
    }

    isUpdating.value = true;

    try {
      final response = await _apiService.updateSalon(
        _authController.salonId!,
        data,
      );

      if (response['success'] == true) {
        await loadSalon();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating salon: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // Salon çalışma saatlerini güncelle
  Future<bool> updateWorkingHours(
    Map<String, WorkingHours> workingSchedule,
  ) async {
    if (_authController.salonId == null || !_authController.isSalonOwner) {
      return false;
    }

    isUpdating.value = true;

    try {
      final Map<String, dynamic> data = {'working_schedule': workingSchedule};

      final response = await _apiService.updateSalon(
        _authController.salonId!,
        data,
      );

      if (response['success'] == true) {
        await loadSalon();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating salon working hours: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // Salon ayarlarını güncelle
  Future<bool> updateSalonSettings(SalonSettings settings) async {
    if (_authController.salonId == null || !_authController.isSalonOwner) {
      return false;
    }

    isUpdating.value = true;

    try {
      final Map<String, dynamic> data = {'settings': settings.toJson()};

      final response = await _apiService.updateSalon(
        _authController.salonId!,
        data,
      );

      if (response['success'] == true) {
        await loadSalon();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating salon settings: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // SMS ayarlarını güncelle
  Future<bool> updateSmsSettings(SmsSettings smsSettings) async {
    if (_authController.salonId == null || !_authController.isSalonOwner) {
      return false;
    }

    isUpdating.value = true;

    try {
      final Map<String, dynamic> data = {'sms_settings': smsSettings.toJson()};

      final response = await _apiService.updateSalon(
        _authController.salonId!,
        data,
      );

      if (response['success'] == true) {
        await loadSalon();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating SMS settings: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}
