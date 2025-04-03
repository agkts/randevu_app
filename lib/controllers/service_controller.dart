import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/service.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';

class ServiceController extends GetxController {
  final ApiService _apiService = ApiService();
  final AuthController _authController = Get.find<AuthController>();

  // Hizmet listeleri
  final RxList<Service> services = <Service>[].obs;
  final RxList<Service> activeServices = <Service>[].obs;

  // Seçilen hizmet
  final Rx<Service?> selectedService = Rx<Service?>(null);

  // Yükleniyor durumu
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Kullanıcı giriş yapmışsa hizmetleri yükle
    if (_authController.isLoggedIn && _authController.salonId != null) {
      loadServices();
    }
  }

  // Tüm hizmetleri yükle
  Future<void> loadServices() async {
    if (_authController.salonId == null) {
      return;
    }

    isLoading.value = true;

    try {
      final Map<String, dynamic> params = {'salon_id': _authController.salonId};

      final response = await _apiService.getServices(params);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];

        // Hizmetleri modele dönüştür
        final List<Service> fetchedServices =
            data.map((item) => Service.fromJson(item)).toList();

        // Ana listeyi güncelle
        services.value = fetchedServices;

        // Aktif hizmetleri filtrele
        activeServices.value = services.where((s) => s.isActive).toList();
      }
    } catch (e) {
      debugPrint('Error loading services: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Belirli bir hizmeti yükle
  Future<bool> loadService(String serviceId) async {
    isLoading.value = true;

    try {
      final response = await _apiService.getService(serviceId);

      if (response['success'] == true) {
        final serviceData = response['data'];
        selectedService.value = Service.fromJson(serviceData);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error loading service: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Yeni hizmet oluştur (salon sahibi için)
  Future<bool> createService(Map<String, dynamic> data) async {
    if (!_authController.isSalonOwner || _authController.salonId == null) {
      return false;
    }

    isCreating.value = true;

    try {
      // Salon ID'sini ekle
      data['salon_id'] = _authController.salonId;

      final response = await _apiService.createService(data);

      if (response['success'] == true) {
        await loadServices();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error creating service: $e');
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  // Hizmet güncelle
  Future<bool> updateService(
    String serviceId,
    Map<String, dynamic> data,
  ) async {
    if (!_authController.isSalonOwner) {
      return false;
    }

    isUpdating.value = true;

    try {
      final response = await _apiService.updateService(serviceId, data);

      if (response['success'] == true) {
        await loadServices();

        // Seçili hizmet güncellendiyse
        if (selectedService.value?.id == serviceId) {
          await loadService(serviceId);
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating service: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // Hizmet sil veya deaktif et
  Future<bool> deleteService(String serviceId) async {
    if (!_authController.isSalonOwner) {
      return false;
    }

    isUpdating.value = true;

    try {
      final response = await _apiService.deleteService(serviceId);

      if (response['success'] == true) {
        // Seçili hizmet silindiyse
        if (selectedService.value?.id == serviceId) {
          selectedService.value = null;
        }

        await loadServices();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error deleting service: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}
