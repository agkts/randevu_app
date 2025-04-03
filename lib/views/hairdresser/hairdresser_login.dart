import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../utils/responsive_size.dart';
import '../../views/common/custom_button.dart';
import '../../views/common/custom_text_field.dart';

class HairdresserLoginScreen extends StatefulWidget {
  const HairdresserLoginScreen({Key? key}) : super(key: key);

  @override
  State<HairdresserLoginScreen> createState() => _HairdresserLoginScreenState();
}

class _HairdresserLoginScreenState extends State<HairdresserLoginScreen> {
  // Controller
  final AuthController _authController = Get.find<AuthController>();

  // Text controller'lar
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Form anahtarı
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Şifre görünürlüğü
  final RxBool isPasswordVisible = false.obs;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Giriş yapma
  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();

      final String username = _usernameController.text.trim();
      final String password = _passwordController.text;

      final bool success = await _authController.login(username, password);

      if (success) {
        if (_authController.isHairdresser) {
          Get.offAllNamed(AppRoutes.hairdresserDashboard);
        } else if (_authController.isSalonOwner) {
          Get.offAllNamed(AppRoutes.salonOwnerDashboard);
        } else {
          Get.snackbar(
            'Hata',
            'Giriş başarılı ancak rol belirlenemedi',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error.withOpacity(0.8),
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Hata',
          'Kullanıcı adı veya şifre hatalı',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: Responsive.pagePadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.formWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'R',
                          style: AppTextStyles.heading1.copyWith(
                            fontSize: 60,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Başlık
                    Text('Randevu App', style: AppTextStyles.heading2),
                    const SizedBox(height: 8),
                    Text(
                      'Kuaför ve Salon Sahibi Girişi',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Kullanıcı adı
                    CustomTextField(
                      label: 'Kullanıcı Adı',
                      hint: 'Kullanıcı adınızı girin',
                      controller: _usernameController,
                      prefixIcon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen kullanıcı adınızı girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Şifre
                    Obx(() {
                      return CustomTextField(
                        label: 'Şifre',
                        hint: 'Şifrenizi girin',
                        controller: _passwordController,
                        prefixIcon: Icons.lock,
                        obscureText: !isPasswordVisible.value,
                        suffixIcon:
                            isPasswordVisible.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                        onSuffixIconPressed: () {
                          isPasswordVisible.value = !isPasswordVisible.value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen şifrenizi girin';
                          }
                          return null;
                        },
                      );
                    }),
                    const SizedBox(height: 32),

                    // Giriş butonu
                    Obx(() {
                      return CustomButton(
                        text: 'Giriş Yap',
                        type: ButtonType.primary,
                        onPressed: _login,
                        isLoading: _authController.isLoading.value,
                      );
                    }),
                    const SizedBox(height: 24),

                    // Müşteri sayfasına yönlendirme
                    TextButton(
                      onPressed: () {
                        Get.offAllNamed(AppRoutes.customerAppointmentBooking);
                      },
                      child: Text(
                        'Müşteri Randevu Sayfasına Dön',
                        style: AppTextStyles.link,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
