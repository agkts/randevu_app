import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../utils/responsive_size.dart';
import '../common/custom_app_bar.dart';
import '../../views/common/custom_button.dart';

class CustomerAppointmentConfirmationScreen extends StatelessWidget {
  const CustomerAppointmentConfirmationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Argümanları getir
    final Map<String, dynamic> appointmentData = Get.arguments ?? {};

    // Randevu verileri
    final String appointmentCode =
        appointmentData['appointment_code'] ?? '------';
    final String customerName = appointmentData['customer_name'] ?? 'Müşteri';
    final String hairdresserName =
        appointmentData['hairdresser_name'] ?? 'Kuaför';
    final String dateTimeStr =
        appointmentData['date_time'] ?? DateTime.now().toIso8601String();
    final DateTime dateTime = DateTime.parse(dateTimeStr);
    final List<String> serviceNames =
        appointmentData['service_names'] != null
            ? List<String>.from(appointmentData['service_names'])
            : [];

    // Formatlar
    final DateFormat dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');
    final DateFormat timeFormat = DateFormat('HH:mm', 'tr_TR');

    return Scaffold(
      appBar: const CustomAppBar(title: 'Randevu Onayı', showBackButton: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Başarı ikonu
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),

              // Başlık
              Text(
                'Randevunuz Alındı!',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Randevunuz başarıyla oluşturuldu. Lütfen randevu saatinden önce salonda olunuz.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Randevu kodu
              Column(
                children: [
                  Text(
                    'Randevu Kodunuz',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildAppointmentCode(appointmentCode),
                ],
              ),
              const SizedBox(height: 32),

              // Randevu detayları
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Randevu Detayları', style: AppTextStyles.heading4),
                      const SizedBox(height: 16),

                      // Müşteri adı
                      _buildInfoRow('Müşteri', customerName, Icons.person),
                      const Divider(),

                      // Kuaför
                      _buildInfoRow(
                        'Kuaför',
                        hairdresserName,
                        Icons.person_outline,
                      ),
                      const Divider(),

                      // Tarih
                      _buildInfoRow(
                        'Tarih',
                        dateFormat.format(dateTime),
                        Icons.calendar_today,
                      ),
                      const Divider(),

                      // Saat
                      _buildInfoRow(
                        'Saat',
                        timeFormat.format(dateTime),
                        Icons.access_time,
                      ),
                      const Divider(),

                      // Hizmetler
                      _buildInfoRow(
                        'Hizmetler',
                        serviceNames.isNotEmpty ? serviceNames.join(', ') : '-',
                        Icons.list,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Bilgilendirme notu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Randevunuzu iptal etmek veya değiştirmek için randevu kodunuzu saklayınız. '
                        'Kodu girerek randevunuzu yönetebilirsiniz.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Randevu Yönetimi',
                      type: ButtonType.outlined,
                      icon: Icons.settings,
                      onPressed: () {
                        Get.offAllNamed(AppRoutes.customerAppointmentManage);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Bitir',
                      type: ButtonType.primary,
                      icon: Icons.check,
                      onPressed: () {
                        Get.offAllNamed(AppRoutes.customerAppointmentBooking);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Randevu kodu widget'ı
  Widget _buildAppointmentCode(String code) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code)).then((value) {
          Get.snackbar(
            'Kopyalandı',
            'Randevu kodu panoya kopyalandı',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success.withOpacity(0.8),
            colorText: Colors.white,
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.copy, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  // Bilgi satırı
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
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
}
