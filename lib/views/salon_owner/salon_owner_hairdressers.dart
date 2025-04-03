import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/hairdresser_controller.dart';
import '../../models/hairdresser.dart';
import '../../utils/responsive_size.dart';
import '../../views/common/custom_app_bar.dart';
import '../../views/common/custom_button.dart';
import '../../views/common/custom_text_field.dart';

class SalonOwnerHairdressersScreen extends StatefulWidget {
  const SalonOwnerHairdressersScreen({Key? key}) : super(key: key);

  @override
  State<SalonOwnerHairdressersScreen> createState() =>
      _SalonOwnerHairdressersScreenState();
}

class _SalonOwnerHairdressersScreenState
    extends State<SalonOwnerHairdressersScreen> {
  // Controller
  final HairdresserController _hairdresserController =
      Get.find<HairdresserController>();

  // Arama kontrolcüsü
  final TextEditingController _searchController = TextEditingController();

  // Filtreleme değişkenleri
  final RxString _searchQuery = ''.obs;
  final RxBool _showOnlyActive = true.obs;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Arama değişikliklerini dinle
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Verileri yükle
  Future<void> _loadData() async {
    await _hairdresserController.loadHairdressers();
  }

  // Kuaför ekle modal
  void _showAddHairdresserModal() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Yeni Kuaför Ekle', style: AppTextStyles.heading3),
                const SizedBox(height: 24),

                // Ad Soyad
                CustomTextField(
                  label: 'Ad Soyad',
                  hint: 'Kuaförün adı ve soyadı',
                  controller: nameController,
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
                  hint: 'Kuaförün e-posta adresi',
                  controller: emailController,
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
                  hint: 'Kuaförün telefon numarası',
                  controller: phoneController,
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

                // Kullanıcı adı
                CustomTextField(
                  label: 'Kullanıcı Adı',
                  hint: 'Giriş için kullanıcı adı',
                  controller: usernameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kullanıcı adı boş olamaz';
                    }
                    if (value.length < 4) {
                      return 'Kullanıcı adı en az 4 karakter olmalı';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Şifre
                CustomTextField(
                  label: 'Şifre',
                  hint: 'Giriş için şifre',
                  controller: passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre boş olamaz';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Ekle butonu
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
                      child: Obx(() {
                        return CustomButton(
                          text: 'Ekle',
                          type: ButtonType.primary,
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final Map<String, dynamic> data = {
                                'name': nameController.text,
                                'email': emailController.text,
                                'phone': phoneController.text,
                                'username': usernameController.text,
                                'password': passwordController.text,
                                'is_active': true,
                              };

                              final success = await _hairdresserController
                                  .createHairdresser(data);

                              if (success) {
                                Get.back();
                                Get.snackbar(
                                  'Başarılı',
                                  'Kuaför başarıyla eklendi',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.success
                                      .withOpacity(0.8),
                                  colorText: Colors.white,
                                );
                              } else {
                                Get.snackbar(
                                  'Hata',
                                  'Kuaför eklenirken bir hata oluştu',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.error.withOpacity(
                                    0.8,
                                  ),
                                  colorText: Colors.white,
                                );
                              }
                            }
                          },
                          isLoading: _hairdresserController.isCreating.value,
                        );
                      }),
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

  // Kuaför düzenle modal
  void _showEditHairdresserModal(Hairdresser hairdresser) {
    final TextEditingController nameController = TextEditingController(
      text: hairdresser.name,
    );
    final TextEditingController emailController = TextEditingController(
      text: hairdresser.email,
    );
    final TextEditingController phoneController = TextEditingController(
      text: hairdresser.phone,
    );
    final TextEditingController passwordController = TextEditingController();

    final RxBool isActive = hairdresser.isActive.obs;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Kuaför Düzenle', style: AppTextStyles.heading3),
                const SizedBox(height: 24),

                // Ad Soyad
                CustomTextField(
                  label: 'Ad Soyad',
                  hint: 'Kuaförün adı ve soyadı',
                  controller: nameController,
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
                  hint: 'Kuaförün e-posta adresi',
                  controller: emailController,
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
                  hint: 'Kuaförün telefon numarası',
                  controller: phoneController,
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

                // Şifre (opsiyonel)
                CustomTextField(
                  label: 'Yeni Şifre (Opsiyonel)',
                  hint: 'Şifreyi değiştirmek için yeni şifre girin',
                  controller: passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Aktif/Pasif
                Row(
                  children: [
                    Text(
                      'Durum',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Obx(() {
                      return Switch(
                        value: isActive.value,
                        onChanged: (value) {
                          isActive.value = value;
                        },
                        activeColor: AppColors.primary,
                      );
                    }),
                    const SizedBox(width: 8),
                    Obx(() {
                      return Text(
                        isActive.value ? 'Aktif' : 'Pasif',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color:
                              isActive.value
                                  ? AppColors.success
                                  : AppColors.error,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),

                // Düzenle butonu
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
                      child: Obx(() {
                        return CustomButton(
                          text: 'Güncelle',
                          type: ButtonType.primary,
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final Map<String, dynamic> data = {
                                'name': nameController.text,
                                'email': emailController.text,
                                'phone': phoneController.text,
                                'is_active': isActive.value,
                              };

                              // Şifre değiştirilecekse ekle
                              if (passwordController.text.isNotEmpty) {
                                data['password'] = passwordController.text;
                              }

                              final success = await _hairdresserController
                                  .updateHairdresser(hairdresser.id, data);

                              if (success) {
                                Get.back();
                                Get.snackbar(
                                  'Başarılı',
                                  'Kuaför bilgileri güncellendi',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.success
                                      .withOpacity(0.8),
                                  colorText: Colors.white,
                                );
                              } else {
                                Get.snackbar(
                                  'Hata',
                                  'Kuaför güncellenirken bir hata oluştu',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.error.withOpacity(
                                    0.8,
                                  ),
                                  colorText: Colors.white,
                                );
                              }
                            }
                          },
                          isLoading: _hairdresserController.isUpdating.value,
                        );
                      }),
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

  // Kuaför sil
  Future<void> _deleteHairdresser(Hairdresser hairdresser) async {
    final bool confirm =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Kuaför Sil'),
            content: Text(
              '${hairdresser.name} isimli kuaförü silmek istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text(
                  'Sil',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      final success = await _hairdresserController.deleteHairdresser(
        hairdresser.id,
      );

      if (success) {
        Get.snackbar(
          'Başarılı',
          'Kuaför başarıyla silindi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Hata',
          'Kuaför silinirken bir hata oluştu',
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
      appBar: const CustomAppBar(title: 'Kuaförler'),
      body: SafeArea(
        child: Column(
          children: [
            // Arama ve filtre bölümü
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Arama alanı
                  CustomTextField(
                    label: '',
                    hint: 'Kuaför ara...',
                    controller: _searchController,
                    prefixIcon: Icons.search,
                    suffixIcon: Icons.clear,
                    onSuffixIconPressed: () {
                      _searchController.clear();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Filtre seçenekleri
                  Row(
                    children: [
                      // Sadece aktif olanları göster
                      Obx(() {
                        return Row(
                          children: [
                            Checkbox(
                              value: _showOnlyActive.value,
                              onChanged: (value) {
                                _showOnlyActive.value = value ?? true;
                              },
                              activeColor: AppColors.primary,
                            ),
                            Text(
                              'Sadece aktif kuaförleri göster',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            // Kuaför listesi
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: Obx(() {
                  if (_hairdresserController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Filtreleme
                  final List<Hairdresser> filteredHairdressers =
                      _hairdresserController.hairdressers.where((hairdresser) {
                        // Arama filtreleme
                        final bool matchesSearch =
                            _searchQuery.value.isEmpty ||
                            hairdresser.name.toLowerCase().contains(
                              _searchQuery.value.toLowerCase(),
                            );

                        // Aktif filtreleme
                        final bool matchesActiveFilter =
                            !_showOnlyActive.value || hairdresser.isActive;

                        return matchesSearch && matchesActiveFilter;
                      }).toList();

                  if (filteredHairdressers.isEmpty) {
                    return Center(
                      child: Text(
                        'Kuaför bulunamadı',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredHairdressers.length,
                    itemBuilder: (context, index) {
                      final hairdresser = filteredHairdressers[index];
                      return _buildHairdresserCard(hairdresser);
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHairdresserModal,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Kuaför kartı
  Widget _buildHairdresserCard(Hairdresser hairdresser) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kuaför avatarı
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      hairdresser.name.isNotEmpty
                          ? hairdresser.name[0].toUpperCase()
                          : 'K',
                      style: AppTextStyles.heading2.copyWith(
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

                      // Telefon
                      if (hairdresser.phone != null &&
                          hairdresser.phone!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hairdresser.phone!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),

                      // E-posta
                      if (hairdresser.email != null &&
                          hairdresser.email!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.email,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hairdresser.email!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
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

            // Kullanıcı adı
            if (hairdresser.username != null &&
                hairdresser.username!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Kullanıcı Adı: ',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    hairdresser.username!,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
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
                // Sil butonu
                TextButton.icon(
                  onPressed: () => _deleteHairdresser(hairdresser),
                  icon: const Icon(
                    Icons.delete,
                    color: AppColors.error,
                    size: 20,
                  ),
                  label: const Text(
                    'Sil',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(width: 8),

                // Düzenle butonu
                ElevatedButton.icon(
                  onPressed: () => _showEditHairdresserModal(hairdresser),
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                  label: const Text('Düzenle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
