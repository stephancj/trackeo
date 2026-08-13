import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final int id;
  final String email;
  final String? name;
  final String? phone;
  final String role;
  final bool alertsEnabled;
  final bool alertSos;
  final bool alertLowBattery;
  final bool alertSpeedLimit;
  final bool alertViaPush;
  final bool alertViaWhatsapp;
  final bool alertViaEmail;

  const AuthUser({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    required this.role,
    this.alertsEnabled = true,
    this.alertSos = true,
    this.alertLowBattery = true,
    this.alertSpeedLimit = false,
    this.alertViaPush = true,
    this.alertViaWhatsapp = false,
    this.alertViaEmail = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        email: json['email'] as String,
        name: json['name'] as String?,
        phone: json['phone'] as String?,
        role: json['role'] as String,
        alertsEnabled: json['alertsEnabled'] as bool? ?? true,
        alertSos: json['alertSos'] as bool? ?? true,
        alertLowBattery: json['alertLowBattery'] as bool? ?? true,
        alertSpeedLimit: json['alertSpeedLimit'] as bool? ?? false,
        alertViaPush: json['alertViaPush'] as bool? ?? true,
        alertViaWhatsapp: json['alertViaWhatsapp'] as bool? ?? false,
        alertViaEmail: json['alertViaEmail'] as bool? ?? false,
      );

  String get displayName => name?.isNotEmpty == true ? name! : email;

  AuthUser copyWith({
    String? name,
    String? phone,
    bool? alertsEnabled,
    bool? alertSos,
    bool? alertLowBattery,
    bool? alertSpeedLimit,
    bool? alertViaPush,
    bool? alertViaWhatsapp,
    bool? alertViaEmail,
  }) =>
      AuthUser(
        id: id,
        email: email,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        role: role,
        alertsEnabled: alertsEnabled ?? this.alertsEnabled,
        alertSos: alertSos ?? this.alertSos,
        alertLowBattery: alertLowBattery ?? this.alertLowBattery,
        alertSpeedLimit: alertSpeedLimit ?? this.alertSpeedLimit,
        alertViaPush: alertViaPush ?? this.alertViaPush,
        alertViaWhatsapp: alertViaWhatsapp ?? this.alertViaWhatsapp,
        alertViaEmail: alertViaEmail ?? this.alertViaEmail,
      );

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

class RegistrationResponse {
  final String email;

  const RegistrationResponse({required this.email});

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) =>
      RegistrationResponse(email: json['email'] as String);
}
