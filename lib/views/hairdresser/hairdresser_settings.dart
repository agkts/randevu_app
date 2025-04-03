import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/hairdresser_controller.dart';
import '../../routes/app_routes.dart';
import '../../utils/responsive_size.dart';
import '../common/custom_app_bar.dart';
import '../../views/common/custom_button.dart';
import '../../views/common/custom_text_field.dart';

class HairdresserSettingsScreen extends StatefulWidget {
  const HairdresserSettingsScreen({Key? key}) : super(key: key);

  @override
  State<HairdresserSettingsScreen> createState() =>
      _HairdresserSettingsScreenState();
}

class _HairdresserSettingsScreenState extends State<HairdresserSettingsScreen> {
  // Controller'lar
  final AuthController _authController = Get.find<AuthController>();
  final HairdresserController _hairdresserController =
      Get.find<HairdresserController>();

  // Form kontrolcüleri
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Form anahtarı
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Şifre değiştirme göster/gizle
  final RxBool _showChangePassword = false.obs;

  // Şifre görünürlüğü
  final RxBool _passwordVisible = false.obs;
  final RxBool _confirmPasswordVisible = false.obs;

  @override
  void initState() {
    super.initState();
    _loadHairdresserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Kuaför verilerini yükle
  Future<void> _loadHairdresserData() async {
    await _hairdresserController.loadCurrentHairdresser();

    if (_hairdresserController.currentHairdresser.value != null) {
      final hairdresser = _hairdresserController.currentHairdresser.value!;

      _nameController.text = hairdresser.name;
      _emailController.text = hairdresser.email ?? '';
      _phoneController.text = hairdresser.phone ?? '';
    }
  }

  // Profil bilgilerini güncelle
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final Map<String, dynamic> data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
    };

    // Şifre değişikliği isteniyorsa ekle
    if (_showChangePassword.value &&
        _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text) {
      data['password'] = _passwordController.text;
    }

    if (_hairdresserController.currentHairdresser.value != null) {
      final success = await _hairdresserController.updateHairdresser(
        _hairdresserController.currentHairdresser.value!.id,
        data,
      );

      if (success) {
        Get.snackbar(
          'Başarılı',
          'Profil bilgileri güncellendi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.8),
          colorText: Colors.white,
        );

        // Şifre alanlarını temizle
        _passwordController.clear();
        _confirmPasswordController.clear();
        _showChangePassword.value = false;
      } else {
        Get.snackbar(
          'Hata',
          'Profil güncellenirken bir hata oluştu',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  // Çıkış yapma
  Future<void> _logout() async {
    final bool confirm =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Çıkış Yap'),
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
      Get.offAllNamed(AppRoutes.hairdresserLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Ayarlar'),
      body: SafeArea(
        child: Obx(() {
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

          final hairdresser = _hairdresserController.currentHairdresser.value!;

          return SingleChildScrollView(
            padding: Responsive.pagePadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil bölümü
                  Text('Profil Bilgileri', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  Text(
                    'Kişisel bilgilerinizi buradan güncelleyebilirsiniz.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profil kartı
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ad Soyad
                          CustomTextField(
                            label: 'Ad Soyad',
                            hint: 'Adınız ve soyadınız',
                            controller: _nameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ad soyad boş olamaz';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // E-posta
                          CustomTextField(
                            label: 'E-posta',
                            hint: 'E-posta adresiniz',
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

                          // Telefon
                          CustomTextField(
                            label: 'Telefon',
                            hint: 'Telefon numaranız',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (!RegExp(r'^\d{10,11}$').hasMatch(
                                  value.replaceAll(RegExp(r'\D'), ''),
                                )) {
                                  return 'Geçerli bir telefon numarası girin';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Şifre değiştirme bölümü göster/gizle
                          GestureDetector(
                            onTap: () {
                              _showChangePassword.value =
                                  !_showChangePassword.value;
                            },
                            child: Row(
                              children: [
                                Icon(
                                  _showChangePassword.value
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Şifre Değiştir',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Şifre değiştirme bölümü
                          if (_showChangePassword.value) ...[
                            const SizedBox(height: 16),

                            // Yeni şifre
                            Obx(() {
                              return CustomTextField(
                                label: 'Yeni Şifre',
                                hint: 'Yeni şifreniz',
                                controller: _passwordController,
                                obscureText: !_passwordVisible.value,
                                suffixIcon:
                                    _passwordVisible.value
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                onSuffixIconPressed: () {
                                  _passwordVisible.value =
                                      !_passwordVisible.value;
                                },
                                validator: (value) {
                                  if (_showChangePassword.value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Şifre boş olamaz';
                                    }
                                    if (value.length < 6) {
                                      return 'Şifre en az 6 karakter olmalı';
                                    }
                                  }
                                  return null;
                                },
                              );
                            }),
                            const SizedBox(height: 16),

                            // Şifre tekrar
                            Obx(() {
                              return CustomTextField(
                                label: 'Şifre Tekrar',
                                hint: 'Şifrenizi tekrar girin',
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
                                  if (_showChangePassword.value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Şifre tekrarı boş olamaz';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Şifreler eşleşmiyor';
                                    }
                                  }
                                  return null;
                                },
                              );
                            }),
                          ],

                          const SizedBox(height: 24),

                          // Kaydet butonu
                          CustomButton(
                            text: 'Profili Güncelle',
                            type: ButtonType.primary,
                            onPressed: _updateProfile,
                            isLoading: _hairdresserController.isUpdating.value,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Diğer ayarlar bölümü
                  Text('Diğer Ayarlar', style: AppTextStyles.heading3),
                  const SizedBox(height: 24),

                  // Diğer ayarlar listesi
                  Card(
                    child: Column(
                      children: [
                        // Çalışma Saatleri
                        ListTile(
                          leading: const Icon(
                            Icons.schedule,
                            color: AppColors.primary,
                          ),
                          title: const Text('Çalışma Saatleri'),
                          subtitle: const Text(
                            'Çalışma günleri ve saatlerinizi ayarlayın',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Get.toNamed(AppRoutes.hairdresserSchedule);
                          },
                        ),
                        const Divider(height: 1),

                        // Müşteriler
                        ListTile(
                          leading: const Icon(
                            Icons.people,
                            color: AppColors.primary,
                          ),
                          title: const Text('Müşterilerim'),
                          subtitle: const Text(
                            'Müşteri listesi ve notlarınızı görüntüleyin',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Get.toNamed(AppRoutes.hairdresserCustomers);
                          },
                        ),
                        const Divider(height: 1),

                        // Hakkında
                        ListTile(
                          leading: const Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                          ),
                          title: const Text('Hakkında'),
                          subtitle: const Text(
                            'Uygulama bilgileri ve yasal bilgiler',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            // Hakkında sayfasına git
                          },
                        ),
                        const Divider(height: 1),

                        // Çıkış Yap
                        ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: AppColors.error,
                          ),
                          title: const Text(
                            'Çıkış Yap',
                            style: TextStyle(color: AppColors.error),
                          ),
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Uygulama versiyonu
                  Center(
                    child: Text(
                      'Uygulama Versiyonu: 1.0.0',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
