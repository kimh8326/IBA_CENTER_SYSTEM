import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/schedule.dart';

class ScheduleProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Schedule> _schedules = [];
  List<ClassType> _classTypes = [];
  bool _isLoading = false;
  String? _error;

  List<Schedule> get schedules => _schedules;
  List<ClassType> get classTypes => _classTypes;
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

  Future<void> loadSchedules({
    String? date,
    String? startDate,
    String? endDate,
    int? instructorId,
    int? classTypeId,
    String? status,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final queryParams = <String, String>{};
      if (date != null) queryParams['date'] = date;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (instructorId != null) queryParams['instructor_id'] = instructorId.toString();
      if (classTypeId != null) queryParams['class_type_id'] = classTypeId.toString();
      if (status != null) queryParams['status'] = status;

      final queryString = queryParams.isEmpty 
          ? ''
          : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final response = await _apiClient.get('/schedules$queryString');
      final List<dynamic> scheduleData = response['schedules'];

      _schedules = scheduleData
          .map((json) => Schedule.fromJson(json as Map<String, dynamic>))
          .toList();

      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadClassTypes() async {
    try {
      final response = await _apiClient.get('/schedules/class-types/list');
      final List<dynamic> classTypeData = response['classTypes'];

      _classTypes = classTypeData
          .map((json) => ClassType.fromJson(json as Map<String, dynamic>))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> createSchedule(CreateScheduleRequest request) async {
    _setLoading(true);
    _setError(null);

    try {
      await _apiClient.post('/schedules', request.toJson());
      
      await loadSchedules();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  List<Schedule> getSchedulesByDate(DateTime date) {
    return _schedules.where((schedule) {
      final scheduleDate = DateTime.parse(schedule.scheduledAt);
      return scheduleDate.year == date.year &&
             scheduleDate.month == date.month &&
             scheduleDate.day == date.day;
    }).toList();
  }

  List<Schedule> getUpcomingSchedules([int limit = 10]) {
    final now = DateTime.now();
    return _schedules
        .where((schedule) => DateTime.parse(schedule.scheduledAt).isAfter(now))
        .take(limit)
        .toList();
  }

  Schedule? getScheduleById(int id) {
    try {
      return _schedules.firstWhere((schedule) => schedule.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _setError(null);
  }
}