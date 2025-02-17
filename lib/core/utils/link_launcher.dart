import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';

class LinkLauncher {
  static final Logger _logger = Logger('LinkLauncher');

  static Future<void> launchURL(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url);
        _logger.info('Launched URL: $url');
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      _logger.severe('Error launching URL: $url', e);
    }
  }

static String sanitizePhoneNumber(String phoneNumber) {
  return phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
}

static Future<void> makeCall(BuildContext context, String phoneNumber) async {
  final Uri uri = Uri(
  scheme: 'tel',
  path: sanitizePhoneNumber(phoneNumber),
);
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Ensure external apps are used for handling calls
      );
      _logger.info('Initiated call to: $phoneNumber');
    } else {
      throw 'Could not launch $uri';
    }
  } catch (e) {
    _logger.severe('Error making call to: $phoneNumber', e);
  }
}



  static Future<void> sendWpMsg(String phoneNumber) async {
    final url = "https://wa.me/$phoneNumber";
    try {
      if (await canLaunch(url)) {
        await launch(url);
        _logger.info('Sent WhatsApp message to: $phoneNumber');
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      _logger.severe('Error sending WhatsApp message to: $phoneNumber', e);
    }
  }

  static Future<void> sendMsg(String phoneNumber) async {
    final url = "sms:$phoneNumber";
    try {
      if (await canLaunch(url)) {
        await launch(url);
        _logger.info('Sent SMS to: $phoneNumber');
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      _logger.severe('Error sending SMS to: $phoneNumber', e);
    }
  }

  static Future<void> sendEmail(String email) async {
    final url = "mailto:$email";
    try {
      if (await canLaunch(url)) {
        await launch(url);
        _logger.info('Sent email to: $email');
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      _logger.severe('Error sending email to: $email', e);
    }
  }

}
