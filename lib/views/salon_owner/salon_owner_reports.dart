import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/hairdresser_controller.dart';
import '../../controllers/service_controller.dart';
import '../../models/appointment.dart';
import '../../models/hairdresser.dart';
import '../../utils/responsive_size.dart';
import '../common/custom_app_bar.dart';
import '../../views/common/custom_button.dart';

class SalonOwnerReportsScreen extends StatefulWidget {
  const SalonOwnerReportsScreen({Key? key}) : super(key: key);

  @override
  State<SalonOwnerReportsScreen> createState() =>
      _SalonOwnerReportsScreenState();
}

class _SalonOwnerReportsScreenState extends State<SalonOwnerReportsScreen>
    with SingleTickerProviderStateMixin {
  // Controller'lar
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();
  final HairdresserController _hairdresserController =
      Get.find<HairdresserController>();
  final ServiceController _serviceController = Get.find<ServiceController>();

  // Tab controller
  late TabController _tabController;

  // Tarih filtreleme
  final Rx<DateTime> _startDate =
      DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> _endDate = DateTime.now().obs;

  // Yükleniyor durumu
  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Veri yükleme
  Future<void> _loadData() async {
    _isLoading.value = true;
    try {
      await _appointmentController.loadAppointments();
      await _hairdresserController.loadHairdressers();
      await _serviceController.loadServices();
    } finally {
      _isLoading.value = false;
    }
  }

  // Tarih aralığındaki randevuları filtrele
  List<Appointment> _getFilteredAppointments() {
    return _appointmentController.appointments.where((appointment) {
      return appointment.dateTime.isAfter(_startDate.value) &&
          appointment.dateTime.isBefore(
            _endDate.value.add(const Duration(days: 1)),
          );
    }).toList();
  }

  // Gelirleri hesapla
  Map<String, dynamic> _calculateRevenue(List<Appointment> appointments) {
    double totalRevenue = 0;
    Map<String, double> revenueByHairdresser = {};
    Map<String, double> revenueByService = {};

    for (var appointment in appointments) {
      // Sadece tamamlanmış randevuları hesaba kat
      if (appointment.status == AppointmentStatus.completed) {
        // Toplam gelir
        if (appointment.totalPrice != null) {
          totalRevenue += appointment.totalPrice!;

          // Kuaföre göre gelir
          if (!revenueByHairdresser.containsKey(appointment.hairdresserId)) {
            revenueByHairdresser[appointment.hairdresserId] = 0;
          }
          revenueByHairdresser[appointment.hairdresserId] =
              revenueByHairdresser[appointment.hairdresserId]! +
              appointment.totalPrice!;

          // Hizmetlere göre gelir
          if (appointment.serviceIds != null) {
            for (var serviceId in appointment.serviceIds!) {
              if (!revenueByService.containsKey(serviceId)) {
                revenueByService[serviceId] = 0;
              }

              // Basit olması için, her hizmetin fiyatını eşit olarak dağıtıyoruz
              double servicePrice =
                  appointment.totalPrice! / appointment.serviceIds!.length;
              revenueByService[serviceId] =
                  revenueByService[serviceId]! + servicePrice;
            }
          }
        }
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'revenueByHairdresser': revenueByHairdresser,
      'revenueByService': revenueByService,
    };
  }

  // Randevu istatistiklerini hesapla
  Map<String, dynamic> _calculateAppointmentStats(
    List<Appointment> appointments,
  ) {
    int totalAppointments = appointments.length;
    int pendingCount = 0;
    int confirmedCount = 0;
    int completedCount = 0;
    int cancelledCount = 0;
    int rejectedCount = 0;

    Map<String, int> appointmentsByHairdresser = {};
    Map<int, int> appointmentsByHour = {};
    Map<int, int> appointmentsByDay = {};

    for (var appointment in appointments) {
      // Durum sayımları
      switch (appointment.status) {
        case AppointmentStatus.pending:
          pendingCount++;
          break;
        case AppointmentStatus.confirmed:
          confirmedCount++;
          break;
        case AppointmentStatus.completed:
          completedCount++;
          break;
        case AppointmentStatus.cancelled:
          cancelledCount++;
          break;
        case AppointmentStatus.rejected:
          rejectedCount++;
          break;
      }

      // Kuaföre göre randevu sayısı
      if (!appointmentsByHairdresser.containsKey(appointment.hairdresserId)) {
        appointmentsByHairdresser[appointment.hairdresserId] = 0;
      }
      appointmentsByHairdresser[appointment.hairdresserId] =
          appointmentsByHairdresser[appointment.hairdresserId]! + 1;

      // Saate göre randevu sayısı
      int hour = appointment.dateTime.hour;
      if (!appointmentsByHour.containsKey(hour)) {
        appointmentsByHour[hour] = 0;
      }
      appointmentsByHour[hour] = appointmentsByHour[hour]! + 1;

      // Güne göre randevu sayısı (1-7, Pazartesi-Pazar)
      int weekday = appointment.dateTime.weekday;
      if (!appointmentsByDay.containsKey(weekday)) {
        appointmentsByDay[weekday] = 0;
      }
      appointmentsByDay[weekday] = appointmentsByDay[weekday]! + 1;
    }

    return {
      'totalAppointments': totalAppointments,
      'pendingCount': pendingCount,
      'confirmedCount': confirmedCount,
      'completedCount': completedCount,
      'cancelledCount': cancelledCount,
      'rejectedCount': rejectedCount,
      'appointmentsByHairdresser': appointmentsByHairdresser,
      'appointmentsByHour': appointmentsByHour,
      'appointmentsByDay': appointmentsByDay,
    };
  }

  // Müşteri istatistiklerini hesapla
  Map<String, dynamic> _calculateCustomerStats(List<Appointment> appointments) {
    // Benzersiz müşteri listesi (telefon numarasına göre)
    Map<String, Map<String, dynamic>> customerData = {};

    for (var appointment in appointments) {
      final String customerKey = appointment.customerPhone;

      if (!customerData.containsKey(customerKey)) {
        customerData[customerKey] = {
          'name': appointment.customerName,
          'phone': appointment.customerPhone,
          'email': appointment.customerEmail,
          'appointmentCount': 0,
          'totalSpent': 0.0,
          'lastAppointment': appointment.dateTime,
        };
      }

      // Randevu sayısı
      customerData[customerKey]!['appointmentCount'] =
          customerData[customerKey]!['appointmentCount'] + 1;

      // Toplam harcama (tamamlanmış randevulardan)
      if (appointment.status == AppointmentStatus.completed &&
          appointment.totalPrice != null) {
        customerData[customerKey]!['totalSpent'] =
            customerData[customerKey]!['totalSpent'] + appointment.totalPrice!;
      }

      // Son randevu tarihi
      if (appointment.dateTime.isAfter(
        customerData[customerKey]!['lastAppointment'],
      )) {
        customerData[customerKey]!['lastAppointment'] = appointment.dateTime;
      }
    }

    // Toplam müşteri sayısı
    int totalCustomers = customerData.length;

    // Yeni müşteriler (son 30 gün)
    int newCustomers = 0;
    DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    // En çok harcama yapan müşteriler
    List<Map<String, dynamic>> topSpendingCustomers =
        customerData.values.toList();
    topSpendingCustomers.sort(
      (a, b) =>
          (b['totalSpent'] as double).compareTo(a['totalSpent'] as double),
    );

    // Randevu sıklıklarına göre müşteriler
    List<Map<String, dynamic>> frequentCustomers = customerData.values.toList();
    frequentCustomers.sort(
      (a, b) => (b['appointmentCount'] as int).compareTo(
        a['appointmentCount'] as int,
      ),
    );

    // Yeni müşteri sayısını hesapla
    for (var customer in customerData.values) {
      if ((customer['lastAppointment'] as DateTime).isAfter(thirtyDaysAgo)) {
        newCustomers++;
      }
    }

    return {
      'totalCustomers': totalCustomers,
      'newCustomers': newCustomers,
      'topSpendingCustomers': topSpendingCustomers.take(5).toList(),
      'frequentCustomers': frequentCustomers.take(5).toList(),
      'customerData': customerData,
    };
  }

  // Hizmet istatistiklerini hesapla
  Map<String, dynamic> _calculateServiceStats(List<Appointment> appointments) {
    Map<String, int> serviceUsageCount = {};

    for (var appointment in appointments) {
      if (appointment.serviceIds != null) {
        for (var serviceId in appointment.serviceIds!) {
          if (!serviceUsageCount.containsKey(serviceId)) {
            serviceUsageCount[serviceId] = 0;
          }
          serviceUsageCount[serviceId] = serviceUsageCount[serviceId]! + 1;
        }
      }
    }

    // En popüler hizmetler
    List<MapEntry<String, int>> popularServices =
        serviceUsageCount.entries.toList();
    popularServices.sort((a, b) => b.value.compareTo(a.value));

    return {
      'serviceUsageCount': serviceUsageCount,
      'popularServices': popularServices,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Raporlar'),
      body: SafeArea(
        child: Column(
          children: [
            // Tarih seçme
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildDateRangePicker(),
            ),

            // Tab bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTextStyles.bodySmall,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Gelir Raporu'),
                  Tab(text: 'Randevu Raporu'),
                  Tab(text: 'Müşteri Raporu'),
                  Tab(text: 'Hizmet Raporu'),
                ],
              ),
            ),

            // Tab içerikleri
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Gelir Raporu
                  _buildRevenueReport(),

                  // Randevu Raporu
                  _buildAppointmentReport(),

                  // Müşteri Raporu
                  _buildCustomerReport(),

                  // Hizmet Raporu
                  _buildServiceReport(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gelir raporu
  Widget _buildRevenueReport() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Appointment> filteredAppointments =
            _getFilteredAppointments();
        final Map<String, dynamic> revenueData = _calculateRevenue(
          filteredAppointments,
        );

        final double totalRevenue = revenueData['totalRevenue'];
        final Map<String, double> revenueByHairdresser =
            revenueData['revenueByHairdresser'];
        final Map<String, double> revenueByService =
            revenueData['revenueByService'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toplam gelir kartı
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toplam Gelir',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '₺${totalRevenue.toStringAsFixed(2)}',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Dönem: ${DateFormat('dd.MM.yyyy').format(_startDate.value)} - ${DateFormat('dd.MM.yyyy').format(_endDate.value)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Kuaförlere göre gelir
              Text('Kuaförlere Göre Gelir', style: AppTextStyles.heading4),
              const SizedBox(height: 16),

              if (revenueByHairdresser.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Bu tarih aralığında kayıt bulunamadı',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: revenueByHairdresser.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final String hairdresserId = revenueByHairdresser.keys
                          .elementAt(index);
                      final double revenue =
                          revenueByHairdresser[hairdresserId]!;

                      // Kuaför adını bul
                      String hairdresserName = 'Bilinmeyen Kuaför';
                      final hairdresser = _hairdresserController.hairdressers
                          .firstWhereOrNull((h) => h.id == hairdresserId);

                      if (hairdresser != null) {
                        hairdresserName = hairdresser.name;
                      }

                      // Yüzde hesapla
                      final double percentage =
                          totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0;

                      return ListTile(
                        title: Text(hairdresserName),
                        subtitle: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₺${revenue.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '%${percentage.toStringAsFixed(1)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),

              // Hizmetlere göre gelir
              Text('Hizmetlere Göre Gelir', style: AppTextStyles.heading4),
              const SizedBox(height: 16),

              if (revenueByService.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Bu tarih aralığında kayıt bulunamadı',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: revenueByService.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final String serviceId = revenueByService.keys.elementAt(
                        index,
                      );
                      final double revenue = revenueByService[serviceId]!;

                      // Hizmet adını bul
                      String serviceName = 'Bilinmeyen Hizmet';
                      final service = _serviceController.services
                          .firstWhereOrNull((s) => s.id == serviceId);

                      if (service != null) {
                        serviceName = service.name;
                      }

                      // Yüzde hesapla
                      final double percentage =
                          totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0;

                      return ListTile(
                        title: Text(serviceName),
                        subtitle: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₺${revenue.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '%${percentage.toStringAsFixed(1)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // Randevu raporu
  Widget _buildAppointmentReport() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Appointment> filteredAppointments =
            _getFilteredAppointments();
        final Map<String, dynamic> appointmentStats =
            _calculateAppointmentStats(filteredAppointments);

        final int totalAppointments = appointmentStats['totalAppointments'];
        final int pendingCount = appointmentStats['pendingCount'];
        final int confirmedCount = appointmentStats['confirmedCount'];
        final int completedCount = appointmentStats['completedCount'];
        final int cancelledCount = appointmentStats['cancelledCount'];
        final int rejectedCount = appointmentStats['rejectedCount'];

        final Map<String, int> appointmentsByHairdresser =
            appointmentStats['appointmentsByHairdresser'];
        final Map<int, int> appointmentsByHour =
            appointmentStats['appointmentsByHour'];
        final Map<int, int> appointmentsByDay =
            appointmentStats['appointmentsByDay'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toplam randevu kartı
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toplam Randevu',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$totalAppointments',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Dönem: ${DateFormat('dd.MM.yyyy').format(_startDate.value)} - ${DateFormat('dd.MM.yyyy').format(_endDate.value)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Durum dağılımı
              Text('Randevu Durumları', style: AppTextStyles.heading4),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Bekleyen randevular
                      _buildStatusProgressBar(
                        'Bekleyen',
                        pendingCount,
                        totalAppointments,
                        AppColors.warning,
                      ),
                      const SizedBox(height: 12),

                      // Onaylanan randevular
                      _buildStatusProgressBar(
                        'Onaylanan',
                        confirmedCount,
                        totalAppointments,
                        AppColors.info,
                      ),
                      const SizedBox(height: 12),

                      // Tamamlanan randevular
                      _buildStatusProgressBar(
                        'Tamamlanan',
                        completedCount,
                        totalAppointments,
                        AppColors.success,
                      ),
                      const SizedBox(height: 12),

                      // İptal edilen randevular
                      _buildStatusProgressBar(
                        'İptal Edilen',
                        cancelledCount,
                        totalAppointments,
                        AppColors.error,
                      ),
                      const SizedBox(height: 12),

                      // Reddedilen randevular
                      _buildStatusProgressBar(
                        'Reddedilen',
                        rejectedCount,
                        totalAppointments,
                        AppColors.error,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Kuaförlere göre randevu
              Text('Kuaförlere Göre Randevular', style: AppTextStyles.heading4),
              const SizedBox(height: 16),

              if (appointmentsByHairdresser.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Bu tarih aralığında kayıt bulunamadı',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: appointmentsByHairdresser.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final String hairdresserId = appointmentsByHairdresser
                          .keys
                          .elementAt(index);
                      final int count =
                          appointmentsByHairdresser[hairdresserId]!;

                      // Kuaför adını bul
                      String hairdresserName = 'Bilinmeyen Kuaför';
                      final hairdresser = _hairdresserController.hairdressers
                          .firstWhereOrNull((h) => h.id == hairdresserId);

                      if (hairdresser != null) {
                        hairdresserName = hairdresser.name;
                      }

                      // Yüzde hesapla
                      final double percentage =
                          totalAppointments > 0
                              ? (count / totalAppointments) * 100
                              : 0;

                      return ListTile(
                        title: Text(hairdresserName),
                        subtitle: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$count',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '%${percentage.toStringAsFixed(1)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),

              // Saatlere göre yoğunluk
              Text('Saatlere Göre Yoğunluk', style: AppTextStyles.heading4),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (int hour = 9; hour < 21; hour++)
                          _buildHourBar(
                            hour,
                            appointmentsByHour[hour] ?? 0,
                            totalAppointments,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Günlere göre yoğunluk
              Text('Günlere Göre Yoğunluk', style: AppTextStyles.heading4),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (int day = 1; day <= 7; day++) ...[
                        _buildDayBar(
                          day,
                          appointmentsByDay[day] ?? 0,
                          totalAppointments,
                        ),
                        if (day < 7) const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Müşteri raporu
  Widget _buildCustomerReport() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Appointment> filteredAppointments =
            _getFilteredAppointments();
        final Map<String, dynamic> customerStats = _calculateCustomerStats(
          filteredAppointments,
        );

        final int totalCustomers = customerStats['totalCustomers'];
        final int newCustomers = customerStats['newCustomers'];
        final List<Map<String, dynamic>> topSpendingCustomers =
            customerStats['topSpendingCustomers'];
        final List<Map<String, dynamic>> frequentCustomers =
            customerStats['frequentCustomers'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toplam müşteri ve yeni müşteri kartları
              Row(
                children: [
                  // Toplam müşteri
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toplam Müşteri',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$totalCustomers',
                                  style: AppTextStyles.heading2.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Yeni müşteri
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yeni Müşteri (Son 30 gün)',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$newCustomers',
                                  style: AppTextStyles.heading2.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // En çok harcama yapan müşteriler
              Text(
                'En Çok Harcama Yapan Müşteriler',
                style: AppTextStyles.heading4,
              ),
              const SizedBox(height: 16),

              if (topSpendingCustomers.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Bu tarih aralığında kayıt bulunamadı',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topSpendingCustomers.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final customerData = topSpendingCustomers[index];
                      final String name = customerData['name'];
                      final String phone = customerData['phone'];
                      final double totalSpent = customerData['totalSpent'];

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'M',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(name),
                        subtitle: Text(phone),
                        trailing: Text(
                          '₺${totalSpent.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),

              // En sık gelen müşteriler
              Text('En Sık Gelen Müşteriler', style: AppTextStyles.heading4),
              const SizedBox(height: 16),

              if (frequentCustomers.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Bu tarih aralığında kayıt bulunamadı',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: frequentCustomers.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final customerData = frequentCustomers[index];
                      final String name = customerData['name'];
                      final String phone = customerData['phone'];
                      final int appointmentCount =
                          customerData['appointmentCount'];
                      final DateTime lastAppointment =
                          customerData['lastAppointment'];

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'M',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(name),
                        subtitle: Text(
                          'Son randevu: ${DateFormat('dd.MM.yyyy').format(lastAppointment)}',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '$appointmentCount Randevu',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // Hizmet raporu
  Widget _buildServiceReport() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Appointment> filteredAppointments =
            _getFilteredAppointments();
        final Map<String, dynamic> serviceStats = _calculateServiceStats(
          filteredAppointments,
        );

        final Map<String, int> serviceUsageCount =
            serviceStats['serviceUsageCount'];
        final List<MapEntry<String, int>> popularServices =
            serviceStats['popularServices'];

        final int totalServiceUsage = popularServices.fold(
          0,
          (sum, entry) => sum + entry.value,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En popüler hizmetler
              Text('En Popüler Hizmetler', style: AppTextStyles.heading4),
              const SizedBox(height: 16),

              if (popularServices.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Bu tarih aralığında kayıt bulunamadı',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        popularServices.length > 10
                            ? 10
                            : popularServices.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final serviceId = popularServices[index].key;
                      final int count = popularServices[index].value;

                      // Hizmet adını bul
                      String serviceName = 'Bilinmeyen Hizmet';
                      final service = _serviceController.services
                          .firstWhereOrNull((s) => s.id == serviceId);

                      if (service != null) {
                        serviceName = service.name;
                      }

                      // Yüzde hesapla
                      final double percentage =
                          totalServiceUsage > 0
                              ? (count / totalServiceUsage) * 100
                              : 0;

                      return ListTile(
                        title: Text(serviceName),
                        subtitle: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$count',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '%${percentage.toStringAsFixed(1)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),

              // Hizmet dağılımı görselleştirme
              Text('Hizmet Dağılımı', style: AppTextStyles.heading4),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (popularServices.isEmpty)
                        Center(
                          child: Text(
                            'Bu tarih aralığında kayıt bulunamadı',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        // Pasta grafik yerine renkli kutular ile basit görselleştirme
                        Wrap(
                          spacing: 8,
                          runSpacing: 16,
                          children: List.generate(
                            popularServices.length > 5
                                ? 5
                                : popularServices.length,
                            (index) {
                              final serviceId = popularServices[index].key;
                              final int count = popularServices[index].value;

                              // Hizmet adını bul
                              String serviceName = 'Bilinmeyen Hizmet';
                              final service = _serviceController.services
                                  .firstWhereOrNull((s) => s.id == serviceId);

                              if (service != null) {
                                serviceName = service.name;
                              }

                              // Yüzde hesapla
                              final double percentage =
                                  totalServiceUsage > 0
                                      ? (count / totalServiceUsage) * 100
                                      : 0;

                              // Renk oluştur (en popülerden az popülere doğru mavi tonları)
                              final Color boxColor = Color.fromRGBO(
                                0,
                                120,
                                215,
                                1.0 - (index * 0.15),
                              );

                              return Container(
                                width:
                                    MediaQuery.of(context).size.width *
                                    0.42, // yaklaşık olarak grid görünümü
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: boxColor.withOpacity(0.1),
                                  border: Border.all(color: boxColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      serviceName,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '$count kez',
                                          style: AppTextStyles.bodySmall,
                                        ),
                                        Text(
                                          '%${percentage.toStringAsFixed(1)}',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: boxColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Detaylı grafik için not
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.info,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Daha detaylı grafik görünümü için FL Chart kütüphanesi eklenebilir.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Gelir getiren hizmetler
              Text('Hizmet Gelir Analizi', style: AppTextStyles.heading4),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (popularServices.isEmpty)
                        Center(
                          child: Text(
                            'Bu tarih aralığında kayıt bulunamadı',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'En çok satılan hizmet:',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                if (popularServices.isNotEmpty)
                                  Text(
                                    _getServiceName(popularServices.first.key),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ortalama randevu başına hizmet:',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                Text(
                                  _calculateAverageServicesPerAppointment(
                                    filteredAppointments,
                                  ),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Hizmet adını alma yardımcı metodu
  String _getServiceName(String serviceId) {
    final service = _serviceController.services.firstWhereOrNull(
      (s) => s.id == serviceId,
    );

    return service != null ? service.name : 'Bilinmeyen Hizmet';
  }

  // Randevu başına ortalama hizmet hesaplama
  String _calculateAverageServicesPerAppointment(
    List<Appointment> appointments,
  ) {
    if (appointments.isEmpty) {
      return '0';
    }

    int totalServiceCount = 0;
    int appointmentsWithServices = 0;

    for (var appointment in appointments) {
      if (appointment.serviceIds != null &&
          appointment.serviceIds!.isNotEmpty) {
        totalServiceCount += appointment.serviceIds!.length;
        appointmentsWithServices++;
      }
    }

    if (appointmentsWithServices == 0) {
      return '0';
    }

    double average = totalServiceCount / appointmentsWithServices;
    return average.toStringAsFixed(1);
  }

  // Tarih aralığı seçici
  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Başlangıç Tarihi',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate.value,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: _endDate.value,
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            primaryColor: AppColors.primary,
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                            ),
                            buttonTheme: const ButtonThemeData(
                              textTheme: ButtonTextTheme.primary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (picked != null) {
                      _startDate.value = picked;
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd.MM.yyyy').format(_startDate.value),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bitiş Tarihi',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate.value,
                      firstDate: _startDate.value,
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            primaryColor: AppColors.primary,
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                            ),
                            buttonTheme: const ButtonThemeData(
                              textTheme: ButtonTextTheme.primary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (picked != null) {
                      _endDate.value = picked;
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd.MM.yyyy').format(_endDate.value),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        CustomButton(
          text: 'Filtrele',
          type: ButtonType.primary,
          width: 100,
          onPressed: _loadData,
          isLoading: _isLoading.value,
          isFullWidth: false,
        ),
      ],
    );
  }

  // Durum çubuğu
  Widget _buildStatusProgressBar(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final double percentage = total > 0 ? (count / total) * 100 : 0;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: AppTextStyles.bodyMedium),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$count',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            '(%${percentage.toStringAsFixed(1)})',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // Saat çubuğu
  Widget _buildHourBar(int hour, int count, int total) {
    final double percentage = total > 0 ? (count / total) * 100 : 0;
    final double height = 150 * (percentage / 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$count',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 30,
            height: height > 0 ? height : 4, // En az bir görünür yükseklik ver
            color: AppColors.primary.withOpacity(0.7),
          ),
          const SizedBox(height: 4),
          Text('$hour:00', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  // Gün çubuğu
  Widget _buildDayBar(int day, int count, int total) {
    final double percentage = total > 0 ? (count / total) * 100 : 0;

    // Gün adını bul
    final List<String> dayNames = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    final String dayName = dayNames[day - 1];

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(dayName, style: AppTextStyles.bodyMedium),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$count',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            '(%${percentage.toStringAsFixed(1)})',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
