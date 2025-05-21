import 'package:flutter/material.dart';
import 'package:nitris/core/models/application.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:nitris/screens/apps/biometric_inapp/biometric_dashboard.dart';
import 'package:nitris/screens/apps/fts_inapp/fts-page.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/contacts/update/contact_update_controller/contacts_update_controller.dart';
import 'package:nitris/screens/launch_screen/theme/launch_app_theme.dart';
import 'package:nitris/core/constants/app_colors.dart';

/// A reusable card widget that displays an application icon + label
/// and navigates to the correct route when tapped.
class ApplicationCard extends StatelessWidget {
  final Application application;

  const ApplicationCard({Key? key, required this.application})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = constraints.maxWidth * 0.45;

        final iconWidget = ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            application.icon,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.apps, size: iconSize, color: Colors.grey),
          ),
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleTap(context),
            borderRadius: BorderRadius.circular(16),
            splashColor: AppColors.lightSecondaryColor,
            highlightColor: AppColors.lightSecondaryColor.withOpacity(0.5),
            child: Ink(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Ink(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: iconWidget,
                  ),
                  const SizedBox(height: 6),
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

  /// Determines the correct route based on [application.label] and user info,
  /// then navigates exactly once.
  Future<void> _handleTap(BuildContext context) async {
    final loginResponse = await LocalStorageService.getLoginResponse();
    final employeeType =
        loginResponse?.employeeType?.toLowerCase() ?? 'employee';
    final empCode = loginResponse?.empCode ?? '1000000';

    String? route;

    switch (application.label) {
      case 'Live Class':
        route = employeeType == 'student'
            ? '/studentAttendance'
            : '/attendanceHome';
        break;

      case 'Hello':
        final hasContacts =
            await ContactsUpdateController().hasExistingContacts();
        route = hasContacts ? '/helloNITRHome' : '/contactsUpdate';
        break;

      case 'Biometric':
        if (employeeType == 'student') {
          route = empCode.startsWith('1')
              ? '/biometricPlaceholder'
              : '/biometricAttendanceStudent';
        } else {
          // For non-students, directly navigate to BiometricTeacherAttendancePage
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    BiometricTeacherAttendancePage(teacherId: empCode),
              ),
            );
          }
          return; // Early return since we've already navigated
        }
        break;

      case 'File':
        FTSTrackingHelper.navigateToFTSInput(context);
        break;

      default:
        // Handle unknown applications if necessary (e.g. show a SnackBar).
        route = null;
    }

    if (route != null && context.mounted) {
      Navigator.of(context).pushNamed(route);
    }
  }
}
