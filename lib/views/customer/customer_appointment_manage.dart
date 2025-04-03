import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/appointment_controller.dart';
import '../../models/appointment.dart';
import '../../routes/app_routes.dart';
import '../../utils/responsive_size.dart';
import '../common/custom_app_bar.dart';
import '../../views/common/custom_button.dart';
import '../../views/common/custom_text_field.dart';

class CustomerAppointmentManageScreen extends StatefulWidget {
  const CustomerAppointmentManageScreen({Key? key}) : super(key: key);

  @override
  State<CustomerAppointmentManageScreen> createState() =>
      _CustomerAppointmentManageScreenState();
}

class _CustomerAppointmentManageScreenState
    extends State<CustomerAppointmentManageScreen> {
  // Controller'lar
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();

  // Text controller
  final TextEditingController _codeController = TextEditingController();

  // Form anahtarı
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Durum değişkenleri
  final RxBool isCodeSubmitted = false.obs;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Randevu kodu ile sorgulama
  Future<void> _queryAppointment() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();

      final String code = _codeController.text.trim();
      final bool success = await _appointmentController.loadAppointmentByCode(
        code,
      );

      if (success) {
        isCodeSubmitted.value = true;
      } else {
        Get.snackbar(
          'Hata',
          'Randevu bulunamadı. Lütfen kodu kontrol edin.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  // Randevu iptal etme
  Future<void> _cancelAppointment() async {
    if (_appointmentController.selectedAppointment.value == null) {
      return;
    }

    final appointment = _appointmentController.selectedAppointment.value!;

    // Onay isteği
    final bool confirm =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Randevu İptali'),
            content: const Text(
              'Randevunuzu iptal etmek istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('İptal Et'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      final bool success = await _appointmentController.updateAppointmentStatus(
        appointment.id!,
        AppointmentStatus.cancelled,
      );

      if (success) {
        Get.snackbar(
          'Başarılı',
          'Randevunuz iptal edildi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.8),
          colorText: Colors.white,
        );

        // Ana ekrana yönlendir
        Get.offAllNamed(AppRoutes.customerAppointmentBooking);
      } else {
        Get.snackbar(
          'Hata',
          'Randevu iptal edilirken bir hata oluştu',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Randevu Yönetimi'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding,
          child: Obx(() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kod girişi (randevu sorgulanmadan önce)
                if (!isCodeSubmitted.value) _buildCodeInputSection(),

                // Randevu detayları (sorgulandıktan sonra)
                if (isCodeSubmitted.value &&
                    _appointmentController.selectedAppointment.value != null)
                  _buildAppointmentDetailsSection(),
              ],
            );
          }),
        ),
      ),
    );
  }

  // Randevu kodu giriş bölümü
  Widget _buildCodeInputSection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Randevu Sorgulama', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            'Randevunuzu görüntülemek, değiştirmek veya iptal etmek için randevu kodunuzu girin.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Kod alanı
          CustomTextField(
            label: 'Randevu Kodu',
            hint: 'Size verilen randevu kodunu girin',
            controller: _codeController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen randevu kodunu girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Sorgula butonu
          CustomButton(
            text: 'Randevuyu Sorgula',
            type: ButtonType.primary,
            onPressed: _queryAppointment,
            isLoading: _appointmentController.isLoading.value,
          ),

          const SizedBox(height: 32),

          // Yeni randevu al
          Center(
            child: TextButton(
              onPressed: () {
                Get.offAllNamed(AppRoutes.customerAppointmentBooking);
              },
              child: Text('Yeni Randevu Al', style: AppTextStyles.link),
            ),
          ),
        ],
      ),
    );
  }

  // Randevu detayları bölümü
  Widget _buildAppointmentDetailsSection() {
    final appointment = _appointmentController.selectedAppointment.value!;
    final DateFormat dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');
    final DateFormat timeFormat = DateFormat('HH:mm', 'tr_TR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Randevu Detayları', style: AppTextStyles.heading3),
        const SizedBox(height: 16),

        // Durum
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getStatusColor(appointment.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor(appointment.status),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Durum',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                appointment.statusText,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(appointment.status),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Temel bilgiler
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Randevu kodu
                _buildInfoRow('Randevu Kodu', appointment.appointmentCode),
                const Divider(),

                // Tarih ve saat
                _buildInfoRow('Tarih', dateFormat.format(appointment.dateTime)),
                const SizedBox(height: 8),
                _buildInfoRow('Saat', timeFormat.format(appointment.dateTime)),
                const Divider(),

                // Kuaför bilgisi
                _buildInfoRow('Kuaför', appointment.hairdresserName),
                const Divider(),

                // Hizmetler
                _buildInfoRow('Hizmetler', appointment.servicesText),

                // Not varsa göster
                if (appointment.customerNote != null &&
                    appointment.customerNote!.isNotEmpty) ...[
                  const Divider(),
                  _buildInfoRow('Not', appointment.customerNote!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // İşlem butonları
        // İptal edilmiş veya tamamlanmış randevular için butonları gösterme
        if (appointment.status != AppointmentStatus.cancelled &&
            appointment.status != AppointmentStatus.completed &&
            appointment.status != AppointmentStatus.rejected) ...[
          // İptal butonu
          CustomButton(
            text: 'Randevuyu İptal Et',
            type: ButtonType.outlined,
            icon: Icons.cancel_outlined,
            onPressed: _cancelAppointment,
            isLoading: _appointmentController.isUpdating.value,
          ),
        ],

        const SizedBox(height: 32),

        // Yeni randevu al
        Center(
          child: TextButton(
            onPressed: () {
              Get.offAllNamed(AppRoutes.customerAppointmentBooking);
            },
            child: Text('Yeni Randevu Al', style: AppTextStyles.link),
          ),
        ),
      ],
    );
  }

  // Bilgi satırı
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Durum rengini belirle
  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.confirmed:
        return AppColors.info;
      case AppointmentStatus.cancelled:
        return AppColors.error;
      case AppointmentStatus.completed:
        return AppColors.success;
      case AppointmentStatus.rejected:
        return AppColors.error;
    }
  }
}
