import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final int id;
  final String email;
  final String? name;
  final String role;

  const AuthUser({
    required this.id,
    required this.email,
    this.name,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        email: json['email'] as String,
        name: json['name'] as String?,
        role: json['role'] as String,
      );

  String get displayName => name?.isNotEmpty == true ? name! : email;

  @override
  List<Object?> get props => [id, email];
}

class AuthResponse {
  final String accessToken;
  final AuthUser user;

  const AuthResponse({required this.accessToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['access_token'] as String,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}
