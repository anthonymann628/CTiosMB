// lib/models/user.dart
class User {
  final String username;
  final String token;

  User({
    required this.username,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] as String,
      token: json['token'] as String,
    );
  }
}
