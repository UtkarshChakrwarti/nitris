import 'dart:async';
import 'dart:convert';
import 'package:nitris/core/models/login.dart';
import 'package:http/http.dart' as http;
import 'package:nitris/core/models/student.dart';
import 'package:nitris/core/models/student_attendance_summary.dart';
import 'package:nitris/core/models/students_subject_response.dart';
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
    // if imp code contains non digit characters then return true as this can be case be of student else check for employee validation
    if (empCode!.contains(RegExp(r'[a-zA-Z]')) || empCode == '1000000') {
      return true;
    }
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
    final Uri url = Uri.parse('$baseUrlPresentsir/SubmitAttendance');

    var headers = {'Content-Type': 'application/json'};

    // Print the request details
    _logger.info('Submit Attendance Request:');
    _logger.info('URL: $url');
    _logger.info('Headers: $headers');
    _logger.info('Payload: ${jsonEncode(payload)}');

    final response =
        await _sendRequest('POST', url, headers: headers, body: payload);

    if (response.statusCode == 200) {
      _logger.info(await response.stream.bytesToString());
    } else {
      _logger.severe('Failed to save attendance: ${response.reasonPhrase}');
      throw Exception('Failed to save attendance');
    }
  }

  Future<StudentSubjectResponse> getStudentSubjects(String userId) async {
    final Uri url =
        Uri.parse('$baseUrlPresentsir/Student/GetSubjects?userId=$userId');
    final response = await _sendRequest('GET', url);

    if (response.statusCode == 200) {
      return StudentSubjectResponse.fromJson(
          jsonDecode(await response.stream.bytesToString()));
    } else {
      _logger
          .severe('Failed to get student subjects: ${response.reasonPhrase}');
      throw Exception('Failed to get student subjects');
    }
  }

  // Start the live attendance session
  Future<Map<String, dynamic>> startLiveSession(
      String sectionId, String latLongString) async {
    final Uri url = Uri.parse(
        '$baseUrlPresentsir/Session/Active/$sectionId/$latLongString');
    final response = await _sendRequest('POST', url);

    if (response.statusCode == 200) {
      final result = await response.stream.bytesToString();
      return jsonDecode(result);
    } else {
      _logger.severe('Failed to start live session: ${response.reasonPhrase}');
      throw Exception('Failed to start live session');
    }
  }

  // End the live attendance session
  Future<void> endLiveSession(String sectionId) async {
    final Uri url = Uri.parse('$baseUrlPresentsir/Session/Close/$sectionId');
    final response = await _sendRequest('POST', url);

    if (response.statusCode == 200) {
      _logger.info(await response.stream.bytesToString());
    } else {
      _logger.severe('Failed to end live session: ${response.reasonPhrase}');
      throw Exception('Failed to end live session');
    }
  }

  // Check session status
  Future<Map<String, String>> checkSessionStatus(int sectionId) async {
    final Uri url =
        Uri.parse('$baseUrlPresentsir/Session/checkstatus/$sectionId');
    final response = await _sendRequest('GET', url);

    if (response.statusCode == 200) {
      final result = await response.stream.bytesToString();
      final Map<String, dynamic> jsonData = jsonDecode(result);

      // Safely extract the status and location values.
      // If either value is null or empty, default to 'closed'.
      String status =
          jsonData['status'] is String ? jsonData['status'] as String : '';
      String location =
          jsonData['location'] is String ? jsonData['location'] as String : '';

      if (status.isEmpty) {
        status = 'closed';
      }
      if (location.isEmpty) {
        location = 'closed';
      }

      return {
        'status': status,
        'location': location,
      };
    } else {
      _logger
          .severe('Failed to check session status: ${response.reasonPhrase}');
      throw Exception('Failed to check session status');
    }
  }

  
  /// Fetch attendance summary for a student
  Future<StudentAttendanceSummary> getStudentAttendance({
    required String rollNo,
    required int month,
    required int year,
  }) async {
    final uri = Uri.parse(
      'https://api.nitrkl.ac.in/Biometric/GetStudentAttendance'
      '?rollno=$rollNo&month=$month&year=$year',
    );

    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final jsonBody = await response.stream.bytesToString();
      return StudentAttendanceSummary.fromJson(
        json.decode(jsonBody) as Map<String, dynamic>
      );
    } else {
      _logger.severe(
        'getStudentAttendance failed: ${response.statusCode} ${response.reasonPhrase}'
      );
      throw Exception('Could not load attendance');
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
