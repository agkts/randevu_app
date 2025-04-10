/* import 'package:get/get.dart';
import 'package:randevu_app/controllers/auth_controller.dart';

// Ekranları import et
import '../views/splash_screen.dart';

// Müşteri Ekranları
import '../views/customer/customer_appointment_booking.dart';
import '../views/customer/customer_appointment_manage.dart';
import '../views/customer/customer_appointment_confirmation.dart';

// Kuaför Ekranları
import '../views/hairdresser/hairdresser_login.dart';
import '../views/hairdresser/hairdresser_dashboard.dart';
import '../views/hairdresser/hairdresser_appointments.dart';
import '../views/hairdresser/hairdresser_schedule.dart';
import '../views/hairdresser/hairdresser_customers.dart';
import '../views/hairdresser/hairdresser_settings.dart';

// Salon Sahibi Ekranları
import '../views/salon_owner/salon_owner_login.dart';
import '../views/salon_owner/salon_owner_dashboard.dart';
import '../views/salon_owner/salon_owner_hairdressers.dart';
import '../views/salon_owner/salon_owner_services.dart';
import '../views/salon_owner/salon_owner_appointments.dart';
import '../views/salon_owner/salon_owner_reports.dart';
import '../views/salon_owner/salon_owner_settings.dart';

class AppRoutes {
  // Rota sabitleri
  static const String splash = '/splash';

  // Müşteri rotaları
  static const String customerHome = '/customer/home';
  static const String customerAppointmentBooking =
      '/customer/appointment-booking';
  static const String customerAppointmentManage =
      '/customer/appointment-manage';
  static const String customerAppointmentConfirmation =
      '/customer/appointment-confirmation';

  // Kuaför rotaları
  static const String hairdresserLogin = '/hairdresser/login';
  static const String hairdresserDashboard = '/hairdresser/dashboard';
  static const String hairdresserAppointments = '/hairdresser/appointments';
  static const String hairdresserSchedule = '/hairdresser/schedule';
  static const String hairdresserCustomers = '/hairdresser/customers';
  static const String hairdresserSettings = '/hairdresser/settings';

  // Salon sahibi rotaları
  static const String salonOwnerLogin = '/salon-owner/login';
  static const String salonOwnerDashboard = '/salon-owner/dashboard';
  static const String salonOwnerHairdressers = '/salon-owner/hairdressers';
  static const String salonOwnerServices = '/salon-owner/services';
  static const String salonOwnerAppointments = '/salon-owner/appointments';
  static const String salonOwnerReports = '/salon-owner/reports';
  static const String salonOwnerSettings = '/salon-owner/settings';

  // Rota listesi
  static final routes = [
    // Başlangıç ekranı
    GetPage(name: splash, page: () => const SplashScreen()),

    // Müşteri ekranları
    GetPage(
      name: customerAppointmentBooking,
      page: () => const CustomerAppointmentBookingScreen(),
    ),
    GetPage(
      name: customerAppointmentManage,
      page: () => const CustomerAppointmentManageScreen(),
    ),
    GetPage(
      name: customerAppointmentConfirmation,
      page: () => const CustomerAppointmentConfirmationScreen(),
    ),

    // Kuaför ekranları
    GetPage(name: hairdresserLogin, page: () => const HairdresserLoginScreen()),
    GetPage(
      name: hairdresserDashboard,
      page: () => const HairdresserDashboardScreen(),
    ),
    GetPage(
      name: hairdresserAppointments,
      page: () => const HairdresserAppointmentsScreen(),
    ),
    GetPage(
      name: hairdresserSchedule,
      page: () => const HairdresserScheduleScreen(),
    ),
    GetPage(
      name: hairdresserCustomers,
      page: () => const HairdresserCustomersScreen(),
    ),
    GetPage(
      name: hairdresserSettings,
      page: () => const HairdresserSettingsScreen(),
    ),

    // Salon sahibi ekranları
    GetPage(name: salonOwnerLogin, page: () => const SalonOwnerLoginScreen()),
    GetPage(
      name: salonOwnerDashboard,
      page: () => const SalonOwnerDashboardScreen(),
    ),
    GetPage(
      name: salonOwnerHairdressers,
      page: () => const SalonOwnerHairdressersScreen(),
    ),
    GetPage(
      name: salonOwnerServices,
      page: () => const SalonOwnerServicesScreen(),
    ),
    GetPage(
      name: salonOwnerAppointments,
      page: () => const SalonOwnerAppointmentsScreen(),
    ),
    GetPage(
      name: salonOwnerReports,
      page: () => const SalonOwnerReportsScreen(),
    ),
    GetPage(
      name: salonOwnerSettings,
      page: () => const SalonOwnerSettingsScreen(),
    ),
  ];

  // Oturum durumuna göre başlangıç rotasını belirle
  static String determineInitialRoute() {
    final authController = Get.find<AuthController>();

    if (authController.isLoggedIn) {
      if (authController.isHairdresser) {
        return hairdresserDashboard;
      } else if (authController.isSalonOwner) {
        return salonOwnerDashboard;
      }
    }

    // Varsayılan olarak müşteri randevu ekranı
    return customerAppointmentBooking;
    //return salonOwnerDashboard;
  }
}
 */

