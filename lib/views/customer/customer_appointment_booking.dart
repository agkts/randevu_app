import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/hairdresser_controller.dart';
import '../../controllers/service_controller.dart';
//import '../../models/hairdresser.dart'; unused
//import '../../models/service.dart'; unused
import '../../routes/app_routes.dart';
import '../../utils/responsive_size.dart';
import '../common/custom_app_bar.dart';
import '../../views/common/custom_button.dart';
import '../../views/common/custom_text_field.dart';

class CustomerAppointmentBookingScreen extends StatefulWidget {
  const CustomerAppointmentBookingScreen({Key? key}) : super(key: key);

  @override
  State<CustomerAppointmentBookingScreen> createState() =>
      _CustomerAppointmentBookingScreenState();
}

class _CustomerAppointmentBookingScreenState
    extends State<CustomerAppointmentBookingScreen> {
  // Controller'lar
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();
  final HairdresserController _hairdresserController =
      Get.find<HairdresserController>();
  final ServiceController _serviceController = Get.find<ServiceController>();

  // Text controller'lar
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Form anahtarı
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Adım kontrol değişkenleri
  final RxInt currentStep = 0.obs;
  final RxBool isCustomerInfoValid = false.obs;
  final RxBool isServiceSelected = false.obs;
  final RxBool isHairdresserSelected = false.obs;
  final RxBool isDateTimeSelected = false.obs;

  // Diğer değişkenler
  final RxString selectedTimeSlot = ''.obs;
  final RxList<String> availableTimeSlots = <String>[].obs;
  final DateTime currentDate = DateTime.now();
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  final Rx<DateTime> focusedDay = DateTime.now().obs;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Başlangıç verilerini yükle
  Future<void> _loadInitialData() async {
    await _hairdresserController.loadHairdressers();
    await _serviceController.loadServices();
    _generateAvailableTimeSlots();
  }

  // Boş zaman dilimlerini oluştur (örnek olarak)
  void _generateAvailableTimeSlots() {
    List<String> slots = [];

    // 09:00'dan 18:00'a kadar 30 dakikalık dilimler
    for (int hour = 9; hour < 18; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
      slots.add('${hour.toString().padLeft(2, '0')}:30');
    }

    availableTimeSlots.value = slots;
  }

  // Müşteri bilgilerini doğrula
  void _validateCustomerInfo() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      // Randevu controller'a değerleri kaydet
      _appointmentController.customerName.value = _nameController.text;
      _appointmentController.customerPhone.value = _phoneController.text;
      _appointmentController.customerEmail.value = _emailController.text;
      _appointmentController.customerNote.value = _noteController.text;

      isCustomerInfoValid.value = true;
      currentStep.value = 1; // Bir sonraki adıma geç
    }
  }

  // Randevu oluşturmayı tamamla
  void _completeBooking() async {
    if (!isCustomerInfoValid.value ||
        !isServiceSelected.value ||
        !isHairdresserSelected.value ||
        !isDateTimeSelected.value) {
      Get.snackbar(
        'Hata',
        'Lütfen tüm gerekli bilgileri doldurun',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Seçilen saat
    if (selectedTimeSlot.value.isNotEmpty) {
      final List<String> timeParts = selectedTimeSlot.value.split(':');
      final int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);

      final DateTime selectedDateTime = DateTime(
        _appointmentController.selectedDate.value.year,
        _appointmentController.selectedDate.value.month,
        _appointmentController.selectedDate.value.day,
        hour,
        minute,
      );

      _appointmentController.selectedTime.value = selectedDateTime;
    }

    // Randevu oluştur
    final result = await _appointmentController.createAppointment();

    if (result['success']) {
      // Randevu başarıyla oluşturuldu, onay ekranına git
      final appointmentData = result['data'];
      Get.toNamed(
        AppRoutes.customerAppointmentConfirmation,
        arguments: appointmentData,
      );
    } else {
      // Hata durumunda
      Get.snackbar(
        'Hata',
        result['message'] ?? 'Randevu oluşturulurken bir hata oluştu',
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
        title: 'Randevu Al',
        showBackButton: false,
        //!! burası ai ile düzenlenecek
        actions: [
          TextButton(
            onPressed: () {
              Get.toNamed(AppRoutes.hairdresserLogin);
            },
            child: Text(
              "Giriş Yap",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        leading: IconButton(
          onPressed: () {
            Get.toNamed(AppRoutes.customerAppointmentManage);
          },
          icon: Icon(Icons.edit_document),
        ),
        //!!!!!!!!!
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 24),

              // Adımlara göre farklı içerikler
              Obx(() {
                if (currentStep.value == 0) {
                  return _buildCustomerInfoStep();
                } else if (currentStep.value == 1) {
                  return _buildServiceSelectionStep();
                } else if (currentStep.value == 2) {
                  return _buildHairdresserSelectionStep();
                } else {
                  return _buildDateTimeSelectionStep();
                }
              }),
            ],
          ),
        ),
      ),

      // Adım kontrol butonları
      bottomNavigationBar: Obx(() => _buildBottomButtons()),
    );
  }

  // Adım göstergesi
  Widget _buildStepIndicator() {
    return Obx(() {
      return Row(
        children: [
          _buildStepCircle(0, 'Bilgiler', isCustomerInfoValid.value),
          _buildStepDivider(),
          _buildStepCircle(1, 'Hizmet', isServiceSelected.value),
          _buildStepDivider(),
          _buildStepCircle(2, 'Kuaför', isHairdresserSelected.value),
          _buildStepDivider(),
          _buildStepCircle(3, 'Tarih & Saat', isDateTimeSelected.value),
        ],
      );
    });
  }

  // Adım dairesi
  Widget _buildStepCircle(int step, String label, bool isCompleted) {
    final bool isActive = currentStep.value == step;
    final bool isPassed = currentStep.value > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  isPassed || isCompleted
                      ? AppColors.success
                      : isActive
                      ? AppColors.primary
                      : AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Center(
              child:
                  isPassed || isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                        '${step + 1}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color:
                              isActive ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Adım ayırıcı
  Widget _buildStepDivider() {
    return Container(width: 16, height: 1.5, color: AppColors.border);
  }

  // Alt butonlar
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Geri butonu (ilk adımda gösterme)
          if (currentStep.value > 0)
            Expanded(
              child: CustomButton(
                text: 'Geri',
                type: ButtonType.outlined,
                onPressed: () {
                  currentStep.value--;
                },
              ),
            ),

          // İlk adımda değilsek boşluk ekle
          if (currentStep.value > 0) const SizedBox(width: 16),

          // İleri veya Tamamla butonu
          Expanded(
            child: CustomButton(
              text: currentStep.value < 3 ? 'İleri' : 'Tamamla',
              type: ButtonType.primary,
              onPressed: () {
                if (currentStep.value == 0) {
                  _validateCustomerInfo();
                } else if (currentStep.value == 1) {
                  if (_appointmentController.selectedServices.isNotEmpty) {
                    isServiceSelected.value = true;
                    currentStep.value = 2;
                  } else {
                    Get.snackbar(
                      'Uyarı',
                      'Lütfen en az bir hizmet seçin',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                } else if (currentStep.value == 2) {
                  if (_appointmentController.selectedHairdresser.value !=
                      null) {
                    isHairdresserSelected.value = true;
                    currentStep.value = 3;
                  } else {
                    Get.snackbar(
                      'Uyarı',
                      'Lütfen bir kuaför seçin',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                } else if (currentStep.value == 3) {
                  if (selectedTimeSlot.value.isNotEmpty) {
                    isDateTimeSelected.value = true;
                    _completeBooking();
                  } else {
                    Get.snackbar(
                      'Uyarı',
                      'Lütfen bir saat seçin',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Adım 1: Müşteri Bilgileri
  Widget _buildCustomerInfoStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kişisel Bilgileriniz', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            'Randevu alabilmek için aşağıdaki bilgileri doldurun.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // İsim alanı
          CustomTextField(
            label: 'Adınız Soyadınız',
            hint: 'Adınızı ve soyadınızı girin',
            controller: _nameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen adınızı ve soyadınızı girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Telefon alanı
          CustomTextField(
            label: 'Telefon Numaranız',
            hint: '05XXXXXXXXX',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen telefon numaranızı girin';
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

          // E-posta alanı
          CustomTextField(
            label: 'E-posta Adresiniz',
            hint: 'ornek@email.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen e-posta adresinizi girin';
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

          // Not alanı (opsiyonel)
          CustomTextField(
            label: 'Eklemek İstediğiniz Not (Opsiyonel)',
            hint: 'Eklemek istediğiniz bir not varsa buraya yazabilirsiniz',
            controller: _noteController,
            isMultiline: true,
            maxLines: 3,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Adım 2: Hizmet Seçimi
  Widget _buildServiceSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hizmet Seçin', style: AppTextStyles.heading3),
        const SizedBox(height: 8),
        Text(
          'Almak istediğiniz hizmetleri seçin.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Hizmet listesi
        Obx(() {
          if (_serviceController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_serviceController.activeServices.isEmpty) {
            return const Center(child: Text('Henüz hizmet bulunmuyor'));
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _serviceController.activeServices.length,
            itemBuilder: (context, index) {
              final service = _serviceController.activeServices[index];

              return Obx(() {
                final isSelected = _appointmentController.selectedServices.any(
                  (s) => s.id == service.id,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (isSelected) {
                        _appointmentController.selectedServices.removeWhere(
                          (s) => s.id == service.id,
                        );
                      } else {
                        _appointmentController.selectedServices.add(service);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Seçim indikatörü
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                width: 2,
                              ),
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                            ),
                            child:
                                isSelected
                                    ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 16),

                          // Hizmet bilgisi
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (service.description != null)
                                  Text(
                                    service.description!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Fiyat ve süre
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                service.formattedPrice,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                service.formattedDuration,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              });
            },
          );
        }),

        const SizedBox(height: 16),
      ],
    );
  }

  // Adım 3: Kuaför Seçimi
  Widget _buildHairdresserSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kuaför Seçin', style: AppTextStyles.heading3),
        const SizedBox(height: 8),
        Text(
          'Randevu almak istediğiniz kuaförü seçin.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Kuaför listesi
        Obx(() {
          if (_hairdresserController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_hairdresserController.activeHairdressers.isEmpty) {
            return const Center(child: Text('Henüz kuaför bulunmuyor'));
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _hairdresserController.activeHairdressers.length,
            itemBuilder: (context, index) {
              final hairdresser =
                  _hairdresserController.activeHairdressers[index];

              return Obx(() {
                final isSelected =
                    _appointmentController.selectedHairdresser.value?.id ==
                    hairdresser.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      _appointmentController.selectedHairdresser.value =
                          hairdresser;
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Kuaför resmi veya placeholder
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child:
                                hairdresser.profileImage != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(30),
                                      child: Image.network(
                                        hairdresser.profileImage!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return const Icon(
                                            Icons.person,
                                            size: 30,
                                            color: AppColors.textSecondary,
                                          );
                                        },
                                      ),
                                    )
                                    : const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(width: 16),

                          // Kuaför bilgisi
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
                                if (hairdresser.email != null)
                                  Text(
                                    hairdresser.email!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Seçim indikatörü
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                width: 2,
                              ),
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                            ),
                            child:
                                isSelected
                                    ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              });
            },
          );
        }),

        const SizedBox(height: 16),
      ],
    );
  }

  // Adım 4: Tarih ve Saat Seçimi
  Widget _buildDateTimeSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tarih ve Saat Seçin', style: AppTextStyles.heading3),
        const SizedBox(height: 8),
        Text(
          'Randevu almak istediğiniz tarih ve saati seçin.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Takvim
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 60)),
              focusedDay: focusedDay.value,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(
                  _appointmentController.selectedDate.value,
                  day,
                );
              },
              onDaySelected: (selectedDay, focDay) {
                _appointmentController.selectedDate.value = selectedDay;
                focusedDay.value = focDay;
                selectedTimeSlot.value =
                    ''; // Yeni gün seçildiğinde saat sıfırla
              },
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: AppTextStyles.heading4,
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Seçilen tarih
        Obx(() {
          final DateFormat formatter = DateFormat('dd MMMM yyyy', 'tr_TR');
          return Text(
            'Seçilen Tarih: ${formatter.format(_appointmentController.selectedDate.value)}',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          );
        }),
        const SizedBox(height: 16),

        // Saat seçimi
        Text(
          'Uygun Saatler',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        Obx(() {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                availableTimeSlots.map((time) {
                  final isSelected = selectedTimeSlot.value == time;

                  return InkWell(
                    onTap: () {
                      selectedTimeSlot.value = time;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isSelected ? AppColors.primary : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        time,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          );
        }),

        const SizedBox(height: 24),
      ],
    );
  }
}
