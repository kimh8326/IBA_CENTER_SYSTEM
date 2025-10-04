import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/booking.dart';

class BookingProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadBookings({
    int? userId,
    int? scheduleId,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['user_id'] = userId.toString();
      if (scheduleId != null) queryParams['schedule_id'] = scheduleId.toString();
      if (status != null) queryParams['status'] = status;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final queryString = queryParams.isEmpty 
          ? ''
          : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final response = await _apiClient.get('/bookings$queryString');
      final List<dynamic> bookingData = response['bookings'];

      _bookings = bookingData
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();

      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createBooking(CreateBookingRequest request) async {
    _setLoading(true);
    _setError(null);

    try {
      await _apiClient.post('/bookings', request.toJson());

      // 예약 생성 성공 후 목록 새로고침
      await loadBookings();
      // loadBookings에서 오류가 발생해도 예약 생성 자체는 성공했으므로 true 반환
      _setError(null);  // 오류 클리어
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> cancelBooking(int bookingId, {String? reason}) async {
    _setLoading(true);
    _setError(null);

    try {
      final request = CancelBookingRequest(cancelReason: reason);
      await _apiClient.put('/bookings/$bookingId/cancel', request.toJson());

      await loadBookings();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteBooking(int bookingId) async {
    _setLoading(true);
    _setError(null);

    try {
      await _apiClient.delete('/bookings/$bookingId');

      await loadBookings();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  List<Booking> getMyBookings(int userId) {
    return _bookings.where((booking) => booking.userId == userId).toList();
  }

  List<Booking> getUpcomingBookings([int limit = 10]) {
    final now = DateTime.now();
    return _bookings
        .where((booking) => 
            booking.scheduleDateTime != null &&
            booking.scheduleDateTime!.isAfter(now) &&
            booking.isActive)
        .take(limit)
        .toList();
  }

  List<Booking> getBookingsBySchedule(int scheduleId) {
    return _bookings.where((booking) => booking.scheduleId == scheduleId).toList();
  }

  Booking? getBookingById(int id) {
    try {
      return _bookings.firstWhere((booking) => booking.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _setError(null);
  }
}