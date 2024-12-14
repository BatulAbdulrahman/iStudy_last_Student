import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/guardian.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
abstract class SignInState extends Equatable {}

class SignInInitial extends SignInState {
  @override
  List<Object?> get props => [];
}

class SignInInProgress extends SignInState {
  @override
  List<Object?> get props => [];
}

class SignInSuccess extends SignInState {
  final String jwtToken;
  final bool isStudentLogIn;
  final Student student;
  final String schoolCode;
  final Guardian parent;

  SignInSuccess({
    required this.jwtToken,
    required this.isStudentLogIn,
    required this.student,
    required this.parent,
    required this.schoolCode,
  });

  @override
  List<Object?> get props => [jwtToken, isStudentLogIn, student];
}
class OtpSuccess extends SignInState {
  final String mobile;
  final String otp;
  final String jwtToken; // Add jwtToken here

  OtpSuccess({
    required this.mobile,
    required this.otp,
    required this.jwtToken,
  });

  @override
  List<Object?> get props => [mobile, otp, jwtToken];
}




class SignInFailure extends SignInState {
  final String errorMessage;

  SignInFailure(this.errorMessage);

  @override
  List<Object?> get props => [];
}

class OtpSent extends SignInState {
  final String mobile;
  final String otp;
  final String expiredTime;

  OtpSent({
    required this.mobile,
    required this.otp,
    required this.expiredTime,
  });

  @override
  List<Object?> get props => [mobile, otp, expiredTime];
}

class SignInCubit extends Cubit<SignInState> {
  final AuthRepository _authRepository;

  SignInCubit(this._authRepository) : super(SignInInitial());

  Future<void> sendOtp({required String mobile, }) async {
  print("Sending OTP to $mobile with school code: ");
  
  try {
    final result = await _authRepository.sendOtp(mobile: mobile);
    print("API Response: $result");

    emit(OtpSent(
      mobile: result['mobile'],
      otp: result['otp'],
      expiredTime: result['expiredTime'],
    ));
  } catch (e) {
    print("Error: $e");
    emit(SignInFailure(e.toString()));
  }
}
Future<String?> getStoredMobile() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('mobile'); // Returns null if not set
}


Future<void> verifyOtp({required String otp, required bool useParentApi}) async {
  emit(SignInInProgress());
  try {
    // Print to verify that useParentApi is being passed correctly
    print("Verifying OTP with useParentApi: $useParentApi");

    // Retrieve the stored mobile number from SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mobile = prefs.getString('mobile');

    if (mobile == null) {
      throw Exception("Mobile number is not set. Call sendOtp first.");
    }

    // Call verifyOtp from repository with useParentApi
    final Map<String, dynamic> result = await _authRepository.verifyOtp(otp: otp, useParentApi: useParentApi);

    // Extract token and register status from the API response
    final String token = result['data']['token'];
    final bool isRegistered = result['data']['register'];

    emit(OtpSuccess(
      mobile: mobile,
      otp: otp,
      jwtToken: token, // Pass the token from the API response
    ));

    // Optionally handle registration status if required
    if (!isRegistered) {
      print("User is not registered. Redirecting to registration.");
    }
  } catch (e) {
    emit(SignInFailure(e.toString()));
  }
}

  Future<void> signInUser({
    required String userId,
    required String password,
    required String schoolCode,
    required bool isStudentLogin,
  }) async {
    emit(SignInInProgress());

    try {
      late Map<String, dynamic> result;

      if (isStudentLogin) {
        result = await _authRepository.signInStudent(
          grNumber: userId,
          schoolCode: schoolCode,
          password: password,
        );
      } else {
        result = await _authRepository.signInParent(
          email: userId,
          schoolCode: schoolCode,
          password: password,
        );
      }

      emit(
        SignInSuccess(
          schoolCode: schoolCode,
          jwtToken: result['jwtToken'],
          isStudentLogIn: isStudentLogin,
          student: isStudentLogin ? result['student'] : Student.fromJson({}),
          parent: isStudentLogin ? Guardian.fromJson({}) : result['parent'],
        ),
      );
    } catch (e) {
      emit(SignInFailure(e.toString()));
    }
  }
}
