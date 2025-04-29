import 'package:flutter/material.dart';
import 'package:nitris/core/models/application.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/contacts/update/contact_update_controller/contacts_update_controller.dart';
import 'package:nitris/screens/launch_screen/theme/launch_app_theme.dart';
import 'package:nitris/core/constants/app_colors.dart';

class ApplicationCard extends StatelessWidget {
  final Application application;

  const ApplicationCard({Key? key, required this.application})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to adjust the icon size based on available width.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate icon size as a percentage of the available width.
        final iconSize = constraints.maxWidth * 0.45;

        // Icon widget with rounded corners.
        final Widget iconWidget = ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Image.asset(
            application.icon,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.apps, size: iconSize, color: Colors.grey);
            },
          ),
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final loginResponse =
                  await LocalStorageService.getLoginResponse();
              final employeeType =
                  loginResponse?.employeeType?.toLowerCase() ?? 'employee';
              final empCode = loginResponse?.empCode ?? '1000000';
              // Navigation logic remains the same.
              if (application.label == 'Live Class') {
                if (employeeType == 'student') {
                  Navigator.of(context).pushNamed('/studentAttendance');
                } else {
                  Navigator.of(context).pushNamed('/attendanceHome');
                }
              } else if (application.label == 'Hello') {
                ContactsUpdateController()
                    .hasExistingContacts()
                    .then((hasContacts) {
                  if (hasContacts) {
                    Navigator.of(context).pushNamed('/helloNITRHome');
                  } else {
                    Navigator.of(context).pushNamed('/contactsUpdate');
                  }
                });
              }
              // Add more navigation logic for other applications as needed.
              // for a 'Biometric' application

              else if (employeeType == 'student' && (empCode.startsWith('1'))) {
                Navigator.of(context).pushNamed('/biometricPlaceholder');
              } else if (employeeType == 'student') {
                Navigator.of(context).pushNamed('/biometricAttendanceStudent');
              } else {
                Navigator.of(context).pushNamed('/biometricAttendanceFaculty');
              }
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: AppColors.lightSecondaryColor,
            highlightColor: AppColors.lightSecondaryColor.withOpacity(0.5),
            child: Ink(
              decoration: BoxDecoration(
                // Slightly darker background than pure white.
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(16),
                // Two-layer shadow for a pronounced popping effect.
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black.withOpacity(0.2),
                //     blurRadius: 6,
                //     offset: const Offset(0, 4),
                //   ),
                //   BoxShadow(
                //     color: Colors.black.withOpacity(0.05),
                //     blurRadius: 2,
                //     spreadRadius: 1,
                //     offset: const Offset(0, 0),
                //   ),
                // ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Vertically center content.
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon container without an outline.
                  Ink(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      // boxShadow: [
                      //   BoxShadow(
                      //     color: Colors.black.withOpacity(0.05),
                      //     blurRadius: 4,
                      //     offset: const Offset(0, 2),
                      //   ),
                      // ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: iconWidget,
                  ),
                  const SizedBox(height: 6),
                  // Application label with slightly smaller text.
                  Text(
                    application.label,
                    style: LaunchAppTheme.bodyTextStyle.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: LaunchAppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (application.subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        application.subtitle,
                        style: LaunchAppTheme.bodyTextStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: LaunchAppTheme.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
