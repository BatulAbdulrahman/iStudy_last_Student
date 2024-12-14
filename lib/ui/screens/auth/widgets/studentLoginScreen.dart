import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/signInCubit.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:eschool/ui/screens/auth/widgets/termsAndConditionAndPrivacyPolicyContainer.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/ui/widgets/customTextFieldContainer.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({Key? key}) : super(key: key);

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();

  static Widget routeInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SignInCubit>(
          create: (_) => SignInCubit(AuthRepository()),
        ),
      ],
      child: const StudentLoginScreen(),
    );
  }
}

class _StudentLoginScreenState extends State<StudentLoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  late final Animation<double> _patternAnimation =
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

  final TextEditingController _mobileNumberController = TextEditingController(
    text: showDefaultCredentials ? defaultMobileNumber : null,
  );

  @override
  void initState() {
    super.initState();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (_mobileNumberController.text.trim().isEmpty ||
        _mobileNumberController.text.trim().length < 10) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getTranslatedLabel("pleaseEnterValidMobileNumber"),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    context.read<SignInCubit>().sendOtp(
          mobileNumber: _mobileNumberController.text.trim(),
        );
  }

  Widget _buildUpperPattern() {
    return Align(
      alignment: AlignmentDirectional.topEnd,
      child: FadeTransition(
        opacity: _patternAnimation,
        child: SlideTransition(
          position: _patternAnimation.drive(
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
        opacity: _patternAnimation,
        child: SlideTransition(
          position: _patternAnimation.drive(
            Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero),
          ),
          child: Image.asset(Utils.getImagePath("lower_pattern.png")),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Align(
      alignment: Alignment.topCenter,
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
                left: MediaQuery.of(context).size.width * 0.075,
                right: MediaQuery.of(context).size.width * 0.075,
                top: MediaQuery.of(context).size.height * 0.25,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  CustomTextFieldContainer(
                    hideText: false,
                    hintTextKey: Utils.getTranslatedLabel("mobileNumber"),
                    bottomPadding: 0,
                    textEditingController: _mobileNumberController,
                  ),
                  const SizedBox(height: 30.0),
                  Center(
                    child: BlocConsumer<SignInCubit, SignInState>(
                      listener: (context, state) {
                        if (state is SignInOtpSuccess) {
                          Utils.showCustomSnackBar(
                            context: context,
                            errorMessage: "OTP sent: ${state.otp}",
                            backgroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                          );
                        } else if (state is SignInFailure) {
                          Utils.showCustomSnackBar(
                            context: context,
                            errorMessage: state.errorMessage,
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          );
                        }
                      },
                      builder: (context, state) {
                        return CustomRoundedButton(
                          onTap: () {
                            if (state is SignInInProgress) return;
                            FocusScope.of(context).unfocus();
                            _sendOtp();
                          },
                          widthPercentage: 0.8,
                          backgroundColor:
                              Utils.getColorScheme(context).primary,
                          buttonTitle: Utils.getTranslatedLabel("sendOtp"),
                          titleColor: Theme.of(context).scaffoldBackgroundColor,
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
                  const SizedBox(height: 20.0),
                  const TermsAndConditionAndPrivacyPolicyContainer(),
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
          _buildLowerPattern(),
          _buildUpperPattern(),
          _buildLoginForm(),
        ],
      ),
    );
  }
}