import 'package:get/get.dart';

// Ekranları import et
import '../views/splash_screen.dart';

// Müşteri Ekranları
import '../views/customer/customer_appointment_booking.dart';
import '../views/customer/customer_appointment_manage.dart';
import '../views/customer/customer_appointment_confirmation.dart';

// Ortak Giriş Ekranı
import '../views/auth/login_screen.dart';

// Kuaför Ekranları
import '../views/hairdresser/hairdresser_dashboard.dart';
import '../views/hairdresser/hairdresser_appointments.dart';
import '../views/hairdresser/hairdresser_schedule.dart';
import '../views/hairdresser/hairdresser_customers.dart';
import '../views/hairdresser/hairdresser_settings.dart';

// Salon Sahibi Ekranları
import '../views/salon_owner/salon_owner_dashboard.dart';
import '../views/salon_owner/salon_owner_hairdressers.dart';
import '../views/salon_owner/salon_owner_services.dart';
import '../views/salon_owner/salon_owner_appointments.dart';
import '../views/salon_owner/salon_owner_reports.dart';
import '../views/salon_owner/salon_owner_settings.dart';

// Auth Controller
import '../controllers/auth_controller.dart';

class AppRoutes {
  // Rota sabitleri
  static const String splash = '/splash';

  // Giriş rotası
  static const String login = '/login';

  // Müşteri rotaları
  static const String customerHome = '/customer/home';
  static const String customerAppointmentBooking =
      '/customer/appointment-booking';
  static const String customerAppointmentManage =
      '/customer/appointment-manage';
  static const String customerAppointmentConfirmation =
      '/customer/appointment-confirmation';

  // Kuaför rotaları
  static const String hairdresserDashboard = '/hairdresser/dashboard';
  static const String hairdresserAppointments = '/hairdresser/appointments';
  static const String hairdresserSchedule = '/hairdresser/schedule';
  static const String hairdresserCustomers = '/hairdresser/customers';
  static const String hairdresserSettings = '/hairdresser/settings';

  // Salon sahibi rotaları
  static const String salonOwnerDashboard = '/salon-owner/dashboard';
  static const String salonOwnerHairdressers = '/salon-owner/hairdressers';
  static const String salonOwnerServices = '/salon-owner/services';
  static const String salonOwnerAppointments = '/salon-owner/appointments';
  static const String salonOwnerReports = '/salon-owner/reports';
  static const String salonOwnerSettings = '/salon-owner/settings';

  // Rota listesi
  static final routes = [
    // Başlangıç ekranı
    GetPage(name: splash, page: () => const SplashScreen()),

    // Giriş ekranı
    GetPage(name: login, page: () => const LoginScreen()),

    // Müşteri ekranları
    GetPage(
      name: customerAppointmentBooking,
      page: () => const CustomerAppointmentBookingScreen(),
    ),
    GetPage(
      name: customerAppointmentManage,
      page: () => const CustomerAppointmentManageScreen(),
    ),
    GetPage(
      name: customerAppointmentConfirmation,
      page: () => const CustomerAppointmentConfirmationScreen(),
    ),

    // Kuaför ekranları
    GetPage(
      name: hairdresserDashboard,
      page: () => const HairdresserDashboardScreen(),
    ),
    GetPage(
      name: hairdresserAppointments,
      page: () => const HairdresserAppointmentsScreen(),
    ),
    GetPage(
      name: hairdresserSchedule,
      page: () => const HairdresserScheduleScreen(),
    ),
    GetPage(
      name: hairdresserCustomers,
      page: () => const HairdresserCustomersScreen(),
    ),
    GetPage(
      name: hairdresserSettings,
      page: () => const HairdresserSettingsScreen(),
    ),

    // Salon sahibi ekranları
    GetPage(
      name: salonOwnerDashboard,
      page: () => const SalonOwnerDashboardScreen(),
    ),
    GetPage(
      name: salonOwnerHairdressers,
      page: () => const SalonOwnerHairdressersScreen(),
    ),
    GetPage(
      name: salonOwnerServices,
      page: () => const SalonOwnerServicesScreen(),
    ),
    GetPage(
      name: salonOwnerAppointments,
      page: () => const SalonOwnerAppointmentsScreen(),
    ),
    GetPage(
      name: salonOwnerReports,
      page: () => const SalonOwnerReportsScreen(),
    ),
    GetPage(
      name: salonOwnerSettings,
      page: () => const SalonOwnerSettingsScreen(),
    ),
  ];

  // Oturum durumuna göre başlangıç rotasını belirle
  static String determineInitialRoute() {
    final authController = Get.find<AuthController>();

    if (authController.isLoggedIn) {
      if (authController.isHairdresser) {
        return hairdresserDashboard;
      } else if (authController.isSalonOwner) {
        return salonOwnerDashboard;
      }
    }

    // Varsayılan olarak müşteri randevu ekranı
    return customerAppointmentBooking;
  }
}
