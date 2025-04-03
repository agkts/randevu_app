import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../controllers/appointment_controller.dart';
import '../../models/appointment.dart';
import '../../utils/responsive_size.dart';
import '../common/custom_app_bar.dart';
import '../../views/common/custom_text_field.dart';

class HairdresserCustomersScreen extends StatefulWidget {
  const HairdresserCustomersScreen({Key? key}) : super(key: key);

  @override
  State<HairdresserCustomersScreen> createState() =>
      _HairdresserCustomersScreenState();
}

class _HairdresserCustomersScreenState
    extends State<HairdresserCustomersScreen> {
  // Controller
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();

  // Arama kontrolcüsü
  final TextEditingController _searchController = TextEditingController();

  // Filtreleme değişkenleri
  final RxString _searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    _loadCustomers();

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

  // Müşterileri yükle (aslında tüm randevuları yükler ve gruplar)
  Future<void> _loadCustomers() async {
    await _appointmentController.loadAppointments();
  }

  // Müşterileri grupla (randevulardan)
  Map<String, List<Appointment>> _groupCustomers() {
    final Map<String, List<Appointment>> groupedCustomers = {};

    for (final appointment in _appointmentController.appointments) {
      final String customerKey =
          '${appointment.customerName}_${appointment.customerPhone}';

      if (!groupedCustomers.containsKey(customerKey)) {
        groupedCustomers[customerKey] = [];
      }

      groupedCustomers[customerKey]!.add(appointment);
    }

    return groupedCustomers;
  }

  // Filtrelenmiş müşterileri al
  Map<String, List<Appointment>> _getFilteredCustomers() {
    final Map<String, List<Appointment>> allCustomers = _groupCustomers();

    if (_searchQuery.value.isEmpty) {
      return allCustomers;
    }

    final Map<String, List<Appointment>> filteredCustomers = {};

    allCustomers.forEach((key, appointments) {
      final String customerName = appointments.first.customerName.toLowerCase();
      final String customerPhone =
          appointments.first.customerPhone.toLowerCase();
      final String query = _searchQuery.value.toLowerCase();

      if (customerName.contains(query) || customerPhone.contains(query)) {
        filteredCustomers[key] = appointments;
      }
    });

    return filteredCustomers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Müşterilerim'),
      body: SafeArea(
        child: Column(
          children: [
            // Arama alanı
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomTextField(
                label: '',
                hint: 'Müşteri adı veya telefon numarası...',
                controller: _searchController,
                prefixIcon: Icons.search,
                suffixIcon: Icons.clear,
                onSuffixIconPressed: () {
                  _searchController.clear();
                },
              ),
            ),

            // Müşteri listesi
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadCustomers,
                child: Obx(() {
                  if (_appointmentController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final Map<String, List<Appointment>> customers =
                      _getFilteredCustomers();

                  if (customers.isEmpty) {
                    return Center(
                      child: Text(
                        'Müşteri bulunamadı',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  final List<String> customerKeys = customers.keys.toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: customerKeys.length,
                    itemBuilder: (context, index) {
                      final String customerKey = customerKeys[index];
                      final List<Appointment> appointments =
                          customers[customerKey]!;

                      return _buildCustomerCard(appointments);
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Müşteri kartı
  Widget _buildCustomerCard(List<Appointment> appointments) {
    // Müşteri bilgileri (ilk randevudan al)
    final String customerName = appointments.first.customerName;
    final String customerPhone = appointments.first.customerPhone;
    final String customerEmail = appointments.first.customerEmail;

    // Randevuları tarihe göre sırala (en yeniden en eskiye)
    appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    // En son randevu
    final Appointment latestAppointment = appointments.first;

    // Tamamlanan randevu sayısı
    final int completedCount =
        appointments
            .where((a) => a.status == AppointmentStatus.completed)
            .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Müşteri adı ve bilgileri
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Müşteri avatarı
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      customerName.isNotEmpty
                          ? customerName[0].toUpperCase()
                          : 'M',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Müşteri bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerName, style: AppTextStyles.heading4),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            customerPhone,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.email,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            customerEmail,
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
            const Divider(height: 24),

            // Randevu istatistikleri
            Row(
              children: [
                // Toplam randevu sayısı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toplam Randevu',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${appointments.length}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tamamlanan randevu sayısı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tamamlanan',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedCount',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),

                // Son randevu tarihi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Son Randevu',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latestAppointment.formattedDate,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Detayları göster butonu
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _showCustomerDetails(appointments);
                },
                child: const Text('Detayları Göster'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Müşteri detayları modalı
  void _showCustomerDetails(List<Appointment> appointments) {
    final String customerName = appointments.first.customerName;

    Get.bottomSheet(
      Container(
        height: Responsive.height * 0.7,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '$customerName - Detaylar',
                    style: AppTextStyles.heading4,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // İçerik
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    // Tab bar
                    const TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      tabs: [
                        Tab(text: 'Randevu Geçmişi'),
                        Tab(text: 'Müşteri Notları'),
                      ],
                    ),

                    // Tab içeriği
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Randevu geçmişi
                          _buildAppointmentHistoryTab(appointments),

                          // Müşteri notları
                          _buildCustomerNotesTab(appointments.first),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Randevu geçmişi sekmesi
  Widget _buildAppointmentHistoryTab(List<Appointment> appointments) {
    // Randevuları tarihe göre sırala (en yeniden en eskiye)
    appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentHistoryItem(appointment);
      },
    );
  }

  // Randevu geçmişi öğesi
  Widget _buildAppointmentHistoryItem(Appointment appointment) {
    final DateFormat dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');
    final DateFormat timeFormat = DateFormat('HH:mm', 'tr_TR');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarih ve durum
            Row(
              children: [
                Icon(Icons.event, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${dateFormat.format(appointment.dateTime)} - ${timeFormat.format(appointment.dateTime)}',
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
            const SizedBox(height: 8),

            // Hizmetler
            if (appointment.serviceNames != null &&
                appointment.serviceNames!.isNotEmpty) ...[
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
              const SizedBox(height: 8),
            ],

            // Müşteri notu
            if (appointment.customerNote != null &&
                appointment.customerNote!.isNotEmpty) ...[
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
          ],
        ),
      ),
    );
  }

  // Müşteri notları sekmesi
  Widget _buildCustomerNotesTab(Appointment appointment) {
    final TextEditingController noteController = TextEditingController();

    // Örnek notlar (gerçek uygulamada veritabanından gelecek)
    final List<Map<String, dynamic>> notes = [
      {
        'date': DateTime.now().subtract(const Duration(days: 30)),
        'content': 'Müşteri saç modelini kısa ve modern tercih ediyor.',
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 90)),
        'content': 'Hassas saç derisine sahip, hafif şampuan kullanılmalı.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Not ekleme alanı
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yeni Not Ekle',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Müşteri hakkında not ekleyin...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    // Not ekleme işlemi
                    if (noteController.text.isNotEmpty) {
                      Get.snackbar(
                        'Başarılı',
                        'Not eklendi',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.success.withOpacity(0.8),
                        colorText: Colors.white,
                      );
                      noteController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Not Ekle'),
                ),
              ),
            ],
          ),
          const Divider(height: 32),

          // Mevcut notlar
          Text(
            'Mevcut Notlar',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Not listesi
          Expanded(
            child:
                notes.isEmpty
                    ? Center(
                      child: Text(
                        'Henüz not eklenmemiş',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        final DateTime date = note['date'];
                        final String content = note['content'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tarih
                                Row(
                                  children: [
                                    Icon(
                                      Icons.event_note,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat(
                                        'dd MMMM yyyy',
                                        'tr_TR',
                                      ).format(date),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () {
                                        // Not silme işlemi
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: AppColors.error,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Not içeriği
                                Text(content, style: AppTextStyles.bodyMedium),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
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
}
