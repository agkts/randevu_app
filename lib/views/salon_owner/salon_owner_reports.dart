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
  final Rx<DateTime> _startDate = DateTime.now().subtract(const Duration(days: 30)).obs;
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
              revenueByHairdresser[appointment.hairdresserId]! + appointment.totalPrice!;
          
          // Hizmetlere göre gelir
          if (appointment.serviceIds != null) {
            for (var serviceId in appointment.serviceIds!) {
              if (!revenueByService.containsKey(serviceId)) {
                revenueByService[serviceId] = 0;
              }
              
              // Basit olması için, her hizmetin fiyatını eşit olarak dağıtıyoruz
              double servicePrice = appointment.totalPrice! / appointment.serviceIds!.length;
              revenueByService[serviceId] = revenueByService[serviceId]! + servicePrice;
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
  Map<String, dynamic> _calculateAppointmentStats(List<Appointment> appointments) {
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
      if (appointment.status == AppointmentStatus.completed && appointment.totalPrice != null) {
        customerData[customerKey]!['totalSpent'] = 
            customerData[customerKey]!['totalSpent'] + appointment.totalPrice!;
      }
      
      // Son randevu tarihi
      if (appointment.dateTime.isAfter(customerData[customerKey]!['lastAppointment'])) {
        customerData[customerKey]!['lastAppointment'] = appointment.dateTime;
      }
    }
    
    // Toplam müşteri sayısı
    int totalCustomers = customerData.length;
    
    // Yeni müşteriler (son 30 gün)
    int newCustomers = 0;
    DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    // En çok harcama yapan müşteriler
    List<Map<String, dynamic>> topSpendingCustomers = customerData.values.toList();
    topSpendingCustomers.sort((a, b) => (b['totalSpent'] as double).compareTo(a['totalSpent'] as double));
    
    // Randevu sıklıklarına göre müşteriler
    List<Map<String, dynamic>> frequentCustomers = customerData.values.toList();
    frequentCustomers.sort((a, b) => (b['appointmentCount'] as int).compareTo(a['appointmentCount'] as int));
    
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
    List<MapEntry<String, int>> popularServices = serviceUsageCount.entries.toList();
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
              Obx(() => InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate.value,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: _endDate.value,
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          primaryColor: AppColors.primary,
                          colorScheme: const ColorScheme.light(primary: AppColors.primary),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd.MM.yyyy').format(_startDate.value),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )),
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
              Obx(() => InkWell(
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
                          colorScheme: const ColorScheme.light(primary: AppColors.primary),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd.MM.yyyy').format(_endDate.value),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )),
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
        ),
      ],
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
        
        final List<Appointment> filteredAppointments = _getFilteredAppointments();
        final Map<String, dynamic> revenueData = _calculateRevenue(filteredAppointments);
        
        final double totalRevenue = revenueData['totalRevenue'];
        final Map<String, double> revenueByHairdresser = revenueData['revenueByHairdresser'];
        final Map<String, double> revenueByService = revenueData['revenueByService'];
        
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
                      final String hairdresserId = revenueByHairdresser.keys.elementAt(index);
                      final double revenue = revenueByHairdresser[hairdresserId]!;
                      
                      // Kuaför adını bul
                      String hairdresserName = 'Bilinmeyen Kuaför';
                      final hairdresser = _hairdresserController.hairdressers
                          .firstWhereOrNull((h) => h.id == hairdresserId);
                      
                      if (hairdresser != null) {
                        hairdresserName = hairdresser.name;
                      }
                      
                      // Yüzde hesapla
                      final double percentage = totalRevenue > 0 
                          ? (revenue / totalRevenue) * 100 
                          : 0;
                      
                      return ListTile(
                        title: Text(hairdresserName),
                        subtitle: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                      final String serviceId = revenueByService.keys.elementAt(index);
                      final double revenue = revenueByService[serviceId]!;
                      
                      // Hizmet adını bul
                      String serviceName = 'Bilinmeyen Hizmet';
                      final service = _serviceController.services
                          .firstWhereOrNull((s) => s.id == serviceId);
                      
                      if (service != null) {
                        serviceName = service.name;
                      }
                      
                      // Yüzde hesapla
                      final double percentage = totalRevenue > 0 
                          ? (revenue / totalRevenue) * 100 
                          : 0;
                      
                      return ListTile(
                        title: Text(serviceName),
                        subtitle: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
        
        final List<Appointment> filteredAppointments = _getFilteredAppointments();
        final Map<String, dynamic> appointmentStats = _calculateAppointmentStats(filteredAppointments);
        
        final int totalAppointments = appointmentStats['totalAppointments'];
        final int pendingCount = appointmentStats['pendingCount'];
        final int confirmedCount = appointmentStats['confirmedCount'];
        final int completedCount = appointmentStats['completedCount'];
        final int cancelledCount = appointmentStats['cancelledCount'];
        final int rejectedCount = appointmentStats['rejectedCount'];
        
        final Map<String, int> appointmentsByHairdresser = appointmentStats['appointmentsByHairdresser'];
        final Map<int, int> appointmentsByHour = appointmentStats['appointmentsByHour'];
        final Map<int, int> appointmentsByDay = appointmentStats['appointmentsByDay'];
        
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
                        AppColors.warning
                      ),
                      const SizedBox(height: 12),
                      
                      // Onaylanan randevular
                      _buildStatusProgressBar(
                        'Onaylanan', 
                        confirmedCount, 
                        totalAppointments, 
                        AppColors.info
                      ),
                      const SizedBox(height: 12),
                      
                      // Tamamlanan randevular
                      _buildStatusProgressBar(
                        'Tamamlanan', 
                        completedCount, 
                        totalAppointments, 
                        AppColors.success
                      ),
                      const SizedBox(height: 12),
                      
                      // İptal edilen randevular
                      _buildStatusProgressBar(
                        'İptal Edilen', 
                        cancelledCount, 
                        totalAppointments, 
                        AppColors.error
                      ),
                      const SizedBox(height: 12),
                      
                      // Reddedilen randevular
                      _buildStatusProgressBar(
                        'Reddedilen', 
                        rejectedCount, 
                        totalAppointments, 
                        AppColors.error
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



