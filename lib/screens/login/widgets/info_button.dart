import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoButton extends StatelessWidget {
  const InfoButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline),
      onPressed: () => _showInfoDialog(context),
      tooltip: 'How to get app code',
      color: AppColors.primaryColor
    );
  }

  void _showInfoDialog(BuildContext context) {
    final Uri nitrisUrl = Uri.parse('https://eapplication.nitrkl.ac.in/nitris/Login.aspx');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                
                // Instructions
                const Text(
                  'To get your app code, follow these steps:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                
                // Steps
                _buildStep(1, 'Log in to the NITRis Web Portal', Icons.login),
                
                // Link - no underline but clearly a link
                Padding(
                  padding: const EdgeInsets.only(left: 32, bottom: 12),
                  child: TextButton.icon(
                    onPressed: () => _launchUrl(nitrisUrl),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open NITRIS Portal'),
                  ),
                ),
                
                _buildStep(2, 'Click on Academic option from the top menu', Icons.menu_book),
                _buildStep(3, 'Select Account Settings', Icons.settings),
                _buildStep(4, 'Click on NITRis App Code in the left navigation', Icons.code),
                
                const SizedBox(height: 16),
                
                // Time Notice - warning style
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                  color: AppColors.lightSecondaryColor, 
                  borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                  children: [
                    Icon(Icons.warning_amber_outlined, size: 20, color: Colors.red[800]),
                    const SizedBox(width: 8),
                    Expanded(
                    child: Text(
                      'The app code is valid for 120 seconds only.',
                      style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.red[900],
                      ),
                    ),
                    ),
                  ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Button - simplified
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
                Icon(
                  icon, 
                  size: 16,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(text),
                ),
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