import 'package:flutter/material.dart';
import 'package:nitris/controllers/user_profile_controller.dart';
import 'package:nitris/core/models/user.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/main_screen/widgets/user_profile_content_widget.dart';

class UserProfileScreen extends StatelessWidget {
  final String currentFilter;
  final Function(String) onFilterSelected;

  const UserProfileScreen({
    Key? key,
    required this.currentFilter,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<User?>(
        future: UserProfileController().getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading user data'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No user data available'));
          } else {
            return UserProfileContentWidget(
              user: snapshot.data!,
              currentFilter: currentFilter,
              onFilterSelected: onFilterSelected,
            );
          }
        },
      ),
    );
  }
}
