import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/appConfigurationCubit.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/cubits/slidersCubit.dart';
import 'package:eschool/cubits/socketSettingCubit.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/data/repositories/schoolRepository.dart';
import 'package:eschool/ui/screens/home/widgets/homeContainerTopProfileContainer.dart';
import 'package:eschool/ui/widgets/appUnderMaintenanceContainer.dart';
import 'package:eschool/ui/widgets/borderedProfilePictureContainer.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/forceUpdateDialogContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/svgButton.dart';
import 'package:eschool/utils/animationConfiguration.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/notificationUtility.dart';
import 'package:eschool/utils/systemModules.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({Key? key}) : super(key: key);

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();

  static Widget routeInstance() {
    return BlocProvider<SlidersCubit>(
      create: (context) => SlidersCubit(SchoolRepository()),
      child: const ParentHomeScreen(),
    );
  }
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      _fetchSchoolConfiguration();
      NotificationUtility.setUpNotificationService();
    });
    super.initState();
  }

void _fetchSchoolConfiguration() async {
  try {
    // Fetch profile data using the getProfile method from AuthRepository
    final profileData = await context.read<AuthCubit>().authRepository.getProfile();

    // Log profile data for debugging
    print("Profile fetched successfully:");
    print("Full Name: ${profileData['first_name']}");
    print("Email: ${profileData['email']}");
    print("Mobile: ${profileData['mobile']}");
    print("Role: ${profileData['role']}");

    // Validate and extract the child ID
    final children = profileData['children'] as List<dynamic>? ?? [];
    if (children.isEmpty) {
      throw Exception("No children found in the profile data.");
    }

    // Safely extract the first child's ID
    final firstChildId = children.first['id'] ?? 0;
    if (firstChildId == 0) {
      throw Exception("Invalid child ID found in the profile data.");
    }

    // Log the child ID
    print("First Child ID: $firstChildId");

    // Fetch school configuration with the valid child ID
    await context.read<SchoolConfigurationCubit>().fetchSchoolConfiguration(
          useParentApi: true,
          childId: firstChildId,
        );

    print("School configuration fetched successfully for child ID: $firstChildId");
  } catch (e) {
    // Log any errors that occur
    print("Error in _fetchSchoolConfiguration: $e");
  }
}



