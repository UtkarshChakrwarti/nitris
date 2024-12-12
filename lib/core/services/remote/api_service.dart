import 'dart:async';
import 'dart:convert';
import 'package:nitris/core/models/login.dart';
import 'package:http/http.dart' as http;
import 'package:nitris/core/models/student.dart';
import 'package:nitris/core/models/subject_response.dart';
import 'package:nitris/core/models/user.dart';
import 'package:nitris/core/constants/app_constants.dart';
import 'package:logging/logging.dart';

class ApiService {
  final String baseUrl = AppConstants.baseUrl;
  final String baseUrlPresentsir = AppConstants.baseUrlPresentsir;
  final http.Client client = http.Client();
  final Logger _logger = Logger('ApiService');

  final String currentAppVersion =
      AppConstants.currentAppVersion; // app's current version

  Future<LoginResponse> login(String userId, String password) async {
    final Uri url =
        Uri.parse('$baseUrlPresentsir/login?userid=$userId&password=$password');
    return await _postRequest(url);
  }

  // Validate the user's that they are still valid or not api will return true if user is valid else false
  Future<bool> validateUser(String? empCode) async {
    final Uri url = Uri.parse('$baseUrl/MyStatus?userid=$empCode');
    final response = await _sendRequest('POST', url);

    if (response.statusCode == 200) {
      return jsonDecode(await response.stream.bytesToString());
    } else {
      _logger.severe('Failed to validate user: ${response.reasonPhrase}');
      throw Exception('Failed to validate user');
    }
  }

  Future<List<User>> fetchContacts() async {
    final Uri url = Uri.parse('$baseUrl/getallemployee');
    var headers = {'Content-Type': 'application/json'};
    final response = await _sendRequest('POST', url, headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> jsonData =
          jsonDecode(await response.stream.bytesToString());
      return jsonData.map((item) => User.fromJson(item)).toList();
    } else {
      _logger.severe('Failed to load contacts: ${response.reasonPhrase}');
      throw Exception('Failed to load contacts');
    }
  }

  Future<bool?> updateDeviceId(String? empCode, String udid) async {
    // Implement the updateDeviceIMEI API here
    final Uri url =
        Uri.parse('$baseUrl/updatelogin?userid=$empCode&deviceid=$udid');
    final response = await _sendRequest('POST', url);

    if (response.statusCode == 200) {
      _logger.info(await response.stream.bytesToString());
      return true;
    } else {
      _logger.severe(response.reasonPhrase);
      return false;
    }
  }

  // De-Register the device from the server
  Future<void> deRegisterDevice(String empCode) async {
    final Uri url = Uri.parse('$baseUrl/resetlogin?userid=$empCode');
    final response = await _sendRequest('POST', url);

    if (response.statusCode == 200) {
      _logger.info(await response.stream.bytesToString());
    } else {
      _logger.severe('Failed to deregister device: ${response.reasonPhrase}');
    }
  }

  // Send OTP to the user's mobile number
  Future<void> sendOtp(String mobileNumber, String otp) async {
    //get last 10 digits of the mobile number
    mobileNumber = mobileNumber.substring(mobileNumber.length - 10);
    final Uri url =
        Uri.parse('$baseUrl/sendotp?otp=$otp&mobileno=$mobileNumber');
    final response = await _sendRequest('POST', url);

    if (response.statusCode == 200) {
      _logger.info(await response.stream.bytesToString());
    } else {
      _logger.severe('Failed to send OTP: ${response.reasonPhrase}');
    }
  }

  // Check for app update
  Future<bool> checkUpdate() async {
    final Uri url = Uri.parse('$baseUrl/version?appid=com.nitrkl.nitris');
    final response = await _sendRequest('GET', url);

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final serverVersion = responseData.trim();
      _logger.info('Server version: $serverVersion');
      _logger.info('Current version: $currentAppVersion');
      bool isUpdateAvailable =
          _isUpdateAvailable(currentAppVersion, serverVersion);
      _logger.info('Update available: $isUpdateAvailable');
      return isUpdateAvailable;
    } else {
      _logger.severe('Failed to check update: ${response.reasonPhrase}');
      return false;
    }
  }

  bool _isUpdateAvailable(String currentVersion, String serverVersion) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> server = serverVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < current.length; i++) {
      if (server[i] > current[i]) {
        return true;
      } else if (server[i] < current[i]) {
        return false;
      }
    }
    return false;
  }

  // Get subjects response from the given faculty ID
  Future<SubjectResponse> getSubjectsResponse(String facultyId) async {
    final Uri url =
        Uri.parse('$baseUrlPresentsir/getsubjects?facultyId=$facultyId');
    final response = await _sendRequest('GET', url);

    if (response.statusCode == 200) {
      return SubjectResponse.fromJson(
          jsonDecode(await response.stream.bytesToString()));
    } else {
      _logger
          .severe('Failed to get subjects response: ${response.reasonPhrase}');
      throw Exception('Failed to get subjects response');
    }
  }

  // Get the list of students for a specific section ID
  Future<List<Student>> getStudents(int sectionId) async {
    final Uri url =
        Uri.parse('$baseUrlPresentsir/GetStudents?sectionid=$sectionId');
    final response = await _sendRequest('GET', url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList =
          jsonDecode(await response.stream.bytesToString());
      //print (jsonList);
      print(jsonList);
      return jsonList.map((json) => Student.fromJson(json)).toList();
    } else {
      _logger.severe('Failed to get students: ${response.reasonPhrase}');
      throw Exception('Failed to get students');
    }
  }
  Future<void> submitAttendance(dynamic payload) async {
    final Uri url = Uri.parse('https://arogyakavach.nitrkl.ac.in/WebApi/Presentsir/SubmitAttendance');
   
    var headers = {'Content-Type': 'application/json'};
    
    // Print the request details
    _logger.info('Submit Attendance Request:');
    _logger.info('URL: $url');
    _logger.info('Headers: $headers');
    _logger.info('Payload: ${jsonEncode(payload)}');

    final response = await _sendRequest('POST', url, headers: headers, body: payload);

    if (response.statusCode == 200) {
      _logger.info(await response.stream.bytesToString());
    } else {
      _logger.severe('Failed to save attendance: ${response.reasonPhrase}');
      throw Exception('Failed to save attendance');
    }
  }

  Future<http.StreamedResponse> _sendRequest(String method, Uri url,
      {Map<String, String>? headers, dynamic body}) async {
    var request = http.Request(method, url);
    if (headers != null) request.headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    try {
      return await client.send(request);
    } on TimeoutException catch (_) {
      _logger.severe('Request to $url timed out.');
      throw Exception('Request timed out');
    } catch (e) {
      _logger.severe('Request to $url failed: $e');
      throw Exception('Request failed');
    }
  }

  Future<LoginResponse> _postRequest(Uri url,
      {Map<String, String>? headers, dynamic body}) async {
    final response =
        await _sendRequest('POST', url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(
          jsonDecode(await response.stream.bytesToString()));
    } else {
      _logger.severe('Failed to login: ${response.reasonPhrase}');
      throw Exception('Failed to login');
    }
  }
}