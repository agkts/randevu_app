import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/hairdresser.dart';
import '../models/service.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';

class AppointmentController extends GetxController {
  final ApiService _apiService = ApiService();
  final AuthController _authController = Get.find<AuthController>();

  // Randevu listeleri
  final RxList<Appointment> appointments = <Appointment>[].obs;
  final RxList<Appointment> pendingAppointments = <Appointment>[].obs;
  final RxList<Appointment> confirmedAppointments = <Appointment>[].obs;
  final RxList<Appointment> completedAppointments = <Appointment>[].obs;
  final RxList<Appointment> cancelledAppointments = <Appointment>[].obs;

  // Seçilen randevu
  final Rx<Appointment?> selectedAppointment = Rx<Appointment?>(null);

  // Randevu oluşturma verileri
  final RxString customerName = ''.obs;
  final RxString customerPhone = ''.obs;
  final RxString customerEmail = ''.obs;
  final RxString customerNote = ''.obs;
  final Rx<Hairdresser?> selectedHairdresser = Rx<Hairdresser?>(null);
  final RxList<Service> selectedServices = <Service>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rx<DateTime?> selectedTime = Rx<DateTime?>(null);

  // Yükleniyor durumu
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Kullanıcı giriş yapmışsa ve rolüne göre randevuları yükle
    if (_authController.isLoggedIn) {
      loadAppointments();
    }
  }

  // Tüm randevuları yükle
  Future<void> loadAppointments() async {
    isLoading.value = true;

    try {
      Map<String, dynamic> params = {};

      // Kuaför ise sadece kendi randevularını görsün
      if (_authController.isHairdresser) {
        params['hairdresser_id'] = _authController.userId;
      }

      // Salon sahibi ise salonun tüm randevularını görsün
      if (_authController.isSalonOwner) {
        params['salon_id'] = _authController.salonId;
      }

      final response = await _apiService.getAppointments(params);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];

        // Randevuları modele dönüştür
        final List<Appointment> fetchedAppointments =
            data.map((item) => Appointment.fromJson(item)).toList();

        // Ana listeyi güncelle
        appointments.value = fetchedAppointments;

        // Durumlara göre listeleri filtrele
        _filterAppointmentsByStatus();
      }
    } catch (e) {
      debugPrint('Error loading appointments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Randevuları durumlarına göre filtrele
  void _filterAppointmentsByStatus() {
    pendingAppointments.value =
        appointments
            .where(
              (appointment) => appointment.status == AppointmentStatus.pending,
            )
            .toList();

    confirmedAppointments.value =
        appointments
            .where(
              (appointment) =>
                  appointment.status == AppointmentStatus.confirmed,
            )
            .toList();

    completedAppointments.value =
        appointments
            .where(
              (appointment) =>
                  appointment.status == AppointmentStatus.completed,
            )
            .toList();

    cancelledAppointments.value =
        appointments
            .where(
              (appointment) =>
                  appointment.status == AppointmentStatus.cancelled ||
                  appointment.status == AppointmentStatus.rejected,
            )
            .toList();
  }

  // Belirli bir randevuyu yükle (kod ile)
  Future<bool> loadAppointmentByCode(String code) async {
    isLoading.value = true;

    try {
      final response = await _apiService.getAppointmentByCode(code);

      if (response['success'] == true) {
        final appointmentData = response['data'];
        final appointment = Appointment.fromJson(appointmentData);

        selectedAppointment.value = appointment;
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error loading appointment by code: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Yeni randevu oluştur (müşteri için)
  Future<Map<String, dynamic>> createAppointment() async {
    isCreating.value = true;

    try {
      // Servis ID'lerini liste olarak al
      final List<String> serviceIds =
          selectedServices.map((service) => service.id).toList();

      // Seçili tarih ve saati birleştir
      final DateTime appointmentDateTime = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
        selectedTime.value?.hour ?? 0,
        selectedTime.value?.minute ?? 0,
      );

      // Randevu için veriyi hazırla
      final Map<String, dynamic> appointmentData = {
        'customer_name': customerName.value,
        'customer_phone': customerPhone.value,
        'customer_email': customerEmail.value,
        'customer_note': customerNote.value,
        'hairdresser_id': selectedHairdresser.value?.id,
        'service_ids': serviceIds,
        'date_time': appointmentDateTime.toIso8601String(),
        'salon_id': _authController.salonId,
      };

      final response = await _apiService.createAppointment(appointmentData);

      if (response['success'] == true) {
        // Randevu başarıyla oluşturuldu, form verilerini sıfırla
        resetFormData();

        // Kullanıcı giriş yapmış ise randevuları yeniden yükle
        if (_authController.isLoggedIn) {
          await loadAppointments();
        }

        return {'success': true, 'data': response['data']};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Randevu oluşturulamadı',
      };
    } catch (e) {
      debugPrint('Error creating appointment: $e');
      return {
        'success': false,
        'message': 'Randevu oluşturulurken bir hata oluştu',
      };
    } finally {
      isCreating.value = false;
    }
  }

  // Randevu güncelle
  Future<bool> updateAppointment(
    String appointmentId,
    Map<String, dynamic> data,
  ) async {
    isUpdating.value = true;

    try {
      final response = await _apiService.updateAppointment(appointmentId, data);

      if (response['success'] == true) {
        await loadAppointments();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating appointment: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // Randevu durumunu güncelle
  Future<bool> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  ) async {
    isUpdating.value = true;

    try {
      final Map<String, dynamic> data = {'status': _getStatusString(status)};

      final response = await _apiService.updateAppointment(appointmentId, data);

      if (response['success'] == true) {
        await loadAppointments();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // Randevu sil
  Future<bool> deleteAppointment(String appointmentId) async {
    isUpdating.value = true;

    try {
      final response = await _apiService.deleteAppointment(appointmentId);

      if (response['success'] == true) {
        await loadAppointments();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error deleting appointment: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // Randevu durumunu string olarak al
  String _getStatusString(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'pending';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.rejected:
        return 'rejected';
    }
  }

  // Form verilerini sıfırla
  void resetFormData() {
    customerName.value = '';
    customerPhone.value = '';
    customerEmail.value = '';
    customerNote.value = '';
    selectedHairdresser.value = null;
    selectedServices.clear();
    selectedDate.value = DateTime.now();
    selectedTime.value = null;
  }
}
