import 'package:flutter/material.dart';
import 'package:nitris/core/models/application.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/contacts/update/contact_update_controller/contacts_update_controller.dart';
import 'package:nitris/screens/launch_screen/theme/launch_app_theme.dart';

class ApplicationCard extends StatelessWidget {
  final Application application;

  const ApplicationCard({Key? key, required this.application})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to get the available width for this card.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate icon size as a percentage of the available width.
        final iconSize = constraints.maxWidth * 0.3;

        final Widget iconWidget = ClipOval(
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
            onTap: () {
              if (application.label == 'Live Class') {
                Navigator.of(context).pushNamed('/attendanceHome');
              } else if (application.label == 'Hello') {
                // Check if contacts are already loaded; then navigate accordingly.
                ContactsUpdateController().hasExistingContacts().then((hasContacts) {
                  if (hasContacts) {
                    Navigator.of(context).pushNamed('/helloNITRHome');
                  } else {
                    Navigator.of(context).pushNamed('/contactsUpdate');
                  }
                });
              }
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: application.color.withOpacity(0.1),
            highlightColor: application.color.withOpacity(0.05),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.grey.shade100,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon container with gradient and padding.
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            application.color.withOpacity(0.15),
                            application.color.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: iconWidget,
                    ),
                    const SizedBox(height: 12),
                    // Application label and subtitle with constrained width.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Column(
                        children: [
                          Text(
                            application.label,
                            style: LaunchAppTheme.bodyTextStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: LaunchAppTheme.textSecondaryColor,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                          if (application.subtitle.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 0),
                              child: Text(
                                application.subtitle,
                                style: LaunchAppTheme.bodyTextStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: LaunchAppTheme.textSecondaryColor,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
