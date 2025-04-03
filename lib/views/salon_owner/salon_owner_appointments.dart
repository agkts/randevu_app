import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/hairdresser_controller.dart';
import '../../models/appointment.dart';
import '../../models/hairdresser.dart';
import '../../utils/responsive_size.dart';
import '../common/custom_app_bar.dart';
import '../../views/common/custom_button.dart';
import '../../views/common/custom_text_field.dart';

class SalonOwnerAppointmentsScreen extends StatefulWidget {
  const SalonOwnerAppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<SalonOwnerAppointmentsScreen> createState() =>
      _SalonOwnerAppointmentsScreenState();
}

class _SalonOwnerAppointmentsScreenState
    extends State<SalonOwnerAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  // Controller'lar
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();
  final HairdresserController _hairdresserController =
      Get.find<HairdresserController>();

  // Tab controller
  late TabController _tabController;

  // Takvim değişkenleri
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  final RxDateTime _focusedDay = DateTime.now().obs;
  final Rx<DateTime?> _selectedDay = Rx<DateTime?>(DateTime.now());

  // Filtreleme seçenekleri
  final RxInt _selectedFilter =
      0.obs; // 0: Tümü, 1: Bekleyen, 2: Onaylanmış, 3: Tamamlanmış, 4: İptal/Reddedilen
  final RxString _searchQuery = ''.obs;
  final TextEditingController _searchController = TextEditingController();
  final Rx<Hairdresser?> _selectedHairdresser = Rx<Hairdresser?>(null);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();

    // Arama değişikliklerini dinle
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Başlangıç verilerini yükle
  Future<void> _loadInitialData() async {
    await _appointmentController.loadAppointments();
    await _hairdresserController.loadHairdressers();
  }

  // Randevu statüsünü güncelle
  Future<void> _updateAppointmentStatus(
    Appointment appointment,
    AppointmentStatus newStatus,
  ) async {
    final String statusText =
        newStatus == AppointmentStatus.confirmed
            ? 'onaylamak'
            : newStatus == AppointmentStatus.rejected
            ? 'reddetmek'
            : newStatus == AppointmentStatus.completed
            ? 'tamamlamak'
            : newStatus == AppointmentStatus.cancelled
            ? 'iptal etmek'
            : 'güncellemek';

    final bool confirm =
        await Get.dialog<bool>(
          AlertDialog(
            title: Text('Randevu ${statusText.capitalize}'),
            content: Text(
              'Bu randevuyu ${statusText} istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: Text(
                  statusText.capitalize!,
                  style: TextStyle(
                    color:
                        newStatus == AppointmentStatus.rejected ||
                                newStatus == AppointmentStatus.cancelled
                            ? AppColors.error
                            : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      final bool success = await _appointmentController.updateAppointmentStatus(
        appointment.id!,
        newStatus,
      );

      if (success) {
        Get.snackbar(
          'Başarılı',
          'Randevu durumu güncellendi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Hata',
          'Randevu durumu güncellenirken bir hata oluştu',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  // Yeni randevu ekleme
  void _showAddAppointmentModal() {
    // Uygula butonunu aktifleştirecek değişkenler
    final RxBool isCustomerValid = false.obs;
    final RxBool isHairdresserSelected = false.obs;
    final RxBool isServiceSelected = false.obs;
    final RxBool isDateTimeSelected = false.obs;

    // Form değişkenleri
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    final Rx<DateTime> selectedDate = DateTime.now().obs;
    final RxString selectedTimeSlot = ''.obs;
    final Rx<Hairdresser?> hairdresser = Rx<Hairdresser?>(null);

    // Form anahtarı
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    // Zaman dilimlerini oluştur (örnek olarak)
    final List<String> timeSlots = [];
    for (int hour = 9; hour < 18; hour++) {
      timeSlots.add('${hour.toString().padLeft(2, '0')}:00');
      timeSlots.add('${hour.toString().padLeft(2, '0')}:30');
    }

    Get.bottomSheet(
      Container(
        height: Responsive.height * 0.8,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Başlık
            Row(
              children: [
                Text('Yeni Randevu Ekle', style: AppTextStyles.heading3),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),

            // İçerik
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Müşteri Bilgileri Bölümü
                      Text('Müşteri Bilgileri', style: AppTextStyles.heading4),
                      const SizedBox(height: 16),

                      // Ad Soyad
                      CustomTextField(
                        label: 'Ad Soyad',
                        hint: 'Müşterinin adı ve soyadı',
                        controller: nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ad soyad boş olamaz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Telefon
                      CustomTextField(
                        label: 'Telefon',
                        hint: 'Müşterinin telefon numarası',
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Telefon numarası boş olamaz';
                          }
                          if (!RegExp(
                            r'^\d{10,11}$',
                          ).hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
                            return 'Geçerli bir telefon numarası girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      CustomTextField(
                        label: 'E-posta',
                        hint: 'Müşterinin e-posta adresi',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'E-posta adresi boş olamaz';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Geçerli bir e-posta adresi girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Not (opsiyonel)
                      CustomTextField(
                        label: 'Not (Opsiyonel)',
                        hint: 'Randevu ile ilgili not',
                        controller: noteController,
                        isMultiline: true,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Kuaför Seçimi
                      Text('Kuaför Seçimi', style: AppTextStyles.heading4),
                      const SizedBox(height: 16),

                      // Kuaför listesi
                      Obx(() {
                        if (_hairdresserController.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final List<Hairdresser> activeHairdressers =
                            _hairdresserController.activeHairdressers;

                        if (activeHairdressers.isEmpty) {
                          return const Text('Aktif kuaför bulunamadı');
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Hairdresser>(
                              value: hairdresser.value,
                              hint: const Text('Kuaför seçin'),
                              isExpanded: true,
                              items:
                                  activeHairdressers.map((h) {
                                    return DropdownMenuItem<Hairdresser>(
                                      value: h,
                                      child: Text(h.name),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                hairdresser.value = value;
                                isHairdresserSelected.value = value != null;
                              },
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),

                      // Tarih ve Saat Seçimi
                      Text(
                        'Tarih ve Saat Seçimi',
                        style: AppTextStyles.heading4,
                      ),
                      const SizedBox(height: 16),

                      // Tarih seçimi
                      Obx(() {
                        return InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate.value,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 60),
                              ),
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
                              selectedDate.value = picked;
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat(
                                    'dd MMMM yyyy',
                                    'tr_TR',
                                  ).format(selectedDate.value),
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      // Saat seçimi
                      Text('Saat', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 8),
                      Obx(
                        () => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              timeSlots.map((time) {
                                final bool isSelected =
                                    selectedTimeSlot.value == time;
                                return GestureDetector(
                                  onTap: () {
                                    selectedTimeSlot.value = time;
                                    isDateTimeSelected.value = true;
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? AppColors.primary
                                                : AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      time,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Alt butonlar
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'İptal',
                      type: ButtonType.outlined,
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() {
                      return CustomButton(
                        text: 'Randevu Oluştur',
                        type: ButtonType.primary,
                        onPressed: () async {
                          if (formKey.currentState!.validate() &&
                              hairdresser.value != null &&
                              selectedTimeSlot.value.isNotEmpty) {
                            // Form verilerini AppointmentController'a aktar
                            _appointmentController.customerName.value =
                                nameController.text;
                            _appointmentController.customerPhone.value =
                                phoneController.text;
                            _appointmentController.customerEmail.value =
                                emailController.text;
                            _appointmentController.customerNote.value =
                                noteController.text;
                            _appointmentController.selectedHairdresser.value =
                                hairdresser.value;
                            _appointmentController.selectedDate.value =
                                selectedDate.value;

                            // Saati ayarla
                            final List<String> timeParts = selectedTimeSlot
                                .value
                                .split(':');
                            final int hour = int.parse(timeParts[0]);
                            final int minute = int.parse(timeParts[1]);

                            final DateTime selectedDateTime = DateTime(
                              selectedDate.value.year,
                              selectedDate.value.month,
                              selectedDate.value.day,
                              hour,
                              minute,
                            );

                            _appointmentController.selectedTime.value =
                                selectedDateTime;

                            // Randevuyu oluştur
                            final result =
                                await _appointmentController
                                    .createAppointment();

                            if (result['success']) {
                              Get.back();
                              Get.snackbar(
                                'Başarılı',
                                'Randevu başarıyla oluşturuldu',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.success.withOpacity(
                                  0.8,
                                ),
                                colorText: Colors.white,
                              );
                            } else {
                              Get.snackbar(
                                'Hata',
                                result['message'] ??
                                    'Randevu oluşturulurken bir hata oluştu',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.error.withOpacity(
                                  0.8,
                                ),
                                colorText: Colors.white,
                              );
                            }
                          } else {
                            Get.snackbar(
                              'Uyarı',
                              'Lütfen tüm alanları doğru şekilde doldurun',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.warning.withOpacity(
                                0.8,
                              ),
                              colorText: Colors.white,
                            );
                          }
                        },
                        isLoading: _appointmentController.isCreating.value,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Randevular'),
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

      // Yeni randevu ekleme butonu
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAppointmentModal,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Liste görünümü
  Widget _buildListView() {
    return Column(
      children: [
        // Filtreleme ve arama
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Arama alanı
              CustomTextField(
                label: '',
                hint: 'Müşteri adı, telefon veya e-posta ile ara...',
                controller: _searchController,
                prefixIcon: Icons.search,
                suffixIcon: Icons.clear,
                onSuffixIconPressed: () {
                  _searchController.clear();
                },
              ),
              const SizedBox(height: 16),

              // Kuaför filtresi
              Row(
                children: [
                  Text(
                    'Kuaför:',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() {
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<Hairdresser?>(
                          value: _selectedHairdresser.value,
                          hint: const Text('Tüm Kuaförler'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<Hairdresser?>(
                              value: null,
                              child: Text('Tüm Kuaförler'),
                            ),
                            ..._hairdresserController.hairdressers.map((h) {
                              return DropdownMenuItem<Hairdresser>(
                                value: h,
                                child: Text(h.name),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            _selectedHairdresser.value = value;
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Durum filtreleme butonları
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
            onRefresh: _loadInitialData,
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

            // Müşteri ve kuaför bilgileri
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Müşteri bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Müşteri',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.customerName,
                        style: AppTextStyles.bodyMedium.copyWith(
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
                    ],
                  ),
                ),

                // Kuaför bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kuaför',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.hairdresserName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
                    ),
                  ),
                ],
              ),
            ],

            // İşlem butonları
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Durum değiştirme butonları (duruma göre)
                if (appointment.status == AppointmentStatus.pending) ...[
                  // Reddet butonu
                  TextButton.icon(
                    onPressed:
                        () => _updateAppointmentStatus(
                          appointment,
                          AppointmentStatus.rejected,
                        ),
                    icon: const Icon(Icons.close, color: AppColors.error),
                    label: const Text(
                      'Reddet',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Onayla butonu
                  ElevatedButton.icon(
                    onPressed:
                        () => _updateAppointmentStatus(
                          appointment,
                          AppointmentStatus.confirmed,
                        ),
                    icon: const Icon(Icons.check),
                    label: const Text('Onayla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ],

                if (appointment.status == AppointmentStatus.confirmed) ...[
                  // Tamamla butonu
                  ElevatedButton.icon(
                    onPressed:
                        () => _updateAppointmentStatus(
                          appointment,
                          AppointmentStatus.completed,
                        ),
                    icon: const Icon(Icons.done_all),
                    label: const Text('Tamamla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],

                if (appointment.status == AppointmentStatus.pending ||
                    appointment.status == AppointmentStatus.confirmed) ...[
                  // İptal butonu
                  if (appointment.status != AppointmentStatus.pending)
                    const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed:
                        () => _updateAppointmentStatus(
                          appointment,
                          AppointmentStatus.cancelled,
                        ),
                    icon: const Icon(
                      Icons.cancel_outlined,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'İptal',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Filtre seçimine göre randevuları filtrele
  List<Appointment> _getFilteredAppointments() {
    List<Appointment> appointments = [];

    // Durum filtreleme
    switch (_selectedFilter.value) {
      case 1: // Bekleyen
        appointments = _appointmentController.pendingAppointments;
        break;
      case 2: // Onaylanan
        appointments = _appointmentController.confirmedAppointments;
        break;
      case 3: // Tamamlanan
        appointments = _appointmentController.completedAppointments;
        break;
      case 4: // İptal/Reddedilen
        appointments = _appointmentController.cancelledAppointments;
        break;
      default: // Tümü
        appointments = _appointmentController.appointments;
        break;
    }

    // Kuaför filtreleme
    if (_selectedHairdresser.value != null) {
      appointments =
          appointments
              .where((a) => a.hairdresserId == _selectedHairdresser.value!.id)
              .toList();
    }

    // Arama filtreleme
    if (_searchQuery.value.isNotEmpty) {
      final String query = _searchQuery.value.toLowerCase();
      appointments =
          appointments
              .where(
                (a) =>
                    a.customerName.toLowerCase().contains(query) ||
                    a.customerPhone.toLowerCase().contains(query) ||
                    a.customerEmail.toLowerCase().contains(query),
              )
              .toList();
    }

    return appointments;
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
