import 'package:flutter/material.dart';
import 'package:nitris/controllers/user_profile_controller.dart';
import 'package:nitris/core/models/user.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/user_profile/widgets/filter_buttons.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/user_profile/widgets/section_title.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/user_profile/widgets/utility_buttons.dart';


class UserProfileContentWidget extends StatelessWidget {
  final User user;
  final String currentFilter;
  final Function(String) onFilterSelected;

  const UserProfileContentWidget({
    Key? key,
    required this.user,
    required this.currentFilter,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SectionTitle("Filter by", 16.0),
        FilterButtons(
          onFilterSelected: onFilterSelected,
        ),
        const SectionTitle("Utilities", 16.0),
        UtilityButtons(UserProfileController()),
      ],
    );
  }
}
