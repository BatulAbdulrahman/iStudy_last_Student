import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/signInCubit.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/ui/widgets/customTextFieldContainer.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({Key? key}) : super(key: key);

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();

  static Widget routeInstance() {
    return BlocProvider<SignInCubit>(
      child: const ParentLoginScreen(),
      create: (_) => SignInCubit(AuthRepository()),
    );
  }
}

class _ParentLoginScreenState extends State<ParentLoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  late final Animation<double> _patterntAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ),
  );

  late final Animation<double> _formAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ),
  );

  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isOtpFieldVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mobileNumberController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (_mobileNumberController.text.trim().isEmpty) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getTranslatedLabel("pleaseEnterMobileNumber"),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    context.read<SignInCubit>().sendOtp(
          mobile: _mobileNumberController.text.trim(),
        );
  }

void _verifyOtp() {
  if (_otpController.text.trim().isEmpty) {
    Utils.showCustomSnackBar(
      context: context,
      errorMessage: Utils.getTranslatedLabel("pleaseEnterOtp"),
      backgroundColor: Theme.of(context).colorScheme.error,
    );
    return;
  }

  print('Verifying OTP with useParentApi: true'); // Debug statement

  context.read<SignInCubit>().verifyOtp(
    otp: _otpController.text.trim(),
    useParentApi: true, // Pass the `useParentApi` parameter as true
  );
}



  Widget _buildUpperPattern() {
    return Align(
      alignment: AlignmentDirectional.topEnd,
      child: FadeTransition(
        opacity: _patterntAnimation,
        child: SlideTransition(
          position: _patterntAnimation.drive(
            Tween<Offset>(begin: const Offset(0.0, -1.0), end: Offset.zero),
          ),
          child: Image.asset(Utils.getImagePath("upper_pattern.png")),
        ),
      ),
    );
  }

  Widget _buildLowerPattern() {
    return Align(
      alignment: AlignmentDirectional.bottomStart,
      child: FadeTransition(
        opacity: _patterntAnimation,
        child: SlideTransition(
          position: _patterntAnimation.drive(
            Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero),
          ),
          child: Image.asset(Utils.getImagePath("lower_pattern.png")),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: FadeTransition(
        opacity: _formAnimation,
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: NotificationListener(
            onNotification: (OverscrollIndicatorNotification overscroll) {
              overscroll.disallowIndicator();
              return true;
            },
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * (0.075),
                right: MediaQuery.of(context).size.width * (0.075),
                top: MediaQuery.of(context).size.height * (0.25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Utils.getTranslatedLabel(letsSignInKey),
                    style: TextStyle(
                      fontSize: 34.0,
                      fontWeight: FontWeight.bold,
                      color: Utils.getColorScheme(context).secondary,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    "${Utils.getTranslatedLabel(welcomeBackKey)}, \n${Utils.getTranslatedLabel(youHaveBeenMissedKey)}",
                    style: TextStyle(
                      fontSize: 24.0,
                      height: 1.5,
                      color: Utils.getColorScheme(context).secondary,
                    ),
                  ),
                  const SizedBox(height: 30.0),

                  /// Mobile number or OTP field
                  CustomTextFieldContainer(
                    hideText: false,
                    hintTextKey: _isOtpFieldVisible
                        ? Utils.getTranslatedLabel("otp")
                        : Utils.getTranslatedLabel("mobileNumber"),
                    textEditingController: _isOtpFieldVisible
                        ? _otpController
                        : _mobileNumberController,
                  ),
                  const SizedBox(height: 30.0),

                  Center(
                    child: BlocConsumer<SignInCubit, SignInState>(
                      listener: (context, state) {
                        if (state is OtpSent) {
                          setState(() {
                            _isOtpFieldVisible = true;
                          });
                          Utils.showCustomSnackBar(
                            context: context,
                            errorMessage: Utils.getTranslatedLabel(
                                "otpSentSuccessfully"),
                            backgroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                          );
                        } else if (state is OtpSuccess) {
                        context.read<AuthCubit>().handleOtpSent(
            mobile: state.mobile,
            otp: state.otp,
            jwtToken: state.jwtToken,
          );
                          Get.offNamedUntil(
                            Routes.parentHome,
                            (Route<dynamic> route) => false,
                          );
                        } else if (state is SignInFailure) {
                          Utils.showCustomSnackBar(
                            context: context,
                            errorMessage: Utils.getErrorMessageFromErrorCode(
                              context,
                              state.errorMessage,
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          );
                        }
                      },
                      builder: (context, state) {
                        return CustomRoundedButton(
                          onTap: () {
                            if (state is SignInInProgress) {
                              return;
                            }

                            if (_isOtpFieldVisible) {
                              _verifyOtp();
                            } else {
                              _sendOtp();
                            }
                          },
                          widthPercentage: 0.8,
                          backgroundColor:
                              Utils.getColorScheme(context).primary,
                          buttonTitle: _isOtpFieldVisible
                              ? Utils.getTranslatedLabel("verifyOtp")
                              : Utils.getTranslatedLabel("send"),
                          titleColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          showBorder: false,
                          child: state is SignInInProgress
                              ? const CustomCircularProgressIndicator(
                                  strokeWidth: 2,
                                  widthAndHeight: 20,
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildUpperPattern(),
          _buildLowerPattern(),
          _buildLoginForm(),
        ],
      ),
    );
  }
}