Widget _buildAppBar() {
  return FutureBuilder<Map<String, dynamic>>(
    future: context.read<AuthCubit>().authRepository.getProfile(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        // Show a loader while waiting for data
        return Center(
          child: CircularProgressIndicator(),
        );
      } else if (snapshot.hasError) {
        // Show error message if an error occurs
        return Center(
          child: Text(
            "Error: ${snapshot.error}",
            style: TextStyle(color: Colors.red),
          ),
        );
      } else if (snapshot.hasData) {
        final parentDetails = snapshot.data!;
        final fullName = parentDetails['first_name'] ?? "Parent Name";
        final email = parentDetails['email'] ?? "Email not available";
        final imageUrl = parentDetails['image'] ?? "";

        return Align(
          alignment: Alignment.topCenter,
          child: ScreenTopBackgroundContainer(
            padding: EdgeInsets.zero,
            heightPercentage: Utils.appBarMediumtHeightPercentage,
            child: LayoutBuilder(
              builder: (context, boxConstraints) {
                return Stack(
                  children: [
                    // Bordered circles for decoration
                    PositionedDirectional(
                      top: MediaQuery.of(context).size.width * (-0.2),
                      start: MediaQuery.of(context).size.width * (-0.225),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context)
                                .scaffoldBackgroundColor
                                .withOpacity(0.1),
                          ),
                          shape: BoxShape.circle,
                        ),
                        width: MediaQuery.of(context).size.width * (0.6),
                        height: MediaQuery.of(context).size.width * (0.6),
                      ),
                    ),
                    PositionedDirectional(
                      bottom: MediaQuery.of(context).size.width * (-0.15),
                      end: MediaQuery.of(context).size.width * (-0.15),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        width: MediaQuery.of(context).size.width * (0.4),
                        height: MediaQuery.of(context).size.width * (0.4),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: EdgeInsetsDirectional.only(
                          end: boxConstraints.maxWidth * (0.02),
                          start: boxConstraints.maxWidth * (0.075),
                          bottom: boxConstraints.maxHeight * (0.21),
                        ),
                        child: Row(
                          children: [
                            BorderedProfilePictureContainer(
                              heightAndWidth: 65,
                              onTap: () {
                                Get.toNamed(Routes.parentProfile);
                              },
                              imageUrl: imageUrl,
                            ),
                            SizedBox(
                              width: boxConstraints.maxWidth * (0.04),
                            ),
                            SizedBox(
                              width: boxConstraints.maxWidth * (0.5),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                  ),
                                  Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const Spacer(),
                            BlocBuilder<AppConfigurationCubit,
                                AppConfigurationState>(
                              builder: (context, state) {
                                return Utils.isModuleEnabled(
                                        context: context,
                                        moduleId: chatModuleId.toString())
                                    ? SvgButton(
                                        onTap: () {
                                          Get.toNamed(Routes.chatContacts);
                                        },
                                        svgIconUrl: Utils.getImagePath(
                                            "chat_icon.svg"),
                                      )
                                    : const SizedBox();
                              },
                            ),
                            IconButton(
                              iconSize: 24,
                              color:
                                  Theme.of(context).scaffoldBackgroundColor,
                              onPressed: () {
                                Get.toNamed(Routes.settings);
                              },
                              icon: const Icon(Icons.settings),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      } else {
        // Render a fallback widget if no data is available
        return const SizedBox.shrink();
      }
    },
  );
}



 Widget _buildChildDetailsContainer({
  required double width,
  required Student student,
}) {
  // Print the student data to check if it's fetched correctly
  print('Building Child Details Container for student: ${student.getFullName()}');
  print('Student details: ${student.toString()}');

  return Animate(
    effects: customItemZoomAppearanceEffects(),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        print('Navigating to details page for: ${student.getFullName()}');
        Get.toNamed(Routes.parentChildDetails, arguments: student);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        width: width,
        height: 150,
        child: LayoutBuilder(
          builder: (context, boxConstraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: boxConstraints.maxHeight * (0.125),
                        ),
                        BorderedProfilePictureContainer(
                          onTap: () {
                            print('Profile picture clicked for: ${student.getFullName()}');
                            Get.toNamed(
                              Routes.parentChildDetails,
                              arguments: student,
                            );
                          },
                          heightAndWidth: 50,
                          imageUrl: student.childUserDetails?.image ?? "",
                        ),
                        SizedBox(
                          height: boxConstraints.maxHeight * (0.075),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7.5),
                          child: Text(
                            student.getFullName(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: boxConstraints.maxHeight * (0.025),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7.5),
                          child: Text(
                            "${Utils.getTranslatedLabel(classKey)} - ${student.classSection?.fullName}",
                            style: TextStyle(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: -15,
                  start: (boxConstraints.maxWidth * 0.5) - 15,
                  child: Container(
                    alignment: Alignment.center,
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.3),
                          offset: const Offset(0, 5),
                          blurRadius: 20,
                        )
                      ],
                      shape: BoxShape.circle,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    ),
  );
}

 Widget _buildChildrenContainer() {
  return FutureBuilder<Map<String, dynamic>>(
    future: context.read<AuthCubit>().authRepository.getProfile(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(
          child: Text(
            "Error: ${snapshot.error}",
            style: TextStyle(color: Colors.red),
          ),
        );
      } else if (snapshot.hasData) {
        final profileData = snapshot.data!;
        final children = profileData['children'] as List<dynamic>? ?? [];

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * (0.075),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  Utils.getTranslatedLabel(myChildrenKey),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, boxConstraints) {
                  return Wrap(
                    spacing: boxConstraints.maxWidth * (0.05),
                    runSpacing: 32.5,
                    children: children
                        .map<Widget>(
                          (child) => _buildChildDetailsContainer(
                            width: boxConstraints.maxWidth * (0.45),
                            student: Student.fromJson(child),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: context.read<AppConfigurationCubit>().appUnderMaintenance()
          ? const AppUnderMaintenanceContainer()
          : BlocConsumer<SchoolConfigurationCubit, SchoolConfigurationState>(
              listener: (context, state) {
                if (state is SchoolConfigurationFetchSuccess) {
           if (Utils.isModuleEnabled(
    context: context, moduleId: chatModuleId.toString())) {
  context.read<AuthCubit>().authRepository.getProfile().then((profile) {
    final userId = profile['data']?['id'] ?? 0; // Safely fetch the 'id' field
    context.read<SocketSettingCubit>().init(userId: userId);
  }).catchError((error) {
    print("Error fetching profile: $error");
  });
}

                }
              },
              builder: (context, state) {
                if (state is SchoolConfigurationFetchSuccess) {
                  return Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            bottom: 50,
                            top: Utils.getScrollViewTopPadding(
                              context: context,
                              appBarHeightPercentage:
                                  Utils.appBarMediumtHeightPercentage,
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildChildrenContainer(),
                            ],
                          ),
                        ),
                      ),
                      _buildAppBar(),
                      //Check forece update here
                      context.read<AppConfigurationCubit>().forceUpdate()
                          ? FutureBuilder<bool>(
                              future: Utils.forceUpdate(
                                context
                                    .read<AppConfigurationCubit>()
                                    .getAppVersion(),
                              ),
                              builder: (context, snaphsot) {
                                if (snaphsot.hasData) {
                                  return (snaphsot.data ?? false)
                                      ? const ForceUpdateDialogContainer()
                                      : const SizedBox();
                                }

                                return const SizedBox();
                              },
                            )
                          : const SizedBox(),
                    ],
                  );
                }
                if (state is SchoolConfigurationFetchFailure) {
                  return Center(
                    child: Column(
                      children: [
                        HomeContainerTopProfileContainer(),
                        const SizedBox(height: 15),
                        ErrorContainer(
                          errorMessageCode: state.errorMessage,
                          onTapRetry: _fetchSchoolConfiguration,
                        ),
                        const SizedBox(height: 20),
                        CustomRoundedButton(
                          height: 40,
                          widthPercentage: 0.3,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          onTap: () {
                            Get.toNamed(Routes.settings);
                          },
                          titleColor: Theme.of(context).scaffoldBackgroundColor,
                          buttonTitle: Utils.getTranslatedLabel(settingsKey),
                          showBorder: false,
                        )
                      ],
                    ),
                  );
                }

                return const SizedBox();
                // return Column(
                //   children: [
                //     HomeContainerTopProfileContainer(),
                //     Expanded(
                //         child: HomeScreenDataLoadingContainer(
                //       addTopPadding: false,
                //     )),
                //   ],
                // );
              },
            ),
    );
  }
}
