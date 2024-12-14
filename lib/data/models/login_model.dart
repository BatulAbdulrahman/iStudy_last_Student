// File: lib/models/login_model.dart
class LoginResponse {
  final bool error;
  final String message;
  final LoginData? data;
  final int code;

  LoginResponse({
    required this.error,
    required this.message,
    required this.code,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      error: json['error'],
      message: json['message'],
      code: json['code'],
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }
}

class LoginData {
  final String mobile;
  final int otp;
  final String expiredTime;

  LoginData({
    required this.mobile,
    required this.otp,
    required this.expiredTime,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      mobile: json['mobile'],
      otp: json['otp'],
      expiredTime: json['expired_time'],
    );
  }
}
