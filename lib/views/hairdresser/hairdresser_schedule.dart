import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/hairdresser_controller.dart';
import '../../models/hairdresser.dart';
import '../../utils/responsive_size.dart';
import '../common/custom_app_bar.dart';
import '../../views/common/custom_button.dart';

class HairdresserScheduleScreen extends StatefulWidget {
  const HairdresserScheduleScreen({Key? key}) : super(key: key);

  @override
  State<HairdresserScheduleScreen> createState() =>
      _HairdresserScheduleScreenState();
}

class _HairdresserScheduleScreenState extends State<HairdresserScheduleScreen>
    with SingleTickerProviderStateMixin {
  // Controller
  final HairdresserController _hairdresserController =
      Get.find<HairdresserController>();

  // Tab controller
  late TabController _tabController;

  // Çalışma saatleri için geçici depo
  final RxMap<String, WorkingHours> _workingSchedule =
      RxMap<String, WorkingHours>({});

  // Tatil günleri
  final RxList<DateTime> _holidayDates = <DateTime>[].obs;

  // Takvim değişkenleri
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  final RxDateTime _focusedDay = DateTime.now().obs;
  final Rx<Set<DateTime>> _selectedDays = Rx<Set<DateTime>>(Set<DateTime>());

  // Yükleniyor durumu
  final RxBool _isHolidayUpdating = false.obs;

  // Gün isimleri
  final Map<String, String> _dayNames = {
    'monday': 'Pazartesi',
    'tuesday': 'Salı',
    'wednesday': 'Çarşamba',
    'thursday': 'Perşembe',
    'friday': 'Cuma',
    'saturday': 'Cumartesi',
    'sunday': 'Pazar',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHairdresserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Kuaför verilerini yükle
  Future<void> _loadHairdresserData() async {
    await _hairdresserController.loadCurrentHairdresser();

    if (_hairdresserController.currentHairdresser.value != null) {
      // Çalışma saatlerini güncelle
      _workingSchedule.assignAll(
        _hairdresserController.currentHairdresser.value!.workingSchedule,
      );

      // Tatil günlerini güncelle
      if (_hairdresserController.currentHairdresser.value!.holidayDates !=
          null) {
        _holidayDates.assignAll(
          _hairdresserController.currentHairdresser.value!.holidayDates!,
        );
        _selectedDays.value = Set<DateTime>.from(_holidayDates);
      }
    }
  }

  // Çalışma saatlerini güncelle
  Future<void> _updateWorkingHours() async {
    if (_hairdresserController.currentHairdresser.value == null) {
      return;
    }

    final bool success = await _hairdresserController.updateWorkingHours(
      _hairdresserController.currentHairdresser.value!.id,
      _workingSchedule,
    );

    if (success) {
      Get.snackbar(
        'Başarılı',
        'Çalışma saatleri güncellendi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.8),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Hata',
        'Çalışma saatleri güncellenirken bir hata oluştu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // Tatil günlerini güncelle
  Future<void> _updateHolidayDates() async {
    if (_hairdresserController.currentHairdresser.value == null) {
      return;
    }

    _isHolidayUpdating.value = true;

    try {
      final bool success = await _hairdresserController.updateHolidayDates(
        _hairdresserController.currentHairdresser.value!.id,
        _holidayDates.toList(),
      );

      if (success) {
        Get.snackbar(
          'Başarılı',
          'Tatil günleri güncellendi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Hata',
          'Tatil günleri güncellenirken bir hata oluştu',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } finally {
      _isHolidayUpdating.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Çalışma Saatlerim'),
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
                tabs: const [
                  Tab(text: 'Çalışma Saatleri'),
                  Tab(text: 'Tatil Günleri'),
                ],
              ),
            ),

            // Tab içeriği
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Çalışma saatleri
                  _buildWorkingHoursTab(),

                  // Tatil günleri
                  _buildHolidayDatesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Çalışma saatleri sekmesi
  Widget _buildWorkingHoursTab() {
    return Obx(() {
      if (_hairdresserController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_hairdresserController.currentHairdresser.value == null) {
        return Center(
          child: Text(
            'Kuaför bilgileri yüklenemedi',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        );
      }

      return Column(
        children: [
          // Açıklama
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Her gün için çalışma saatlerinizi ayarlayabilirsiniz. Çalışmadığınız günleri devre dışı bırakabilirsiniz.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Çalışma saatleri listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _workingSchedule.length,
              itemBuilder: (context, index) {
                final String day = _workingSchedule.keys.elementAt(index);
                final WorkingHours hours = _workingSchedule[day]!;

                return _buildDayScheduleCard(day, hours);
              },
            ),
          ),

          // Kaydet butonu
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomButton(
              text: 'Çalışma Saatlerini Kaydet',
              type: ButtonType.primary,
              onPressed: _updateWorkingHours,
              isLoading: _hairdresserController.isUpdating.value,
            ),
          ),
        ],
      );
    });
  }

  // Gün çalışma saati kartı
  Widget _buildDayScheduleCard(String day, WorkingHours hours) {
    return Obx(() {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gün adı ve aktif/pasif switch
              Row(
                children: [
                  Text(
                    _dayNames[day] ?? day,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _workingSchedule[day]!.isActive,
                    onChanged: (value) {
                      _workingSchedule[day] = WorkingHours(
                        isActive: value,
                        openTime: _workingSchedule[day]!.openTime,
                        closeTime: _workingSchedule[day]!.closeTime,
                      );
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),

              // Pasif ise gösterme
              if (_workingSchedule[day]!.isActive) ...[
                const Divider(),

                // Açılış ve kapanış saatleri
                Row(
                  children: [
                    // Açılış saati
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Açılış Saati',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap:
                                () => _selectTime(
                                  context,
                                  day,
                                  true,
                                  _workingSchedule[day]!.openTime,
                                ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _workingSchedule[day]!.openTime,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Kapanış saati
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kapanış Saati',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap:
                                () => _selectTime(
                                  context,
                                  day,
                                  false,
                                  _workingSchedule[day]!.closeTime,
                                ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _workingSchedule[day]!.closeTime,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  // Saat seçme
  Future<void> _selectTime(
    BuildContext context,
    String day,
    bool isOpenTime,
    String initialTime,
  ) async {
    final List<String> timeParts = initialTime.split(':');
    final int hour = int.parse(timeParts[0]);
    final int minute = int.parse(timeParts[1]);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
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
      final String formattedHour = picked.hour.toString().padLeft(2, '0');
      final String formattedMinute = picked.minute.toString().padLeft(2, '0');
      final String newTime = '$formattedHour:$formattedMinute';

      if (isOpenTime) {
        _workingSchedule[day] = WorkingHours(
          isActive: _workingSchedule[day]!.isActive,
          openTime: newTime,
          closeTime: _workingSchedule[day]!.closeTime,
        );
      } else {
        _workingSchedule[day] = WorkingHours(
          isActive: _workingSchedule[day]!.isActive,
          openTime: _workingSchedule[day]!.openTime,
          closeTime: newTime,
        );
      }
    }
  }

  // Tatil günleri sekmesi
  Widget _buildHolidayDatesTab() {
    return Column(
      children: [
        // Açıklama
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Çalışmayacağınız özel günleri (tatil, izin, vb.) takvimden seçebilirsiniz. Seçili günlerde randevu alınamayacaktır.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),

        // Takvim
        Expanded(
          child: Obx(() {
            return TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay.value,
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableCalendarFormats: const {CalendarFormat.month: 'Ay'},
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
              selectedDayPredicate: (day) {
                return _selectedDays.value.contains(day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                final Set<DateTime> newSelectedDays = Set<DateTime>.from(
                  _selectedDays.value,
                );

                if (_selectedDays.value.contains(selectedDay)) {
                  newSelectedDays.remove(selectedDay);
                } else {
                  newSelectedDays.add(selectedDay);
                }

                _selectedDays.value = newSelectedDays;
                _holidayDates.assignAll(newSelectedDays);
                _focusedDay.value = focusedDay;
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),

        // Seçili günler
        Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            return Row(
              children: [
                Text(
                  'Seçili Tatil Günleri: ${_selectedDays.value.length}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_selectedDays.value.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _selectedDays.value = {};
                      _holidayDates.clear();
                    },
                    child: const Text('Temizle'),
                  ),
              ],
            );
          }),
        ),

        // Kaydet butonu
        Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            return CustomButton(
              text: 'Tatil Günlerini Kaydet',
              type: ButtonType.primary,
              onPressed: _updateHolidayDates,
              isLoading: _isHolidayUpdating.value,
            );
          }),
        ),
      ],
    );
  }
}
