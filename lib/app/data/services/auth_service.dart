import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/app_config.dart';

class AuthService extends GetxService {
  final GetStorage _storage = GetStorage();

  static const String baseUrl = AppConfig.baseUrl;

  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  bool get isLoggedIn => currentUser.value != null;
  bool get isGuest => currentUser.value?.isGuest ?? true;

  @override
  void onInit() {
    super.onInit();
    // Clean up stale legacy local cache of users
    _storage.remove('users');
    _loadCurrentSession();
  }

  void _loadCurrentSession() {
    final Map<String, dynamic>? storedUser = _storage.read<Map<String, dynamic>>('current_user');
    if (storedUser != null) {
      currentUser.value = UserModel.fromJson(storedUser);
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String phone = '',
  }) async {
    try {
      final payload = {
        'name': username.trim(),
        'email': email.trim(),
        'password': password,
        'phone': phone.trim(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('[AuthService] User registered successfully into Supabase DB: ${email.trim()}');
        return true;
      } else {
        final data = jsonDecode(response.body);
        debugPrint('[AuthService] Registration rejected by server: ${data['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('[AuthService] Registration error: $e');
      return false;
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    final cleanIdentifier = identifier.trim().toLowerCase();

    // Validate against Laravel Server API -> Supabase Database (Strict Hashed Password Match)
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'identifier': cleanIdentifier, 'password': password}),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['data'];

        final loggedInUser = UserModel(
          id: userData['id'].toString(),
          username: userData['username'].toString(),
          email: userData['email'].toString(),
          phone: userData['phone']?.toString() ?? '',
        );

        currentUser.value = loggedInUser;
        await _storage.write('current_user', loggedInUser.toJson());
        return true;
      }
    } catch (e) {
      debugPrint('[AuthService] Server login error: $e');
    }

    return false;
  }

  Future<bool> updateProfile({
    required String username,
    required String email,
    required String phone,
    String? newPassword,
  }) async {
    final current = currentUser.value;
    if (current == null || current.isGuest) return false;

    try {
      final payload = {
        'username': username.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        if (newPassword != null && newPassword.isNotEmpty) 'password': newPassword,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/users/${current.id}/profile'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['data'];

        final updatedUser = current.copyWith(
          username: userData['username'].toString(),
          email: userData['email'].toString(),
          phone: userData['phone']?.toString() ?? '',
        );

        currentUser.value = updatedUser;
        await _storage.write('current_user', updatedUser.toJson());
        debugPrint('[AuthService] Profile updated & synced to Supabase DB for user ${current.id}');
        return true;
      }
    } catch (e) {
      debugPrint('[AuthService] Server profile update error: $e');
    }

    final updatedUser = current.copyWith(
      username: username.trim(),
      email: email.trim(),
      phone: phone.trim(),
    );

    currentUser.value = updatedUser;
    await _storage.write('current_user', updatedUser.toJson());
    return true;
  }

  void loginAsGuest() {
    final guest = UserModel.guest();
    currentUser.value = guest;
    _storage.write('current_user', guest.toJson());
  }

  void logout() {
    currentUser.value = null;
    _storage.remove('current_user');
  }
}
