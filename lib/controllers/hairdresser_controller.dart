import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/hairdresser.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';

class HairdresserController extends GetxController {
  final ApiService _apiService = ApiService();
  final AuthController _authController = Get.find<AuthController>();

  // Kuaför listeleri
  final RxList<Hairdresser> hairdressers = <Hairdresser>[].obs;
  final RxList<Hairdresser> activeHairdressers = <Hairdresser>[].obs;

  // Aktif kuaför bilgisi (giriş yapan kuaför için)
  final Rx<Hairdresser?> currentHairdresser = Rx<Hairdresser?>(null);

  // Seçilen kuaför
  final Rx<Hairdresser?> selectedHairdresser = Rx<Hairdresser?>(null);

  // Yükleniyor durumu
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Kullanıcı giriş yapmışsa kuaförleri yükle
    if (_authController.isLoggedIn) {
      loadHairdressers();

      // Kuaför olarak giriş yapılmışsa kendi bilgilerini yükle
      if (_authController.isHairdresser) {
        loadCurrentHairdresser();
      }
    }
  }

  // Tüm kuaförleri yükle
  Future<void> loadHairdressers() async {
    isLoading.value = true;

    try {
      Map<String, dynamic> params = {};

      // Salon sahibi veya kuaför ise salon ID'sine göre filtrele
      if (_authController.salonId != null) {
        params['salon_id'] = _authController.salonId;
      }

      final response = await _apiService.getHairdressers(params);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];

        // Kuaförleri modele dönüştür
        final List<Hairdresser> fetchedHairdressers =
            data.map((item) => Hairdresser.fromJson(item)).toList();

        // Ana listeyi güncelle
        hairdressers.value = fetchedHairdressers;

        // Aktif kuaförleri filtrele
        activeHairdressers.value =
            hairdressers.where((h) => h.isActive).toList();
      }
    } catch (e) {
      debugPrint('Error loading hairdressers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Mevcut giriş yapan kuaför bilgilerini yükle
  Future<void> loadCurrentHairdresser() async {
    if (!_authController.isHairdresser || _authController.userId == null) {
      return;
    }

    isLoading.value = true;

    try {
      final response = await _apiService.getHairdresser(
        _authController.userId!,
      );

      if (response['success'] == true) {
        final hairdresserData = response['data'];
        currentHairdresser.value = Hairdresser.fromJson(hairdresserData);
      }
    } catch (e) {
      debugPrint('Error loading current hairdresser: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Belirli bir kuaförü yükle
  Future<bool> loadHairdresser(String hairdresserId) async {
    isLoading.value = true;

    try {
      final response = await _apiService.getHairdresser(hairdresserId);

      if (response['success'] == true) {
        final hairdresserData = response['data'];
        selectedHairdresser.value = Hairdresser.fromJson(hairdresserData);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error loading hairdresser: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Yeni kuaför oluştur (salon sahibi için)
  Future<bool> createHairdresser(Map<String, dynamic> data) async {
    isCreating.value = true;

    try {
      // Salon ID'sini ekle
      data['salon_id'] = _authController.salonId;

      // Varsayılan çalışma saatleri oluştur
      if (data['working_schedule'] == null) {
        data['working_schedule'] = Hairdresser.createDefaultSchedule();
      }

      final response = await _apiService.createHairdresser(data);

      if (response['success'] == true) {
        await loadHairdressers();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error creating hairdresser: $e');
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  // Kuaför güncelle
  Future<bool> updateHairdresser(
    String hairdresserId,
    Map<String, dynamic> data,
  ) async {
    isUpdating.value = true;

    try {
      final response = await _apiService.updateHairdresser(hairdresserId, data);

      if (response['success'] == true) {
        // Listeleri güncelle
        await loadHairdressers();

        // Eğer güncellenen kuaför mevcut kuaför ise, onu da güncelle
        if (_authController.isHairdresser &&
            _authController.userId == hairdresserId) {
          await loadCurrentHairdresser();
        }

        // Seçili kuaför güncellendiyse
        if (selectedHairdresser.value?.id == hairdresserId) {
          await loadHairdresser(hairdresserId);
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating hairdresser: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // Kuaförün çalışma saatlerini güncelle
  Future<bool> updateWorkingHours(
    String hairdresserId,
    Map<String, WorkingHours> workingSchedule,
  ) async {
    isUpdating.value = true;

    try {
      final Map<String, dynamic> data = {'working_schedule': workingSchedule};

      final response = await _apiService.updateHairdresser(hairdresserId, data);

      if (response['success'] == true) {
        // Güncellenen kuaföre göre listeleri yenile
        if (_authController.isHairdresser &&
            _authController.userId == hairdresserId) {
          await loadCurrentHairdresser();
        } else if (selectedHairdresser.value?.id == hairdresserId) {
          await loadHairdresser(hairdresserId);
        } else {
          await loadHairdressers();
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating working hours: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // Kuaförün tatil günlerini güncelle
  Future<bool> updateHolidayDates(
    String hairdresserId,
    List<DateTime> holidayDates,
  ) async {
    isUpdating.value = true;

    try {
      final Map<String, dynamic> data = {
        'holiday_dates':
            holidayDates.map((date) => date.toIso8601String()).toList(),
      };

      final response = await _apiService.updateHairdresser(hairdresserId, data);

      if (response['success'] == true) {
        // Güncellenen kuaföre göre listeleri yenile
        if (_authController.isHairdresser &&
            _authController.userId == hairdresserId) {
          await loadCurrentHairdresser();
        } else if (selectedHairdresser.value?.id == hairdresserId) {
          await loadHairdresser(hairdresserId);
        } else {
          await loadHairdressers();
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating holiday dates: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // Kuaföre hizmet ata veya kaldır
  Future<bool> updateHairdresserServices(
    String hairdresserId,
    List<String> serviceIds,
  ) async {
    isUpdating.value = true;

    try {
      final Map<String, dynamic> data = {'service_ids': serviceIds};

      final response = await _apiService.updateHairdresser(hairdresserId, data);

      if (response['success'] == true) {
        // Güncellenen kuaföre göre listeleri yenile
        if (_authController.isHairdresser &&
            _authController.userId == hairdresserId) {
          await loadCurrentHairdresser();
        } else if (selectedHairdresser.value?.id == hairdresserId) {
          await loadHairdresser(hairdresserId);
        } else {
          await loadHairdressers();
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating hairdresser services: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // Kuaför sil (salon sahibi için)
  Future<bool> deleteHairdresser(String hairdresserId) async {
    isUpdating.value = true;

    try {
      final response = await _apiService.deleteHairdresser(hairdresserId);

      if (response['success'] == true) {
        // Seçili kuaför silindiyse
        if (selectedHairdresser.value?.id == hairdresserId) {
          selectedHairdresser.value = null;
        }

        await loadHairdressers();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error deleting hairdresser: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}
