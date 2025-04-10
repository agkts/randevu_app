import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:randevu_app/routes/app_routes.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/appointment_controller.dart';
import '../../models/appointment.dart';
// import '../../utils/responsive_size.dart'; unused
import '../common/custom_app_bar.dart';
// import '../../views/common/custom_button.dart'; unused

class HairdresserAppointmentsScreen extends StatefulWidget {
  const HairdresserAppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<HairdresserAppointmentsScreen> createState() =>
      _HairdresserAppointmentsScreenState();
}

class _HairdresserAppointmentsScreenState
    extends State<HairdresserAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  // Controller'lar
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();

  // Tab controller
  late TabController _tabController;

  // Takvim değişkenleri
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  final Rx<DateTime> _focusedDay = DateTime.now().obs;
  final Rx<DateTime?> _selectedDay = Rx<DateTime?>(DateTime.now());

  // Filtreleme seçenekleri
  final RxInt _selectedFilter =
      0.obs; // 0: Tümü, 1: Bekleyen, 2: Onaylanan, 3: Tamamlanan, 4: İptal Edilen

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Randevuları yükle
  Future<void> _loadAppointments() async {
    await _appointmentController.loadAppointments();
  }

  // Randevuyu onayla
  Future<void> _confirmAppointment(Appointment appointment) async {
    final success = await _appointmentController.updateAppointmentStatus(
      appointment.id!,
      AppointmentStatus.confirmed,
    );

    if (success) {
      Get.snackbar(
        'Başarılı',
        'Randevu başarıyla onaylandı',
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

  // Randevuyu reddet
  Future<void> _rejectAppointment(Appointment appointment) async {
    final confirm =
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
      final success = await _appointmentController.updateAppointmentStatus(
        appointment.id!,
        AppointmentStatus.rejected,
      );

      if (success) {
        Get.snackbar(
          'Başarılı',
          'Randevu başarıyla reddedildi',
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

  // Randevuyu tamamla
  Future<void> _completeAppointment(Appointment appointment) async {
    final success = await _appointmentController.updateAppointmentStatus(
      appointment.id!,
      AppointmentStatus.completed,
    );

    if (success) {
      Get.snackbar(
        'Başarılı',
        'Randevu başarıyla tamamlandı',
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
      appBar: CustomAppBar(title: 'Randevularım'),
      body: SafeArea(
        child: Column(
          children: [
            // Tab bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTextStyles.bodyMedium,
                tabs: const [Tab(text: 'Liste'), Tab(text: 'Takvim')],
              ),
            ),

            // Tab içerikleri
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Liste görünümü
                  _buildListView(),

                  // Takvim görünümü
                  _buildCalendarView(),
                ],
              ),
            ),
          ],
        ),
      ),

      // Yenileme butonu
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAppointments,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // Liste görünümü
  Widget _buildListView() {
    return Column(
      children: [
        // Filtre butonları
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: [
                  _buildFilterChip(0, 'Tümü'),
                  const SizedBox(width: 8),
                  _buildFilterChip(1, 'Bekleyen'),
                  const SizedBox(width: 8),
                  _buildFilterChip(2, 'Onaylanan'),
                  const SizedBox(width: 8),
                  _buildFilterChip(3, 'Tamamlanan'),
                  const SizedBox(width: 8),
                  _buildFilterChip(4, 'İptal/Reddedilen'),
                ],
              ),
            ),
          ),
        ),

        // Randevu listesi
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAppointments,
            child: Obx(() {
              if (_appointmentController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final List<Appointment> filteredAppointments =
                  _getFilteredAppointments();

              if (filteredAppointments.isEmpty) {
                return Center(
                  child: Text(
                    'Randevu bulunamadı',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = filteredAppointments[index];
                  return _buildAppointmentCard(appointment);
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  // Filtre chip'i
  Widget _buildFilterChip(int index, String label) {
    return GestureDetector(
      onTap: () {
        _selectedFilter.value = index;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              _selectedFilter.value == index
                  ? AppColors.primary
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                _selectedFilter.value == index
                    ? AppColors.primary
                    : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color:
                _selectedFilter.value == index
                    ? Colors.white
                    : AppColors.textPrimary,
            fontWeight:
                _selectedFilter.value == index
                    ? FontWeight.w600
                    : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Takvim görünümü
  Widget _buildCalendarView() {
    return Column(
      children: [
        // Takvim
        Obx(
          () => TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay.value,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return _selectedDay.value != null &&
                  isSameDay(_selectedDay.value!, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              _selectedDay.value = selectedDay;
              _focusedDay.value = focusedDay;
            },
            onPageChanged: (focusedDay) {
              _focusedDay.value = focusedDay;
            },
            // Gün içindeki etkinlik sayısını göster
            eventLoader: (day) {
              return _appointmentController.appointments
                  .where((a) => isSameDay(a.dateTime, day))
                  .toList();
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              markersMaxCount: 3,
              markerDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: AppTextStyles.heading4,
            ),
          ),
        ),

        // Seçili günün randevuları
        Expanded(
          child: Obx(() {
            if (_appointmentController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_selectedDay.value == null) {
              return Center(
                child: Text(
                  'Lütfen bir gün seçin',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            final appointmentsForDay =
                _appointmentController.appointments
                    .where((a) => isSameDay(a.dateTime, _selectedDay.value!))
                    .toList();

            if (appointmentsForDay.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat(
                        'dd MMMM yyyy',
                        'tr_TR',
                      ).format(_selectedDay.value!),
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bu tarihte randevu bulunmuyor',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    DateFormat(
                      'dd MMMM yyyy',
                      'tr_TR',
                    ).format(_selectedDay.value!),
                    style: AppTextStyles.heading4,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: appointmentsForDay.length,
                    itemBuilder: (context, index) {
                      final appointment = appointmentsForDay[index];
                      return _buildAppointmentCard(appointment);
                    },
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  // Randevu kartı
  Widget _buildAppointmentCard(Appointment appointment) {
    // Butonların durumunu belirle
    final bool canConfirmReject =
        appointment.status == AppointmentStatus.pending;
    final bool canComplete = appointment.status == AppointmentStatus.confirmed;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
            // Zaman ve durum
            Row(
              children: [
                Icon(Icons.event, size: 16, color: AppColors.primary),
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appointment.customerEmail,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Hizmetler
            if (appointment.serviceNames != null &&
                appointment.serviceNames!.isNotEmpty) ...[
              const SizedBox(height: 12),
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
            ],

            // Müşteri notu
            if (appointment.customerNote != null &&
                appointment.customerNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
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

            // Durum butonları
            if (canConfirmReject || canComplete) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canConfirmReject) ...[
                    // Reddet butonu
                    TextButton.icon(
                      onPressed: () => _rejectAppointment(appointment),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.error,
                        size: 18,
                      ),
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
                      icon: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text('Onayla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],

                  if (canComplete) ...[
                    // Tamamla butonu
                    ElevatedButton.icon(
                      onPressed: () => _completeAppointment(appointment),
                      icon: const Icon(
                        Icons.done_all,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text('Tamamla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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

  // Filtre seçimine göre randevuları filtrele
  List<Appointment> _getFilteredAppointments() {
    switch (_selectedFilter.value) {
      case 1: // Bekleyen
        return _appointmentController.pendingAppointments;
      case 2: // Onaylanan
        return _appointmentController.confirmedAppointments;
      case 3: // Tamamlanan
        return _appointmentController.completedAppointments;
      case 4: // İptal/Reddedilen
        return _appointmentController.cancelledAppointments;
      default: // Tümü
        return _appointmentController.appointments;
    }
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
