import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/guardianDetailsContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({Key? key}) : super(key: key);

  static Widget routeInstance() {
    return const ParentProfileScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: context.read<AuthCubit>().authRepository.getProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (snapshot.hasData) {
            final parentDetails = snapshot.data!;
            return Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: Utils.getScrollViewTopPadding(
                        context: context,
                        appBarHeightPercentage:
                            Utils.appBarSmallerHeightPercentage,
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * (0.05),
                        ),
                        GuardianDetailsContainer(
                          image: parentDetails['image'] ?? "",
                          fullName: parentDetails['full_name'] ?? "Parent Name",
                          email: parentDetails['email'] ?? "Email not available",
                          mobile: parentDetails['mobile'] ?? "",
                          currentAddress: parentDetails['current_address'] ?? "",
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: CustomAppBar(
                    title: Utils.getTranslatedLabel(profileKey),
                  ),
                ),
              ],
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
