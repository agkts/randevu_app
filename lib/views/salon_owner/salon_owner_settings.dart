import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/salon_controller.dart';
import '../../models/salon.dart';
import '../../routes/app_routes.dart';
import '../../utils/responsive_size.dart';
import '../common/custom_app_bar.dart';
import '../../views/common/custom_button.dart';
import '../../views/common/custom_text_field.dart';

class SalonOwnerSettingsScreen extends StatefulWidget {
  const SalonOwnerSettingsScreen({Key? key}) : super(key: key);

  @override
  State<SalonOwnerSettingsScreen> createState() =>
      _SalonOwnerSettingsScreenState();
}

class _SalonOwnerSettingsScreenState extends State<SalonOwnerSettingsScreen>
    with SingleTickerProviderStateMixin {
  // Controller'lar
  final AuthController _authController = Get.find<AuthController>();
  final SalonController _salonController = Get.find<SalonController>();

  // Tab controller
  late TabController _tabController;

  // Form anahtarları
  final GlobalKey<FormState> _salonInfoFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _settingsFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _smsFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  // Text controller'lar
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  // SMS Ayarları controller'ları
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _senderIdController = TextEditingController();
  final TextEditingController _appointmentConfirmationTemplateController =
      TextEditingController();
  final TextEditingController _appointmentReminderTemplateController =
      TextEditingController();
  final TextEditingController _appointmentCancelTemplateController =
      TextEditingController();

  // Şifre değiştirme controller'ları
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Salon ayarları
  final RxBool _allowOnlineBooking = true.obs;
  final RxInt _defaultAppointmentDuration = 30.obs;
  final RxInt _minimumNoticeTime = 60.obs;
  final Rx<int?> _cancelationTimeLimit = Rx<int?>(null);
  final RxBool _sendSmsReminders = true.obs;
  final RxInt _reminderTimeBeforeAppointment = 24.obs;
  final RxBool _requireCustomerEmail = true.obs;

  // SMS ayarları
  final RxBool _smsIsActive = false.obs;

  // Şifre görünürlüğü
  final RxBool _currentPasswordVisible = false.obs;
  final RxBool _newPasswordVisible = false.obs;
  final RxBool _confirmPasswordVisible = false.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSalonData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _apiKeyController.dispose();
    _senderIdController.dispose();
    _appointmentConfirmationTemplateController.dispose();
    _appointmentReminderTemplateController.dispose();
    _appointmentCancelTemplateController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Salon verilerini yükle
  Future<void> _loadSalonData() async {
    await _salonController.loadSalon();

    if (_salonController.salon.value != null) {
      final salon = _salonController.salon.value!;

      // Salon bilgileri
      _nameController.text = salon.name;
      _addressController.text = salon.address ?? '';
      _phoneController.text = salon.phone ?? '';
      _emailController.text = salon.email ?? '';
      _websiteController.text = salon.website ?? '';

      // Salon ayarları
      _allowOnlineBooking.value = salon.settings.allowOnlineBooking;
      _defaultAppointmentDuration.value =
          salon.settings.defaultAppointmentDuration;
      _minimumNoticeTime.value = salon.settings.minimumNoticeTime;
      _cancelationTimeLimit.value = salon.settings.cancelationTimeLimit;
      _sendSmsReminders.value = salon.settings.sendSmsReminders;
      _reminderTimeBeforeAppointment.value =
          salon.settings.reminderTimeBeforeAppointment;
      _requireCustomerEmail.value = salon.settings.requireCustomerEmail;

      // SMS ayarları
      _smsIsActive.value = salon.smsSettings.isActive;
      _apiKeyController.text = salon.smsSettings.apiKey ?? '';
      _senderIdController.text = salon.smsSettings.senderId ?? '';
      _appointmentConfirmationTemplateController.text =
          salon.smsSettings.appointmentConfirmationTemplate ?? '';
      _appointmentReminderTemplateController.text =
          salon.smsSettings.appointmentReminderTemplate ?? '';
      _appointmentCancelTemplateController.text =
          salon.smsSettings.appointmentCancelTemplate ?? '';
    }
  }

  // Salon bilgilerini güncelle
  Future<void> _updateSalonInfo() async {
    if (_salonInfoFormKey.currentState?.validate() ?? false) {
      final Map<String, dynamic> data = {
        'name': _nameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'website': _websiteController.text,
      };

      final success = await _salonController.updateSalon(data);

      if (success) {
        Get.snackbar(
          'Başarılı',
          'Salon bilgileri güncellendi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Hata',
          'Salon bilgileri güncellenirken bir hata oluştu',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  // Salon ayarlarını güncelle
  Future<void> _updateSalonSettings() async {
    if (_settingsFormKey.currentState?.validate() ?? false) {
      final SalonSettings settings = SalonSettings(
        allowOnlineBooking: _allowOnlineBooking.value,
        defaultAppointmentDuration: _defaultAppointmentDuration.value,
        minimumNoticeTime: _minimumNoticeTime.value,
        cancelationTimeLimit: _cancelationTimeLimit.value,
        sendSmsReminders: _sendSmsReminders.value,
        reminderTimeBeforeAppointment: _reminderTimeBeforeAppointment.value,
        requireCustomerEmail: _requireCustomerEmail.value,
      );

      final success = await _salonController.updateSalonSettings(settings);

      if (success) {
        Get.snackbar(
          'Başarılı',
          'Salon ayarları güncellendi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Hata',
          'Salon ayarları güncellenirken bir hata oluştu',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  // SMS ayarlarını güncelle
  Future<void> _updateSmsSettings() async {
    if (_smsFormKey.currentState?.validate() ?? false) {
      final SmsSettings smsSettings = SmsSettings(
        isActive: _smsIsActive.value,
        apiKey: _apiKeyController.text,
        senderId: _senderIdController.text,
        appointmentConfirmationTemplate:
            _appointmentConfirmationTemplateController.text,
        appointmentReminderTemplate:
            _appointmentReminderTemplateController.text,
        appointmentCancelTemplate: _appointmentCancelTemplateController.text,
      );

      final success = await _salonController.updateSmsSettings(smsSettings);

      if (success) {
        Get.snackbar(
          'Başarılı',
          'SMS ayarları güncellendi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Hata',
          'SMS ayarları güncellenirken bir hata oluştu',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  // Şifre değiştir
  Future<void> _changePassword() async {
    if (_passwordFormKey.currentState?.validate() ?? false) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        Get.snackbar(
          'Hata',
          'Yeni şifreler eşleşmiyor',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      // API entegrasyonu yapılacak - Örnek olarak başarılı gösterildi
      Get.snackbar(
        'Başarılı',
        'Şifreniz başarıyla değiştirildi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.8),
        colorText: Colors.white,
      );

      // Formu temizle
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  // Çıkış yap
  Future<void> _logout() async {
    final bool confirm =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Çıkış Yap'),
            content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('İptal'),
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
      appBar: const CustomAppBar(title: 'Salon Ayarları'),
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
                  Tab(text: 'Salon Bilgileri'),
                  Tab(text: 'Salon Ayarları'),
                  Tab(text: 'SMS Ayarları'),
                ],
              ),
            ),

            // Tab içerikleri
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Salon Bilgileri
                  _buildSalonInfoTab(),

                  // Salon Ayarları
                  _buildSalonSettingsTab(),

                  // SMS Ayarları
                  _buildSmsSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),

      // Şifre değiştirme ve çıkış butonları (Alt kısımda)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
            Expanded(
              child: CustomButton(
                text: 'Şifre Değiştir',
                type: ButtonType.outlined,
                onPressed: () {
                  _showChangePasswordModal();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: 'Çıkış Yap',
                type: ButtonType.primary,
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Salon Bilgileri Tab
  Widget _buildSalonInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        if (_salonController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Form(
          key: _salonInfoFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Açıklama
              Text(
                'Salon bilgilerinizi güncelleyin',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Salon adı
              CustomTextField(
                label: 'Salon Adı',
                hint: 'Salonunuzun adı',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Salon adı boş olamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Adres
              CustomTextField(
                label: 'Adres',
                hint: 'Salonunuzun adresi',
                controller: _addressController,
                isMultiline: true,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Telefon
              CustomTextField(
                label: 'Telefon',
                hint: 'Salonunuzun telefon numarası',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(
                      r'^\d{10,11}$',
                    ).hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
                      return 'Geçerli bir telefon numarası girin';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // E-posta
              CustomTextField(
                label: 'E-posta',
                hint: 'Salonunuzun e-posta adresi',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Web sitesi
              CustomTextField(
                label: 'Web Sitesi',
                hint: 'Salonunuzun web sitesi (opsiyonel)',
                controller: _websiteController,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 32),

              // Kaydet butonu
              CustomButton(
                text: 'Salon Bilgilerini Güncelle',
                type: ButtonType.primary,
                onPressed: _updateSalonInfo,
                isLoading: _salonController.isUpdating.value,
              ),
            ],
          ),
        );
      }),
    );
  }

  // Salon Ayarları Tab
  Widget _buildSalonSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        if (_salonController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Form(
          key: _settingsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Açıklama
              Text(
                'Salon çalışma ve randevu ayarlarını güncelleyin',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Online randevu
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Randevu Ayarları', style: AppTextStyles.heading4),
                      const SizedBox(height: 16),

                      // Online randevu aktif/pasif
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Online Randevu Alma',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          Switch(
                            value: _allowOnlineBooking.value,
                            onChanged: (value) {
                              _allowOnlineBooking.value = value;
                            },
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                      const Divider(),

                      // Varsayılan randevu süresi
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Varsayılan Randevu Süresi (dk)',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: DropdownButtonFormField<int>(
                              isExpanded: true,
                              value: _defaultAppointmentDuration.value,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items:
                                  [15, 30, 45, 60, 90, 120].map((int value) {
                                    return DropdownMenuItem<int>(
                                      value: value,
                                      child: Text('$value dk'),
                                    );
                                  }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  _defaultAppointmentDuration.value = newValue;
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(),

                      // Minimum randevu öncesi bildirim süresi
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Minimum Bildirim Süresi (dk)',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: DropdownButtonFormField<int>(
                              isExpanded: true,
                              value: _minimumNoticeTime.value,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items:
                                  [30, 60, 120, 180, 240, 360, 720, 1440].map((
                                    int value,
                                  ) {
                                    return DropdownMenuItem<int>(
                                      value: value,
                                      child: Text('$value dk'),
                                    );
                                  }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  _minimumNoticeTime.value = newValue;
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(),

                      // İptal süre sınırı
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'İptal Süre Sınırı (saat)',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: DropdownButtonFormField<int?>(
                              isExpanded: true,
                              value: _cancelationTimeLimit.value,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('Sınır yok'),
                                ),
                                ...[1, 2, 3, 6, 12, 24, 48].map((int value) {
                                  return DropdownMenuItem<int?>(
                                    value: value,
                                    child: Text('$value saat'),
                                  );
                                }),
                              ],
                              onChanged: (newValue) {
                                _cancelationTimeLimit.value = newValue;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bildirim ayarları
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bildirim Ayarları', style: AppTextStyles.heading4),
                      const SizedBox(height: 16),

                      // SMS hatırlatması
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'SMS ile Randevu Hatırlatması',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          Switch(
                            value: _sendSmsReminders.value,
                            onChanged: (value) {
                              _sendSmsReminders.value = value;
                            },
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                      const Divider(),

                      // Hatırlatma zamanı
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Hatırlatma Zamanı (randevudan önce)',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: DropdownButtonFormField<int>(
                              isExpanded: true,
                              value: _reminderTimeBeforeAppointment.value,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items:
                                  [1, 2, 3, 6, 12, 24, 48].map((int value) {
                                    return DropdownMenuItem<int>(
                                      value: value,
                                      child: Text('$value saat'),
                                    );
                                  }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  _reminderTimeBeforeAppointment.value =
                                      newValue;
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Müşteri ayarları
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Müşteri Ayarları', style: AppTextStyles.heading4),
                      const SizedBox(height: 16),

                      // E-posta zorunluluğu
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'E-posta Adresi Zorunlu',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          Switch(
                            value: _requireCustomerEmail.value,
                            onChanged: (value) {
                              _requireCustomerEmail.value = value;
                            },
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Kaydet butonu
              CustomButton(
                text: 'Salon Ayarlarını Güncelle',
                type: ButtonType.primary,
                onPressed: _updateSalonSettings,
                isLoading: _salonController.isUpdating.value,
              ),
            ],
          ),
        );
      }),
    );
  }

  // SMS Ayarları Tab
  Widget _buildSmsSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        if (_salonController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Form(
          key: _smsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Açıklama
              Text(
                'SMS entegrasyonu ayarlarını yapılandırın',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Ana SMS Ayarları
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SMS Servisi', style: AppTextStyles.heading4),
                      const SizedBox(height: 16),

                      // SMS aktif/pasif
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'SMS Hizmeti Aktif',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          Switch(
                            value: _smsIsActive.value,
                            onChanged: (value) {
                              _smsIsActive.value = value;
                            },
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                      const Divider(),

                      // API Key
                      CustomTextField(
                        label: 'API Key',
                        hint:
                            'SMS servis sağlayıcınızdan aldığınız API anahtarı',
                        controller: _apiKeyController,
                        enabled: _smsIsActive.value,
                      ),
                      const SizedBox(height: 16),

                      // Sender ID
                      CustomTextField(
                        label: 'Gönderici ID',
                        hint:
                            'SMS servis sağlayıcınızdan aldığınız gönderici kimliği',
                        controller: _senderIdController,
                        enabled: _smsIsActive.value,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // SMS Şablonları
              if (_smsIsActive.value) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SMS Şablonları', style: AppTextStyles.heading4),
                        const SizedBox(height: 8),
                        Text(
                          'Kullanılabilir değişkenler: {ad}, {tarih}, {saat}, {kuafor}, {salon}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Onay şablonu
                        CustomTextField(
                          label: 'Randevu Onay Şablonu',
                          hint:
                              'Randevu onaylandığında gönderilecek SMS şablonu',
                          controller:
                              _appointmentConfirmationTemplateController,
                          isMultiline: true,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // Hatırlatma şablonu
                        CustomTextField(
                          label: 'Randevu Hatırlatma Şablonu',
                          hint:
                              'Randevu hatırlatması için gönderilecek SMS şablonu',
                          controller: _appointmentReminderTemplateController,
                          isMultiline: true,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // İptal şablonu
                        CustomTextField(
                          label: 'Randevu İptal Şablonu',
                          hint:
                              'Randevu iptal edildiğinde gönderilecek SMS şablonu',
                          controller: _appointmentCancelTemplateController,
                          isMultiline: true,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Kaydet butonu
              CustomButton(
                text: 'SMS Ayarlarını Güncelle',
                type: ButtonType.primary,
                onPressed: _updateSmsSettings,
                isLoading: _salonController.isUpdating.value,
              ),
            ],
          ),
        );
      }),
    );
  }

  // Şifre değiştirme modalı
  void _showChangePasswordModal() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _passwordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Şifre Değiştir', style: AppTextStyles.heading3),
                const SizedBox(height: 24),

                // Mevcut şifre
                Obx(
                  () => CustomTextField(
                    label: 'Mevcut Şifre',
                    hint: 'Mevcut şifrenizi girin',
                    controller: _currentPasswordController,
                    obscureText: !_currentPasswordVisible.value,
                    suffixIcon:
                        _currentPasswordVisible.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                    onSuffixIconPressed: () {
                      _currentPasswordVisible.value =
                          !_currentPasswordVisible.value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Mevcut şifre gerekli';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Yeni şifre
                Obx(
                  () => CustomTextField(
                    label: 'Yeni Şifre',
                    hint: 'Yeni şifrenizi girin',
                    controller: _newPasswordController,
                    obscureText: !_newPasswordVisible.value,
                    suffixIcon:
                        _newPasswordVisible.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                    onSuffixIconPressed: () {
                      _newPasswordVisible.value = !_newPasswordVisible.value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Yeni şifre gerekli';
                      }
                      if (value.length < 6) {
                        return 'Şifre en az 6 karakter olmalı';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Şifre tekrar
                Obx(
                  () => CustomTextField(
                    label: 'Yeni Şifre (Tekrar)',
                    hint: 'Yeni şifrenizi tekrar girin',
                    controller: _confirmPasswordController,
                    obscureText: !_confirmPasswordVisible.value,
                    suffixIcon:
                        _confirmPasswordVisible.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                    onSuffixIconPressed: () {
                      _confirmPasswordVisible.value =
                          !_confirmPasswordVisible.value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre tekrarı gerekli';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Şifreler eşleşmiyor';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'İptal',
                        type: ButtonType.outlined,
                        onPressed: () {
                          Get.back();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: 'Şifre Değiştir',
                        type: ButtonType.primary,
                        onPressed: () {
                          if (_passwordFormKey.currentState!.validate()) {
                            _changePassword();
                            Get.back();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
