import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/guardian.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AuthState extends Equatable {}

class AuthInitial extends AuthState {
  @override
  List<Object?> get props => [];
}

class Unauthenticated extends AuthState {
  @override
  List<Object?> get props => [];
}

class Authenticated extends AuthState {
  final String jwtToken;
  final bool isStudent;
  final Student student;
  final Guardian parent;
  final String schoolCode;

  Authenticated({
    required this.jwtToken,
    required this.isStudent,
    required this.student,
    required this.parent,
    required this.schoolCode,
  });

  @override
  List<Object?> get props => [jwtToken, parent, student, isStudent];
}
class OtpSentState extends AuthState {
  final String mobile;
  final String otp;

  OtpSentState({
    required this.mobile,
    required this.otp,
  });

  @override
  List<Object?> get props => [mobile, otp];
}


class OtpVerificationSuccess extends AuthState {
  final String jwtToken;
  final String schoolCode;

  OtpVerificationSuccess({
    required this.jwtToken,
    required this.schoolCode,
  });

  @override
  List<Object?> get props => [jwtToken, schoolCode];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit(this.authRepository) : super(AuthInitial()) {
    _checkIsAuthenticated();
  }

  void _checkIsAuthenticated() {
    if (authRepository.getIsLogIn()) {
      emit(
        Authenticated(
          schoolCode: authRepository.schoolCode,
          jwtToken: authRepository.getJwtToken(),
          isStudent: AuthRepository.getIsStudentLogIn(),
          parent: AuthRepository.getIsStudentLogIn()
              ? Guardian.fromJson({})
              : AuthRepository.getParentDetails(),
          student: AuthRepository.getIsStudentLogIn()
              ? AuthRepository.getStudentDetails()
              : Student.fromJson({}),
        ),
      );
    } else {
      emit(Unauthenticated());
    }
  }
  

 Future<void> sendOtp({required String mobile}) async {
  emit(AuthInitial());

  try {
    final result = await authRepository.sendOtp(mobile: mobile);

    // Emit the state to indicate OTP has been sent
    emit(OtpSentState(
      mobile: result['mobile'],
      otp: result['otp'].toString(),
    ));
  } catch (e) {
    emit(Unauthenticated());
  }
}



Future<void> verifyOtp({
  required String mobile,
  required String otp,
  required bool useParentApi, // Add useParentApi flag
}) async {
  emit(AuthInitial());

  try {
    final response = await authRepository.verifyOtp(otp: otp, useParentApi: useParentApi);

    final jwtToken = response['data']['token'];
    final schoolCode = response['data']['register'];

    // Store the JWT token and school code
    authRepository.setJwtToken(jwtToken);
    authRepository.schoolCode = schoolCode;

    // Handle Parent or Student login based on useParentApi flag
    if (useParentApi) {
      final parent = response['data']['parent'];
      authRepository.setParentDetails(Guardian.fromJson(parent));
      authRepository.setIsStudentLogIn(false); // Set student login as false for parent
    } else {
      final student = response['data']['student'];
      authRepository.setStudentDetails(Student.fromJson(student));
      authRepository.setIsStudentLogIn(true); // Set student login as true for student
    }

    // Emit the authenticated state
    emit(
      Authenticated(
        jwtToken: jwtToken,
        schoolCode: schoolCode,
        isStudent: !useParentApi, // Correctly set isStudent based on the flag
        parent: useParentApi ? Guardian.fromJson(response['data']['parent']) : Guardian.fromJson({}),
        student: useParentApi ? Student.fromJson({}) : Student.fromJson(response['data']['student']),
      ),
    );
  } catch (e) {
    emit(Unauthenticated());
  }
}



void handleOtpSent({
  required String mobile,
  required String otp,
  required String jwtToken,
}) {
  // Save OTP and token details
  authRepository.setOtpDetails(mobile: mobile, otp: otp);
  authRepository.setJwtToken(jwtToken);

  // Emit state with OTP details
  emit(
    OtpSentState(
      mobile: mobile,
      otp: otp,
    ),
  );
      authRepository.setIsStudentLogIn(false);
}



  void authenticateUser({
    required String schoolCode,
    required String jwtToken,
    required bool isStudent,
    required Guardian parent,
    required Student student,
  }) {
    authRepository.schoolCode = schoolCode;
    authRepository.setJwtToken(jwtToken);
    authRepository.setIsLogIn(true);
    authRepository.setIsStudentLogIn(isStudent);
    authRepository.setStudentDetails(student);
    authRepository.setParentDetails(parent);

    emit(
      Authenticated(
        schoolCode: schoolCode,
        jwtToken: jwtToken,
        isStudent: isStudent,
        student: student,
        parent: parent,
      ),
    );
  }

  Student getStudentDetails() {
    if (state is Authenticated) {
      return (state as Authenticated).student;
    }
    return Student.fromJson({});
  }

  Guardian getParentDetails() {
    if (state is OtpSentState) {
      return (state as Authenticated).parent;
    }
    return Guardian.fromJson({});
  }

 bool isParent() {
  if (state is OtpSentState) {
    print("Login method: OTP");
    return true; // Login via OTP
  } else if (state is Authenticated) {
    print("Login method: Standard");
    return false; // Login via standard credentials
  }
  return false; // Default case for unauthenticated or other states
}



  void signOut() {
    authRepository.signOutUser();
    emit(Unauthenticated());
  }
}
