import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';

class AuthService extends GetxService {
  final GetStorage _storage = GetStorage();

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxList<UserModel> registeredUsers = <UserModel>[].obs;

  bool get isLoggedIn => currentUser.value != null;
  bool get isGuest => currentUser.value?.isGuest ?? true;

  @override
  void onInit() {
    super.onInit();
    _loadUsers();
    _loadCurrentSession();
  }

  void _loadUsers() {
    final List<dynamic>? stored = _storage.read<List<dynamic>>('users');
    if (stored != null) {
      registeredUsers.assignAll(
        stored.map((e) => UserModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
    }
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
    final lowerUsername = username.trim().toLowerCase();
    final lowerEmail = email.trim().toLowerCase();

    final exists = registeredUsers.any(
      (u) => u.username.toLowerCase() == lowerUsername || u.email.toLowerCase() == lowerEmail,
    );

    if (exists) {
      return false;
    }

    final newUser = UserModel(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
      username: username.trim(),
      email: email.trim(),
      password: password,
      phone: phone.trim(),
    );

    registeredUsers.add(newUser);
    await _storage.write('users', registeredUsers.map((u) => u.toJson()).toList());
    return true;
  }

  bool login({
    required String identifier, // Username or Email
    required String password,
  }) {
    final cleanIdentifier = identifier.trim().toLowerCase();
    final match = registeredUsers.firstWhereOrNull(
      (u) =>
          (u.username.toLowerCase() == cleanIdentifier ||
              u.email.toLowerCase() == cleanIdentifier) &&
          u.password == password,
    );

    if (match != null) {
      currentUser.value = match;
      _storage.write('current_user', match.toJson());
      return true;
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

    final lowerUsername = username.trim().toLowerCase();
    final lowerEmail = email.trim().toLowerCase();

    // Check collision with OTHER registered users
    final collision = registeredUsers.any(
      (u) =>
          u.id != current.id &&
          (u.username.toLowerCase() == lowerUsername || u.email.toLowerCase() == lowerEmail),
    );

    if (collision) {
      return false;
    }

    final updatedUser = current.copyWith(
      username: username.trim(),
      email: email.trim(),
      phone: phone.trim(),
      password: (newPassword != null && newPassword.isNotEmpty)
          ? newPassword
          : current.password,
    );

    // Replace in registeredUsers list
    final index = registeredUsers.indexWhere((u) => u.id == current.id);
    if (index != -1) {
      registeredUsers[index] = updatedUser;
    }

    currentUser.value = updatedUser;
    await _storage.write('current_user', updatedUser.toJson());
    await _storage.write('users', registeredUsers.map((u) => u.toJson()).toList());

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
