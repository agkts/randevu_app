import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:randevu_app/views/salon_owner/salon_owner_settings.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/hairdresser_controller.dart';
import '../../controllers/salon_controller.dart';
import '../../controllers/service_controller.dart';
import '../../models/appointment.dart';
import '../../routes/app_routes.dart';
import '../../utils/responsive_size.dart';
import '../../views/common/custom_app_bar.dart';
import '../../views/common/custom_button.dart';

class SalonOwnerDashboardScreen extends StatefulWidget {
  const SalonOwnerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SalonOwnerDashboardScreen> createState() =>
      _SalonOwnerDashboardScreenState();
}

class _SalonOwnerDashboardScreenState extends State<SalonOwnerDashboardScreen> {
  // Controller'lar
  final AuthController _authController = Get.find<AuthController>();
  final SalonController _salonController = Get.find<SalonController>();
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();
  final HairdresserController _hairdresserController =
      Get.find<HairdresserController>();
  final ServiceController _serviceController = Get.find<ServiceController>();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Başlangıç verilerini yükle
  Future<void> _loadInitialData() async {
    await _salonController.loadSalon();
    await _hairdresserController.loadHairdressers();
    await _serviceController.loadServices();
    await _appointmentController.loadAppointments();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Salon Paneli',
        showBackButton: false,

        //!!!!!! burası ai ile kontrol edilecek
        actions: [
          IconButton(
            onPressed: () {
              Get.toNamed(AppRoutes.salonOwnerSettings);
            },
            icon: Icon(Icons.settings),
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
                // Hoşgeldin mesajı ve salon bilgisi
                Obx(() {
                  final salon = _salonController.salon.value;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Salon logosu
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                salon?.name.isNotEmpty == true
                                    ? salon!.name[0].toUpperCase()
                                    : 'S',
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
                                  salon?.name ?? 'Salon Sahibi',
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

                // İstatistik kartları
                _buildStatisticsCards(),
                const SizedBox(height: 24),

                // Hızlı Erişim Kartları
                Text('Hızlı Erişim', style: AppTextStyles.heading3),
                const SizedBox(height: 16),

                _buildQuickAccessCards(),
                const SizedBox(height: 24),

                // Bugünkü Randevular
                Text('Bugünkü Randevular', style: AppTextStyles.heading3),
                const SizedBox(height: 16),

                _buildTodayAppointments(),
                const SizedBox(height: 24),

                // Kuaför Listesi
                Text('Kuaförler', style: AppTextStyles.heading3),
                const SizedBox(height: 16),

                _buildHairdressers(),
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
                Obx(() {
                  final salon = _salonController.salon.value;
                  return Text(
                    salon?.name ?? 'Salon Paneli',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  );
                }),
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
            leading: const Icon(Icons.people),
            title: const Text('Kuaförler'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.salonOwnerHairdressers);
            },
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Hizmetler'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.salonOwnerServices);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Randevular'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.salonOwnerAppointments);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Raporlar'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.salonOwnerReports);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.salonOwnerSettings);
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

  // İstatistik kartları
  Widget _buildStatisticsCards() {
    return Obx(() {
      // Bugünün randevuları
      final todayAppointments =
          _appointmentController.appointments
              .where((a) => isSameDay(a.dateTime, DateTime.now()))
              .toList();

      // Toplam randevu sayısı
      final totalAppointments = _appointmentController.appointments.length;

      // Aktif kuaför sayısı
      final activeHairdressers =
          _hairdresserController.activeHairdressers.length;

      // Toplam hizmet sayısı
      final totalServices = _serviceController.services.length;

      return Column(
        children: [
          Row(
            children: [
              // Bugünkü randevu sayısı
              Expanded(
                child: _buildStatCard(
                  'Bugünkü Randevular',
                  '${todayAppointments.length}',
                  Icons.today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),

              // Toplam randevu sayısı
              Expanded(
                child: _buildStatCard(
                  'Toplam Randevu',
                  '$totalAppointments',
                  Icons.calendar_month,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Aktif kuaför sayısı
              Expanded(
                child: _buildStatCard(
                  'Aktif Kuaför',
                  '$activeHairdressers',
                  Icons.people,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),

              // Toplam hizmet sayısı
              Expanded(
                child: _buildStatCard(
                  'Hizmetler',
                  '$totalServices',
                  Icons.list_alt,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  // İstatistik kartı
  Widget _buildStatCard(
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

  // Hızlı erişim kartları
  Widget _buildQuickAccessCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Kuaför ekle
        _buildQuickAccessCard(
          'Kuaför Ekle',
          Icons.person_add,
          Colors.purple,
          () {
            Get.toNamed(AppRoutes.salonOwnerHairdressers);
          },
        ),

        // Hizmet ekle
        _buildQuickAccessCard(
          'Hizmet Ekle',
          Icons.add_circle_outline,
          Colors.orange,
          () {
            Get.toNamed(AppRoutes.salonOwnerServices);
          },
        ),

        // Randevuları görüntüle
        _buildQuickAccessCard(
          'Randevular',
          Icons.calendar_today,
          Colors.blue,
          () {
            Get.toNamed(AppRoutes.salonOwnerAppointments);
          },
        ),

        // Raporlar
        _buildQuickAccessCard('Raporlar', Icons.bar_chart, Colors.green, () {
          Get.toNamed(AppRoutes.salonOwnerReports);
        }),
      ],
    );
  }

  // Hızlı erişim kartı
  Widget _buildQuickAccessCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bugünkü randevular
  Widget _buildTodayAppointments() {
    return Obx(() {
      if (_appointmentController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final todayAppointments =
          _appointmentController.appointments
              .where((a) => isSameDay(a.dateTime, DateTime.now()))
              .toList();

      // Saate göre sırala
      todayAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

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

      return Card(
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount:
              todayAppointments.length > 5 ? 5 : todayAppointments.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final appointment = todayAppointments[index];
            return _buildAppointmentListItem(appointment);
          },
        ),
      );
    });
  }

  // Randevu listesi öğesi
  Widget _buildAppointmentListItem(Appointment appointment) {
    final timeFormat = DateFormat('HH:mm', 'tr_TR');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getStatusColor(appointment.status).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            _getStatusIcon(appointment.status),
            color: _getStatusColor(appointment.status),
          ),
        ),
      ),
      title: Text(
        appointment.customerName,
        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'Kuaför: ${appointment.hairdresserName}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 2),
          if (appointment.serviceNames != null &&
              appointment.serviceNames!.isNotEmpty)
            Text(
              'Hizmet: ${appointment.servicesText}',
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeFormat.format(appointment.dateTime),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(appointment.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              appointment.statusText,
              style: AppTextStyles.bodySmall.copyWith(
                color: _getStatusColor(appointment.status),
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        // Randevu detayları
      },
    );
  }

  // Kuaförler listesi
  Widget _buildHairdressers() {
    return Obx(() {
      if (_hairdresserController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final hairdressers = _hairdresserController.hairdressers;

      if (hairdressers.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Henüz kuaför bulunmuyor',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }

      // Sadece ilk 3 kuaförü göster
      final displayHairdressers =
          hairdressers.length > 3 ? hairdressers.sublist(0, 3) : hairdressers;

      return Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayHairdressers.length,
            itemBuilder: (context, index) {
              final hairdresser = displayHairdressers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Kuaför avatarı
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            hairdresser.name.isNotEmpty
                                ? hairdresser.name[0].toUpperCase()
                                : 'K',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Kuaför bilgileri
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hairdresser.name,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (hairdresser.phone != null)
                              Text(
                                hairdresser.phone!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Durum
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              hairdresser.isActive
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          hairdresser.isActive ? 'Aktif' : 'Pasif',
                          style: AppTextStyles.bodySmall.copyWith(
                            color:
                                hairdresser.isActive
                                    ? AppColors.success
                                    : AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Tümünü gör butonu
          if (hairdressers.length > 3)
            TextButton(
              onPressed: () {
                Get.toNamed(AppRoutes.salonOwnerHairdressers);
              },
              child: const Text('Tüm Kuaförleri Gör'),
            ),
        ],
      );
    });
  }

  // Durum rengi
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

  // Durum ikonu
  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.access_time;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.rejected:
        return Icons.cancel;
    }
  }

  // Aynı gün kontrolü
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
