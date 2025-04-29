import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoButton extends StatelessWidget {
  const InfoButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline),
      tooltip: 'How to get app code',
      color: AppColors.primaryColor,
      onPressed: () => _showInfoDialog(context),
    );
  }

  void _showInfoDialog(BuildContext context) {
    final Uri nitrisUrl =
        Uri.parse('https://eapplication.nitrkl.ac.in/nitris/Login.aspx');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header -----------------------------------------------------
                Row(
                  children: [
                    Icon(Icons.app_shortcut, color: AppColors.primaryColor),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'How to Get App Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      color: AppColors.primaryColor,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Instructions ----------------------------------------------
                const Text(
                  'To get your app code, follow these steps:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                // Steps ------------------------------------------------------
                _buildStep(1, 'Log in to the NITRis Web Portal', Icons.login),
                Padding(
                  padding: const EdgeInsets.only(left: 32, bottom: 12),
                  child: TextButton.icon(
                    onPressed: () => _launchUrl(nitrisUrl),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.open_in_new,
                        size: 16, color: AppColors.primaryColor),
                    label: const Text('Open NITRIS Portal'),
                  ),
                ),
                _buildStep(
                    2,
                    'Click on Academic option from the top menu',
                    Icons.menu_book),
                _buildStep(3, 'Select Account Settings', Icons.settings),
                _buildStep(
                    4,
                    'Click on NITRis App Code in the left navigation',
                    Icons.code),

                const SizedBox(height: 16),

                // Time notice -----------------------------------------------
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.lightSecondaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_outlined,
                          size: 20, color: AppColors.primaryColor),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'The app code is valid for 120 seconds only.',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            // keep text color as warning style – not an icon
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Close button ----------------------------------------------
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                    ),
                    child: const Text('GOT IT'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Step-row helper -------------------------------------------------------------
  Widget _buildStep(int number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Expanded(child: Text(text)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
