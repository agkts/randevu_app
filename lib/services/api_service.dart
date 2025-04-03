import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // API URL
  static const String baseUrl = 'https://api.randevuapp.com'; // Örnek URL

  // Headers
  Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Token ayarla
  void setToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  // Token temizle
  void clearToken() {
    _headers.remove('Authorization');
  }

  // GET isteği
  Future<Map<String, dynamic>> get(
    String endpoint, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      Uri uri = Uri.parse('$baseUrl/$endpoint');

      if (params != null && params.isNotEmpty) {
        uri = uri.replace(
          queryParameters: params.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        );
      }

      final response = await http.get(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('GET Error: $e');
      return _errorResponse('İstek sırasında bir hata oluştu');
    }
  }

  // POST isteği
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/$endpoint');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('POST Error: $e');
      return _errorResponse('İstek sırasında bir hata oluştu');
    }
  }

  // PUT isteği
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/$endpoint');
      final response = await http.put(
        uri,
        headers: _headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('PUT Error: $e');
      return _errorResponse('İstek sırasında bir hata oluştu');
    }
  }

  // DELETE isteği
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl/$endpoint');
      final response = await http.delete(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('DELETE Error: $e');
      return _errorResponse('İstek sırasında bir hata oluştu');
    }
  }

  // Yanıt işleme
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      String message = 'Bir hata oluştu';

      try {
        final Map<String, dynamic> errorBody = json.decode(response.body);
        message = errorBody['message'] ?? 'Bir hata oluştu';
      } catch (_) {}

      return _errorResponse(message);
    }
  }

  // Hata yanıtı
  Map<String, dynamic> _errorResponse(String message) {
    return {'success': false, 'message': message};
  }

  // AUTH ENDPOINTLERİ

  // Giriş yapma
  Future<Map<String, dynamic>> login(String username, String password) async {
    return await post('auth/login', {
      'username': username,
      'password': password,
    });
  }

  // SALON ENDPOINTLERİ

  // Salon bilgilerini getir
  Future<Map<String, dynamic>> getSalon(String salonId) async {
    return await get('salons/$salonId');
  }

  // Salon bilgilerini güncelle
  Future<Map<String, dynamic>> updateSalon(
    String salonId,
    Map<String, dynamic> data,
  ) async {
    return await put('salons/$salonId', data);
  }

  // KUAFÖR ENDPOINTLERİ

  // Kuaförleri getir
  Future<Map<String, dynamic>> getHairdressers([
    Map<String, dynamic>? params,
  ]) async {
    return await get('hairdressers', params);
  }

  // Kuaför bilgilerini getir
  Future<Map<String, dynamic>> getHairdresser(String hairdresserId) async {
    return await get('hairdressers/$hairdresserId');
  }

  // Yeni kuaför oluştur
  Future<Map<String, dynamic>> createHairdresser(
    Map<String, dynamic> data,
  ) async {
    return await post('hairdressers', data);
  }

  // Kuaför bilgilerini güncelle
  Future<Map<String, dynamic>> updateHairdresser(
    String hairdresserId,
    Map<String, dynamic> data,
  ) async {
    return await put('hairdressers/$hairdresserId', data);
  }

  // Kuaför sil
  Future<Map<String, dynamic>> deleteHairdresser(String hairdresserId) async {
    return await delete('hairdressers/$hairdresserId');
  }

  // HİZMET ENDPOINTLERİ

  // Hizmetleri getir
  Future<Map<String, dynamic>> getServices([
    Map<String, dynamic>? params,
  ]) async {
    return await get('services', params);
  }

  // Hizmet bilgilerini getir
  Future<Map<String, dynamic>> getService(String serviceId) async {
    return await get('services/$serviceId');
  }

  // Yeni hizmet oluştur
  Future<Map<String, dynamic>> createService(Map<String, dynamic> data) async {
    return await post('services', data);
  }

  // Hizmet bilgilerini güncelle
  Future<Map<String, dynamic>> updateService(
    String serviceId,
    Map<String, dynamic> data,
  ) async {
    return await put('services/$serviceId', data);
  }

  // Hizmet sil
  Future<Map<String, dynamic>> deleteService(String serviceId) async {
    return await delete('services/$serviceId');
  }

  // RANDEVU ENDPOINTLERİ

  // Randevuları getir
  Future<Map<String, dynamic>> getAppointments([
    Map<String, dynamic>? params,
  ]) async {
    return await get('appointments', params);
  }

  // Randevu bilgilerini getir
  Future<Map<String, dynamic>> getAppointment(String appointmentId) async {
    return await get('appointments/$appointmentId');
  }

  // Randevu koduna göre randevu getir
  Future<Map<String, dynamic>> getAppointmentByCode(String code) async {
    return await get('appointments/code/$code');
  }

  // Yeni randevu oluştur
  Future<Map<String, dynamic>> createAppointment(
    Map<String, dynamic> data,
  ) async {
    return await post('appointments', data);
  }

  // Randevu bilgilerini güncelle
  Future<Map<String, dynamic>> updateAppointment(
    String appointmentId,
    Map<String, dynamic> data,
  ) async {
    return await put('appointments/$appointmentId', data);
  }

  // Randevu sil
  Future<Map<String, dynamic>> deleteAppointment(String appointmentId) async {
    return await delete('appointments/$appointmentId');
  }
}
