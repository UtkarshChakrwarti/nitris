import 'package:flutter/material.dart';
import 'package:nitris/screens/launch_screen/theme/launch_app_theme.dart';

class ApplicationsBar extends StatelessWidget {
  const ApplicationsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Applications',
                  style: LaunchAppTheme.headingStyle
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Access your favorite tools and services',
                  style: LaunchAppTheme.subheadingStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.grid_view_rounded,
            size: 24,
            color: LaunchAppTheme.textSecondaryColor,
          ),
        ],
      ),
    );
  }
}
