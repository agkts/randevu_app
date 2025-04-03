import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/service_controller.dart';
import '../../models/service.dart';
import '../../utils/responsive_size.dart';
import '../../views/common/custom_app_bar.dart';
import '../../views/common/custom_button.dart';
import '../../views/common/custom_text_field.dart';

class SalonOwnerServicesScreen extends StatefulWidget {
  const SalonOwnerServicesScreen({Key? key}) : super(key: key);

  @override
  State<SalonOwnerServicesScreen> createState() =>
      _SalonOwnerServicesScreenState();
}

class _SalonOwnerServicesScreenState extends State<SalonOwnerServicesScreen> {
  // Controller
  final ServiceController _serviceController = Get.find<ServiceController>();

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
    await _serviceController.loadServices();
  }

  // Hizmet ekle modal
  void _showAddServiceModal() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController durationController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

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
                Text('Yeni Hizmet Ekle', style: AppTextStyles.heading3),
                const SizedBox(height: 24),

                // Hizmet adı
                CustomTextField(
                  label: 'Hizmet Adı',
                  hint: 'Hizmetin adını girin',
                  controller: nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Hizmet adı boş olamaz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Fiyat
                CustomTextField(
                  label: 'Fiyat (₺)',
                  hint: 'Hizmetin fiyatını girin',
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Fiyat boş olamaz';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Geçerli bir fiyat girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Süre
                CustomTextField(
                  label: 'Süre (Dakika)',
                  hint: 'Hizmetin süresini dakika olarak girin',
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Süre boş olamaz';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Geçerli bir süre girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Açıklama
                CustomTextField(
                  label: 'Açıklama (Opsiyonel)',
                  hint: 'Hizmet hakkında açıklama',
                  controller: descriptionController,
                  isMultiline: true,
                  maxLines: 3,
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
                                'price': double.parse(priceController.text),
                                'duration_minutes': int.parse(
                                  durationController.text,
                                ),
                                'description': descriptionController.text,
                                'is_active': true,
                              };

                              final success = await _serviceController
                                  .createService(data);

                              if (success) {
                                Get.back();
                                Get.snackbar(
                                  'Başarılı',
                                  'Hizmet başarıyla eklendi',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.success
                                      .withOpacity(0.8),
                                  colorText: Colors.white,
                                );
                              } else {
                                Get.snackbar(
                                  'Hata',
                                  'Hizmet eklenirken bir hata oluştu',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.error.withOpacity(
                                    0.8,
                                  ),
                                  colorText: Colors.white,
                                );
                              }
                            }
                          },
                          isLoading: _serviceController.isCreating.value,
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

  // Hizmet düzenle modal
  void _showEditServiceModal(Service service) {
    final TextEditingController nameController = TextEditingController(
      text: service.name,
    );
    final TextEditingController priceController = TextEditingController(
      text: service.price.toString(),
    );
    final TextEditingController durationController = TextEditingController(
      text: service.durationMinutes.toString(),
    );
    final TextEditingController descriptionController = TextEditingController(
      text: service.description ?? '',
    );

    final RxBool isActive = service.isActive.obs;
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
                Text('Hizmet Düzenle', style: AppTextStyles.heading3),
                const SizedBox(height: 24),

                // Hizmet adı
                CustomTextField(
                  label: 'Hizmet Adı',
                  hint: 'Hizmetin adını girin',
                  controller: nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Hizmet adı boş olamaz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Fiyat
                CustomTextField(
                  label: 'Fiyat (₺)',
                  hint: 'Hizmetin fiyatını girin',
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Fiyat boş olamaz';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Geçerli bir fiyat girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Süre
                CustomTextField(
                  label: 'Süre (Dakika)',
                  hint: 'Hizmetin süresini dakika olarak girin',
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Süre boş olamaz';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Geçerli bir süre girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Açıklama
                CustomTextField(
                  label: 'Açıklama (Opsiyonel)',
                  hint: 'Hizmet hakkında açıklama',
                  controller: descriptionController,
                  isMultiline: true,
                  maxLines: 3,
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

                // Güncelle butonu
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
                                'price': double.parse(priceController.text),
                                'duration_minutes': int.parse(
                                  durationController.text,
                                ),
                                'description': descriptionController.text,
                                'is_active': isActive.value,
                              };

                              final success = await _serviceController
                                  .updateService(service.id, data);

                              if (success) {
                                Get.back();
                                Get.snackbar(
                                  'Başarılı',
                                  'Hizmet bilgileri güncellendi',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.success
                                      .withOpacity(0.8),
                                  colorText: Colors.white,
                                );
                              } else {
                                Get.snackbar(
                                  'Hata',
                                  'Hizmet güncellenirken bir hata oluştu',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.error.withOpacity(
                                    0.8,
                                  ),
                                  colorText: Colors.white,
                                );
                              }
                            }
                          },
                          isLoading: _serviceController.isUpdating.value,
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

  // Hizmet sil
  Future<void> _deleteService(Service service) async {
    final bool confirm =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Hizmet Sil'),
            content: Text(
              '${service.name} isimli hizmeti silmek istediğinize emin misiniz?',
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
      final success = await _serviceController.deleteService(service.id);

      if (success) {
        Get.snackbar(
          'Başarılı',
          'Hizmet başarıyla silindi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Hata',
          'Hizmet silinirken bir hata oluştu',
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
      appBar: const CustomAppBar(title: 'Hizmetler'),
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
                    hint: 'Hizmet ara...',
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
                              'Sadece aktif hizmetleri göster',
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

            // Hizmet listesi
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: Obx(() {
                  if (_serviceController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Filtreleme
                  final List<Service> filteredServices =
                      _serviceController.services.where((service) {
                        // Arama filtreleme
                        final bool matchesSearch =
                            _searchQuery.value.isEmpty ||
                            service.name.toLowerCase().contains(
                              _searchQuery.value.toLowerCase(),
                            );

                        // Aktif filtreleme
                        final bool matchesActiveFilter =
                            !_showOnlyActive.value || service.isActive;

                        return matchesSearch && matchesActiveFilter;
                      }).toList();

                  if (filteredServices.isEmpty) {
                    return Center(
                      child: Text(
                        'Hizmet bulunamadı',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredServices.length,
                    itemBuilder: (context, index) {
                      final service = filteredServices[index];
                      return _buildServiceCard(service);
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddServiceModal,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Hizmet kartı
  Widget _buildServiceCard(Service service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Hizmet ikonu
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.spa, color: AppColors.primary, size: 24),
                  ),
                ),
                const SizedBox(width: 16),

                // Hizmet adı ve fiyatı
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Süre
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
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

                // Fiyat ve durum
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Fiyat
                    Text(
                      service.formattedPrice,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Durum
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            service.isActive
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        service.isActive ? 'Aktif' : 'Pasif',
                        style: AppTextStyles.bodySmall.copyWith(
                          color:
                              service.isActive
                                  ? AppColors.success
                                  : AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Açıklama
            if (service.description != null &&
                service.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Açıklama:',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                service.description!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            // İşlem butonları
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Sil butonu
                TextButton.icon(
                  onPressed: () => _deleteService(service),
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
                  onPressed: () => _showEditServiceModal(service),
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
