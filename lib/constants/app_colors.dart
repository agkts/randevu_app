import 'package:flutter/material.dart';

class AppColors {
  // Ana renkler
  static const Color primary = Color(
    0xFF5C6BC0,
  ); // Mavi-mor tonu (kuaför teması için)
  static const Color secondary = Color(
    0xFFFF7043,
  ); // Turuncu tonu (aksiyon tuşları için)
  static const Color accent = Color(0xFF4DB6AC); // Turkuaz (vurgu rengi)

  // Nötr renkler
  static const Color background = Color(0xFFF5F7FA); // Arka plan (hafif gri)
  static const Color surface = Colors.white; // Yüzey rengi
  static const Color cardBackground = Colors.white; // Kart arka planı

  // Metin renkleri
  static const Color textPrimary = Color(0xFF2E3A59); // Ana metin rengi
  static const Color textSecondary = Color(0xFF8F9BB3); // İkincil metin rengi
  static const Color textHint = Color(0xFFBBBBBB); // İpucu metni rengi

  // Durum renkleri
  static const Color success = Color(0xFF00E096); // Başarı (yeşil)
  static const Color info = Color(0xFF0095FF); // Bilgi (mavi)
  static const Color warning = Color(0xFFFFAA00); // Uyarı (sarı)
  static const Color error = Color(0xFFFF3D71); // Hata (kırmızı)

  // Randevu durumları için renkler
  static const Color appointmentPending = Color(
    0xFFFFF8E1,
  ); // Bekleyen (açık sarı)
  static const Color appointmentConfirmed = Color(
    0xFFE8F5E9,
  ); // Onaylanmış (açık yeşil)
  static const Color appointmentCancelled = Color(
    0xFFFFEBEE,
  ); // İptal edilmiş (açık kırmızı)
  static const Color appointmentCompleted = Color(
    0xFFE3F2FD,
  ); // Tamamlanmış (açık mavi)

  // Gradient renkler
  static const List<Color> primaryGradient = [
    Color(0xFF7986CB),
    Color(0xFF5C6BC0),
  ];

  // Border renkleri
  static const Color border = Color(0xFFEEF2F6); // Çerçeve rengi
  static const Color divider = Color(0xFFEEF2F6); // Ayırıcı rengi
}
