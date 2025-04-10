import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/hairdresser_controller.dart';
import '../../models/appointment.dart';
import '../../routes/app_routes.dart';
import '../../utils/responsive_size.dart';
import '../../views/common/custom_app_bar.dart';
// import '../../views/common/custom_button.dart'; unused

class HairdresserDashboardScreen extends StatefulWidget {
  const HairdresserDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HairdresserDashboardScreen> createState() =>
      _HairdresserDashboardScreenState();
}

class _HairdresserDashboardScreenState
    extends State<HairdresserDashboardScreen> {
  // Controller'lar
  final AuthController _authController = Get.find<AuthController>();
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();
  final HairdresserController _hairdresserController =
      Get.find<HairdresserController>();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Başlangıç verilerini yükle
  Future<void> _loadInitialData() async {
    await _appointmentController.loadAppointments();
    await _hairdresserController.loadCurrentHairdresser();
  }

  // Çıkış yapma
  Future<void> _logout() async {
    final bool confirm =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Çıkış'),
            content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Çıkış Yap'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await _authController.logout();
      Get.offAllNamed(AppRoutes.login);
    }
  }

  // Randevu onaylama
  Future<void> _confirmAppointment(Appointment appointment) async {
    final bool success = await _appointmentController.updateAppointmentStatus(
      appointment.id!,
      AppointmentStatus.confirmed,
    );

    if (success) {
      Get.snackbar(
        'Başarılı',
        'Randevu onaylandı',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.8),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Hata',
        'Randevu onaylanırken bir hata oluştu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // Randevu reddetme
  Future<void> _rejectAppointment(Appointment appointment) async {
    final bool confirm =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Randevu Reddi'),
            content: const Text(
              'Bu randevuyu reddetmek istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Reddet'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      final bool success = await _appointmentController.updateAppointmentStatus(
        appointment.id!,
        AppointmentStatus.rejected,
      );

      if (success) {
        Get.snackbar(
          'Başarılı',
          'Randevu reddedildi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Hata',
          'Randevu reddedilirken bir hata oluştu',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  // Randevu tamamlama
  Future<void> _completeAppointment(Appointment appointment) async {
    final bool success = await _appointmentController.updateAppointmentStatus(
      appointment.id!,
      AppointmentStatus.completed,
    );

    if (success) {
      Get.snackbar(
        'Başarılı',
        'Randevu tamamlandı',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.8),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Hata',
        'Randevu tamamlanırken bir hata oluştu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Kuaför Paneli',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Get.toNamed(AppRoutes.hairdresserSettings);
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: Responsive.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hoşgeldin mesajı
                Obx(() {
                  final hairdresser =
                      _hairdresserController.currentHairdresser.value;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Kullanıcı avatarı
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                hairdresser?.name.isNotEmpty == true
                                    ? hairdresser!.name[0].toUpperCase()
                                    : 'K',
                                style: AppTextStyles.heading2.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hoş Geldin,',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  hairdresser?.name ?? 'Kuaför',
                                  style: AppTextStyles.heading3,
                                ),
                              ],
                            ),
                          ),

                          // Bugünün tarihi
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat(
                                  'dd MMMM yyyy',
                                  'tr_TR',
                                ).format(DateTime.now()),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'EEEE',
                                  'tr_TR',
                                ).format(DateTime.now()),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Özet kartları
                _buildSummaryCards(),
                const SizedBox(height: 24),

                // Bekleyen randevular
                Text('Onay Bekleyen Randevular', style: AppTextStyles.heading3),
                const SizedBox(height: 16),

                _buildPendingAppointments(),
                const SizedBox(height: 24),

                // Bugünün randevuları
                Text('Bugünkü Randevular', style: AppTextStyles.heading3),
                const SizedBox(height: 16),

                _buildTodayAppointments(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Yan menü
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Başlık
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Randevu App',
                  style: AppTextStyles.heading3.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kuaför Paneli',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Menü öğeleri
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Ana Sayfa'),
            selected: true,
            onTap: () {
              Get.back();
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Randevularım'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.hairdresserAppointments);
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Çalışma Saatlerim'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.hairdresserSchedule);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Müşterilerim'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.hairdresserCustomers);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.hairdresserSettings);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Çıkış Yap'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  // Özet kartları
  Widget _buildSummaryCards() {
    return Obx(() {
      final todayAppointments =
          _appointmentController.confirmedAppointments
              .where((a) => isSameDay(a.dateTime, DateTime.now()))
              .toList();

      final pendingAppointments = _appointmentController.pendingAppointments;

      return Row(
        children: [
          // Bugün kalan randevu sayısı
          Expanded(
            child: _buildSummaryCard(
              'Bugünkü Randevular',
              '${todayAppointments.length}',
              Icons.today,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),

          // Bekleyen randevu sayısı
          Expanded(
            child: _buildSummaryCard(
              'Bekleyen Randevular',
              '${pendingAppointments.length}',
              Icons.pending_actions,
              Colors.orange,
            ),
          ),
        ],
      );
    });
  }

  // Özet kartı
  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: AppTextStyles.heading2.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  // Bekleyen randevular
  Widget _buildPendingAppointments() {
    return Obx(() {
      if (_appointmentController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final pendingAppointments = _appointmentController.pendingAppointments;

      if (pendingAppointments.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Bekleyen randevu bulunmuyor',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: pendingAppointments.length,
        itemBuilder: (context, index) {
          final appointment = pendingAppointments[index];
          return _buildAppointmentCard(appointment, showConfirmReject: true);
        },
      );
    });
  }

  // Bugünkü randevular
  Widget _buildTodayAppointments() {
    return Obx(() {
      if (_appointmentController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final todayAppointments =
          _appointmentController.confirmedAppointments
              .where((a) => isSameDay(a.dateTime, DateTime.now()))
              .toList();

      if (todayAppointments.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Bugün için randevu bulunmuyor',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: todayAppointments.length,
        itemBuilder: (context, index) {
          final appointment = todayAppointments[index];
          return _buildAppointmentCard(appointment, showComplete: true);
        },
      );
    });
  }

  // Randevu kartı
  Widget _buildAppointmentCard(
    Appointment appointment, {
    bool showConfirmReject = false,
    bool showComplete = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(appointment.status).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zaman ve durum satırı
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${appointment.formattedDate}, ${appointment.formattedTime}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    appointment.statusText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _getStatusColor(appointment.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),

            // Müşteri bilgileri
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Müşteri avatarı
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      appointment.customerName.isNotEmpty
                          ? appointment.customerName[0].toUpperCase()
                          : 'M',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Müşteri detayları
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.customerName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appointment.customerPhone,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (appointment.customerNote != null &&
                          appointment.customerNote!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.note,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Not: ${appointment.customerNote}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Hizmetler
            if (appointment.serviceNames != null &&
                appointment.serviceNames!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.list, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hizmetler: ${appointment.servicesText}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Butonlar (Durumlara göre)
            if (showConfirmReject || showComplete) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (showConfirmReject) ...[
                    // Reddet butonu
                    TextButton.icon(
                      onPressed: () => _rejectAppointment(appointment),
                      icon: const Icon(Icons.close, color: AppColors.error),
                      label: const Text(
                        'Reddet',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Onayla butonu
                    ElevatedButton.icon(
                      onPressed: () => _confirmAppointment(appointment),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Onayla'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ],

                  if (showComplete &&
                      appointment.status == AppointmentStatus.confirmed) ...[
                    // Tamamla butonu
                    ElevatedButton.icon(
                      onPressed: () => _completeAppointment(appointment),
                      icon: const Icon(Icons.done_all, color: Colors.white),
                      label: const Text('Tamamla'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
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

  // Aynı gün kontrolü
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
