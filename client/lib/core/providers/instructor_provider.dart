import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/user.dart';

class InstructorProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<User> _instructors = [];
  bool _isLoading = false;
  String? _error;

  List<User> get instructors => _instructors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<User> get activeInstructors => _instructors.where((i) => i.isActive).toList();
  List<User> get inactiveInstructors => _instructors.where((i) => !i.isActive).toList();

  Future<void> loadInstructors({String? status, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (status != null) params['status'] = status;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await _apiClient.get('/instructors', queryParams: params);
      
      if (response['instructors'] != null) {
        _instructors = (response['instructors'] as List)
            .map((json) => User.fromJson(json))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading instructors: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<User?> getInstructor(int instructorId) async {
    try {
      final response = await _apiClient.get('/instructors/$instructorId');
      if (response['instructor'] != null) {
        return User.fromJson(response['instructor']);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error getting instructor: $e');
      notifyListeners();
    }
    return null;
  }

  Future<bool> createInstructor({
    required String name,
    required String phone,
    required String password,
    String? email,
    String? specializations,
    int? experienceYears,
    String? certifications,
    double? hourlyRate,
    String? bio,
  }) async {
    try {
      final data = {
        'name': name,
        'phone': phone,
        'password': password,
        if (email != null) 'email': email,
        if (specializations != null) 'specializations': specializations,
        if (experienceYears != null) 'experience_years': experienceYears,
        if (certifications != null) 'certifications': certifications,
        if (hourlyRate != null) 'hourly_rate': hourlyRate,
        if (bio != null) 'bio': bio,
      };

      await _apiClient.post('/instructors', data);
      await loadInstructors(); // Reload list
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating instructor: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateInstructor(
    int instructorId, {
    String? name,
    String? email,
    String? specializations,
    int? experienceYears,
    String? certifications,
    double? hourlyRate,
    String? bio,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (specializations != null) data['specializations'] = specializations;
      if (experienceYears != null) data['experience_years'] = experienceYears;
      if (certifications != null) data['certifications'] = certifications;
      if (hourlyRate != null) data['hourly_rate'] = hourlyRate;
      if (bio != null) data['bio'] = bio;

      await _apiClient.put('/instructors/$instructorId', data);
      await loadInstructors(); // Reload list
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating instructor: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateInstructorStatus(int instructorId, bool isActive) async {
    try {
      await _apiClient.put('/instructors/$instructorId/status', {
        'is_active': isActive,
      });
      await loadInstructors(); // Reload list
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating instructor status: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeInstructorPassword(
    int instructorId, 
    String newPassword, {
    String? currentPassword,
  }) async {
    try {
      final data = {
        'new_password': newPassword,
        if (currentPassword != null) 'current_password': currentPassword,
      };

      await _apiClient.put('/instructors/$instructorId/password', data);
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error changing instructor password: $e');
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> getInstructorStats(
    int instructorId, {
    int? year,
    int? month,
  }) async {
    try {
      final params = <String, String>{};
      if (year != null) params['year'] = year.toString();
      if (month != null) params['month'] = month.toString();

      final response = await _apiClient.get(
        '/instructors/$instructorId/stats',
        queryParams: params,
      );
      return response;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error getting instructor stats: $e');
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _instructors = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}