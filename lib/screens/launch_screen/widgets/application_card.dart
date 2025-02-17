import 'package:flutter/material.dart';
import 'package:nitris/core/models/application.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/contacts/update/contact_update_controller/contacts_update_controller.dart';
import 'package:nitris/screens/launch_screen/theme/launch_app_theme.dart';

class ApplicationCard extends StatelessWidget {
  final Application application;

  const ApplicationCard({Key? key, required this.application}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the screen width to make the widget responsive
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate card width based on screen size
    // For tablets, we want to show more items in a row
    final isTablet = screenWidth > 600;
    final cardWidth = isTablet ? 160.0 : 120.0;
    final iconSize = isTablet ? 32.0 : 40.0;
    final paddingSize = isTablet ? 8.0 : 16.0;

    // Load the application icon with error handling
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

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (application.label == 'Live Class') {
              Navigator.of(context).pushNamed('/attendanceHome');
            } else if (application.label == 'Hello') {
              ContactsUpdateController().hasExistingContacts().then((hasContacts) {
                if (hasContacts) {
                  Navigator.of(context).pushNamed('/helloNITRHome');
                } else {
                  Navigator.of(context).pushNamed('/contactsUpdate');
                }
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: application.color.withOpacity(0.1),
          highlightColor: application.color.withOpacity(0.05),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(paddingSize),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Container with optimized size
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
                    padding: EdgeInsets.all(paddingSize * 0.75),
                    child: iconWidget,
                  ),
                  SizedBox(height: paddingSize * 0.25),
                  // Text content with adaptive sizing
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          application.label,
                          style: LaunchAppTheme.bodyTextStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isTablet ? 10 : 11,
                            color: LaunchAppTheme.textSecondaryColor,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (application.subtitle.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: paddingSize*0.1),
                            child: Text(
                              application.subtitle,
                              style: LaunchAppTheme.bodyTextStyle.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: isTablet ? 10 : 11,
                                color: LaunchAppTheme.textSecondaryColor.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
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
      ),
    );
  }
}