// file: lib/data/repositories/auth_repository.dart

import 'package:eschool/data/models/guardian.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/utils/api.dart';
import 'package:eschool/utils/hiveBoxKeys.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthRepository {
  // LocalDataSource
  bool getIsLogIn() {
    return Hive.box(authBoxKey).get(isLogInKey) ?? false;
  }

  Future<void> setIsLogIn(bool value) async {
    return Hive.box(authBoxKey).put(isLogInKey, value);
  }

  static bool getIsStudentLogIn() {
    return Hive.box(authBoxKey).get(isStudentLogInKey) ?? false;
  }

  Future<void> setIsStudentLogIn(bool value) async {
    return Hive.box(authBoxKey).put(isStudentLogInKey, value);
  }

  static Student getStudentDetails() {
    return Student.fromJson(
      Map.from(Hive.box(authBoxKey).get(studentDetailsKey) ?? {}),
    );
  }

  Future<void> setStudentDetails(Student student) async {
    return Hive.box(authBoxKey).put(studentDetailsKey, student.toJson());
  }

  static Guardian getParentDetails() {
    return Guardian.fromJson(
      Map.from(Hive.box(authBoxKey).get(parentDetailsKey) ?? {}),
    );
  }

  Future<void> setParentDetails(Guardian parent) async {
    return Hive.box(authBoxKey).put(parentDetailsKey, parent.toJson());
  }

  String getJwtToken() {
    return Hive.box(authBoxKey).get(jwtTokenKey) ?? "";
  }

  Future<void> setJwtToken(String value) async {
    return Hive.box(authBoxKey).put(jwtTokenKey, value);
  }

  String get schoolCode =>
      Hive.box(authBoxKey).get(schoolCodeKey, defaultValue: "") as String;

  set schoolCode(String value) =>
      Hive.box(authBoxKey).put(schoolCodeKey, value);

  Future<void> signOutUser() async {
    try {
      Api.post(body: {}, url: Api.logout, useAuthToken: true);
    } catch (e) {
      //
    }
    setIsLogIn(false);
    setJwtToken("");
    setStudentDetails(Student.fromJson({}));
    setParentDetails(Guardian.fromJson({}));
  }

  // RemoteDataSource
  Future<Map<String, dynamic>> signInStudent({
    required String grNumber,
    required String schoolCode,
    required String password,
  }) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final body = {
        "password": password,
        "school_code": schoolCode,
        "gr_number": grNumber,
        "fcm_id": fcmToken
      };

      final result = await Api.post(
        body: body,
        url: Api.studentLogin,
        useAuthToken: false,
      );

      final data = result['data'] as Map<String, dynamic>;
      final school = data['school'] as Map<String, dynamic>;

      return {
        "jwtToken": result['token'],
        "schoolCode": school['code'],
        "student": Student.fromJson(Map.from(result['data']))
      };
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }

      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> signInParent({
    required String email,
    required String schoolCode,
    required String password,
  }) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();

      final body = {
        "password": password,
        "email": email,
        "school_code": schoolCode,
        "fcm_id": fcmToken,
      };

      final result =
          await Api.post(body: body, url: Api.parentLogin, useAuthToken: false);

      return {
        "jwtToken": result['token'],
        "parent": Guardian.fromJson(Map.from(result['data'] ?? {}))
      };
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> resetPasswordRequest({
    required String grNumber,
    required DateTime dob,
  }) async {
    try {
      final body = {
        "gr_no": grNumber,
        "dob": DateFormat('yyyy-MM-dd').format(dob)
      };
      await Api.post(
        body: body,
        url: Api.requestResetPassword,
        useAuthToken: false,
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newConfirmedPassword,
  }) async {
    try {
      final body = {
        "current_password": currentPassword,
        "new_password": newPassword,
        "new_confirm_password": newConfirmedPassword
      };
      await Api.post(body: body, url: Api.changePassword, useAuthToken: true);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      final body = {"email": email};
      await Api.post(body: body, url: Api.forgotPassword, useAuthToken: false);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
Future<void> setOtpDetails({required String mobile, required String otp}) async {
  await Hive.box(authBoxKey).put('otpDetails', {'mobile': mobile, 'otp': otp});
}
Future<Map<String, dynamic>> sendOtp({required String mobile}) async {
  try {
    // Save the mobile number to SharedPreferences for later use
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobile', mobile);

    // Construct the request body
    final body = {"mobile": mobile};

    // Make the POST request using Api.post
    print("Sending OTP to mobile: $mobile");

    final response = await Api.post(
      body: body,
      url: Api.sendOTP,
      useAuthToken: true, // Assuming no auth token is needed for sending OTP
    );

    print("OTP sent successfully: ${response['data']}");

    final data = response['data'] as Map<String, dynamic>;

    return {
      "mobile": data['mobile'],
      "otp": data['otp'].toString(), // Ensure OTP is a string
      "expiredTime": data['expired_time'],
    };
  } catch (e) {
    print("Error sending OTP: $e");
    throw ApiException('Error sending OTP: $e');
  }
}
Future<void> saveLoginData({
  required String jwtToken,
  required String mobile,
}) async {
  await Hive.box(authBoxKey).put(jwtTokenKey, jwtToken);
  await Hive.box(authBoxKey).put('mobile', mobile);
  await setIsLogIn(true); // Ensure consistency
}

 Future<bool> autoLogin() async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jwtToken = prefs.getString('jwtToken');
    final String? mobile = prefs.getString('mobile');

    if (jwtToken != null && mobile != null) {
      final isTokenValid = await validateToken(jwtToken);
      if (isTokenValid) {
        try {
          final profile = await getProfile();
          return profile.isNotEmpty;
        } catch (e) {
          debugPrint("Profile fetch failed: $e");
          return true; // Proceed without profile
        }
      }
    }
  } catch (e) {
    debugPrint("Auto-login error: $e");
  }
  return false;
}

Future<bool> validateToken(String token) async {
  try {
    // Decode the token to check expiry (pseudo-code)
    final expiry = JwtDecoder.getExpirationDate(token);
    return DateTime.now().isBefore(expiry);
  } catch (e) {
    debugPrint("Token validation failed: $e");
    return false;
  }
}

Future<Map<String, dynamic>> verifyOtp({
  required String otp,
  required bool useParentApi,
}) async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mobile = prefs.getString('mobile');

    if (mobile == null) {
      throw Exception("Mobile number is not set. Call sendOtp first.");
    }

    // Construct the request body and print useParentApi
    final body = {
      "mobile": mobile,
      "otp": otp,
      "useParentApi": useParentApi, // Ensure this is included
    };

    print("Request body for OTP verification: $body");

    // Make the POST request
    final response = await Api.post(
      body: body,
      url: Api.verityOTP,
      useAuthToken: true,
    );

    print("Response from verifyOtp: ${response['data']}");

    return response; // Ensure you're returning the response as Map<String, dynamic>
  } catch (e) {
    print("Error verifying OTP: $e");
    throw ApiException('Error verifying OTP: $e');
  }
}





Future<Map<String, dynamic>> getProfile() async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mobile = prefs.getString('mobile');

    if (mobile == null) {
      throw Exception("Mobile number is not set. Call sendOtp first.");
    }
final fcmToken = await FirebaseMessaging.instance.getToken();
print("famToken heree: $fcmToken");
    // Construct the request body
    final body = {
      "school_code": "SCH20241",
      "mobile": mobile,
      "fcm_id":fcmToken,
    };

    print("Request body: $body");

    // Make the POST request
    final response = await Api.post(
      body: body,
      url: Api.getprofile,
      useAuthToken: true,
    );

    print("Response from getProfile: ${response}");

    if (response['error'] == true) {
      throw Exception(response['message'] ?? "Failed to fetch profile");
    }

    // Extract the 'data' field
    final data = response['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw Exception("Profile data is missing");
    }

    print("Profile fetched successfully.");
    return data; // Return the data field
  } catch (e) {
    print("Error in getProfile: $e");
    throw Exception("Error fetching profile: $e");
  }
}


}
