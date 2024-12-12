import 'dart:async';
import 'package:logging/logging.dart';
import 'package:nitris/core/models/user.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:nitris/core/services/remote/api_service.dart';

/// Utility class for handling retries
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffFactor;
  
  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffFactor = 2.0,
  });
}

/// Generic retry utility function
Future<T> retry<T>(
  Future<T> Function() operation,
  Logger logger, {
  RetryConfig config = const RetryConfig(),
  String operationName = 'operation',
}) async {
  int attempt = 0;
  Duration delay = config.initialDelay;

  while (true) {
    try {
      attempt++;
      return await operation();
    } catch (e) {
      if (attempt >= config.maxAttempts) {
        logger.severe('Failed all ${config.maxAttempts} attempts for $operationName: $e');
        rethrow;
      }

      logger.warning(
        'Attempt $attempt failed for $operationName. Retrying in ${delay.inSeconds}s: $e',
      );

      await Future.delayed(delay);
      delay = delay * config.backoffFactor;
    }
  }
}

class ContactsUpdateController {
  final Logger _logger = Logger('ContactsUpdateController');
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  final ApiService _apiService = ApiService();
  final RetryConfig _retryConfig = const RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 2),
    backoffFactor: 2.0,
  );
  int totalContacts = 0;

  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get statusStream => _statusController.stream;

  ContactsUpdateController() {
    _logger.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  /// Starts the contact updating process with retry mechanism.
  void startUpdatingContacts() async {
    try {
      _statusController.add('Updating Contacts List...');
      _logger.info('Started updating contacts');

      // Step 1: Fetch contacts from the server with retry
      List<User> serverUsers = await retry(
        () => fetchContactsFromServer(),
        _logger,
        config: _retryConfig,
        operationName: 'fetch contacts',
      );

      // Step 2: Get the total number of contacts
      totalContacts = serverUsers.length;

      // Step 3: Update the contacts in local database with progress updates
      for (int i = 0; i < totalContacts; i++) {
        await retry(
          () => LocalStorageService.saveUser(serverUsers[i]),
          _logger,
          config: _retryConfig,
          operationName: 'save user ${serverUsers[i].firstName}',
        );

        _logger.info(
            'Updated contact: ${serverUsers[i].firstName} ${serverUsers[i].lastName}');
        _progressController.add((i + 1) / totalContacts);
      }

      _logger.info('Contacts updated successfully');
      _statusController.add('Contacts updated successfully');
    } catch (e) {
      _logger.severe('Error updating contacts: $e');
      _statusController.addError(
          'An error occurred while updating contacts. Please check your network settings and try again.');
    }
  }

  /// Fetches contacts from the remote server.
  Future<List<User>> fetchContactsFromServer() async {
    _logger.info('Fetching contacts from server');
    return await _apiService.fetchContacts();
  }

  /// Checks if there are existing contacts in local storage with retry mechanism.
  Future<bool> hasExistingContacts() async {
    try {
      return await retry(
        () async {
          _logger.info('Checking for existing contacts in local storage');
          return await LocalStorageService.getUserCount('All Employee') > 0;
        },
        _logger,
        config: _retryConfig,
        operationName: 'check existing contacts',
      );
    } catch (e) {
      _logger.severe('Error checking for existing contacts after all retries: $e');
      rethrow;
    }
  }

  /// Disposes the stream controllers to prevent memory leaks.
  void dispose() {
    _progressController.close();
    _statusController.close();
  }
}