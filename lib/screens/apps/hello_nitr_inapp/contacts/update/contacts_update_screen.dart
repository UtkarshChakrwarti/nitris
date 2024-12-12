import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/contacts/update/contact_update_controller/contacts_update_controller.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/contacts/update/widgets/error_dialog.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/contacts/update/widgets/loading_widget.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/contacts/update/widgets/status_message.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/contacts/update/widgets/success_widget.dart';

class ContactsUpdateScreen extends StatefulWidget {
  const ContactsUpdateScreen({super.key});

  @override
  _ContactsUpdateScreenState createState() => _ContactsUpdateScreenState();
}

class _ContactsUpdateScreenState extends State<ContactsUpdateScreen>
    with SingleTickerProviderStateMixin {
  final ContactsUpdateController _controller = ContactsUpdateController();
  final Logger _logger = Logger('ContactsUpdateScreen');
  
  // State variables
  double _progress = 0.0;
  bool _isLoading = true;
  bool _showCounter = false;
  int _updatedContacts = 0;
  String _statusMessage = '';

  // Stream subscriptions
  StreamSubscription<double>? _progressSubscription;
  StreamSubscription<String>? _statusSubscription;

  // Animation controllers (nullable)
  AnimationController? _animationController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _initializeLogging();
    _startUpdatingContacts(); // Directly start updating contacts
  }

  /// Initialize logging configuration
  void _initializeLogging() {
    _logger.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
    _logger.info('ContactsUpdateScreen initialized');
  }

  /// Start the contacts update process
  void _startUpdatingContacts() {
    // Initialize AnimationController and Animation since updating is needed
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    );

    _controller.startUpdatingContacts();

    // Listen to progress updates
    _progressSubscription = _controller.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
          _updatedContacts = (_progress * _controller.totalContacts).toInt();
          if (_progress == 1.0) {
            _isLoading = false;
            _animationController?.forward();
            _logger.info('Contacts update completed');
            _navigateToNextScreen();
          }
          if (!_showCounter && progress > 0) {
            _showCounter = true;
          }
        });
      }
    });

    // Listen to status updates
    _statusSubscription = _controller.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _statusMessage = status;
        });
        _logger.info('Status updated: $status');
      }
    }, onError: (error) {
      if (mounted) {
        _showErrorDialog(error.toString());
      }
      _logger.severe('Error status: $error');
    });
  }

  /// Navigate to the next screen
  void _navigateToNextScreen() {
    Navigator.of(context).pushReplacementNamed('/helloNITRHome');
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _statusSubscription?.cancel();
    _animationController?.dispose(); // Dispose only if initialized
    _controller.dispose();
    _logger.info('ContactsUpdateScreen disposed');
    super.dispose();
  }

  /// Show an error dialog
  void _showErrorDialog(String message) {
    _logger.warning('Showing error dialog: $message');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ErrorDialog(
          message: message,
          onDismiss: () {
            Navigator.of(context).pop();
            _logger.info('Error dialog dismissed');
          },
        );
      },
    );
  }

  /// Handle back button press
  Future<bool> _onWillPop() async {
    // If contacts are not updated, don't allow back press
    if (_isLoading) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    _logger.info('Building ContactsUpdateScreen');

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StatusMessage(statusMessage: _statusMessage),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    LoadingWidget(
                      header:
                          'This may take several minutes depending on your network speed.',
                      waitMessage: 'Please wait...',
                      progress: _progress,
                      updatedContacts: _updatedContacts,
                      totalContacts: _controller.totalContacts,
                      showCounter: _showCounter,
                    )
                  else
                    SuccessWidget(
                      animation: _animation!,
                      updatedContacts: _updatedContacts,
                      totalContacts: _controller.totalContacts,
                      onPressed: () {
                        _navigateToNextScreen();
                      },
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
