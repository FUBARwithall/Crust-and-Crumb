class UserModel {
  final String id;
  final String username;
  final String email;
  final String password;
  final String phone;
  final bool isGuest;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    this.phone = '',
    this.isGuest = false,
  });

  factory UserModel.guest() {
    return UserModel(
      id: 'guest',
      username: 'Tamu / Guest',
      email: '',
      password: '',
      phone: '',
      isGuest: true,
    );
  }

  UserModel copyWith({
    String? username,
    String? email,
    String? password,
    String? phone,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      isGuest: isGuest,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'password': password,
        'phone': phone,
        'isGuest': isGuest,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        password: json['password'] ?? '',
        phone: json['phone'] ?? '',
        isGuest: json['isGuest'] ?? false,
      );
}
