// lib/fts_tracking_components.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:nitris/core/constants/app_colors.dart';

// App Strings
class AppStrings {
  static const String appTitle = 'FTS Tracking';
  static const String enterFtsNumber = 'Enter FTS Number';
  static const String enterFtsDescription = 'Please enter your FTS ID to track the status';
  static const String checkStatus = 'Check Status';
  static const String tapToTrack = 'Tap to Track FTS';
  static const String ftsStatus = 'FTS Status';
  static const String fileDetails = 'File Details';
  static const String movementHistory = 'Movement Timeline';
  static const String noMovementHistory = 'No movement history available';
  static const String goBackTitle = 'Confirm';
  static const String goBackMessage = 'Are you sure you want to go back?';
  static const String stay = 'No';
  static const String goBack = 'Yes';
  static const String enterFtsNumberError = 'Please enter FTS number';
  static const String networkError = 'Network error: Unable to connect to server';
  static const String fetchError = 'Failed to fetch FTS data';
  static const String noDataError = 'No data found for this FTS ID';
  static const String invalidDataError = 'Invalid or incomplete data received';
}

// Typography Scale
class AppTypography {
  static const TextStyle headline1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
}

// Models
class FTSResponse {
  final String fileName;
  final String fileType;
  final String docketNo;
  final String priority;
  final String ftsId;
  final String area;
  final String createdDept;
  final String station;
  final String createdOn;
  final String createdBy;
  final String status;
  final String closedBy;
  final String closedOn;
  final String lifespan;
  final String closingComments;
  final List<Movement> movements;

  FTSResponse({
    required this.fileName,
    required this.fileType,
    required this.docketNo,
    required this.priority,
    required this.ftsId,
    required this.area,
    required this.createdDept,
    required this.station,
    required this.createdOn,
    required this.createdBy,
    required this.status,
    required this.closedBy,
    required this.closedOn,
    required this.lifespan,
    required this.closingComments,
    required this.movements,
  });

  factory FTSResponse.fromJson(Map<String, dynamic> json) {
    return FTSResponse(
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? '',
      docketNo: json['docketNo'] ?? '',
      priority: json['priority'] ?? '',
      ftsId: json['ftsId'] ?? '',
      area: json['area'] ?? '',
      createdDept: json['createdDept'] ?? '',
      station: json['station'] ?? '',
      createdOn: json['createdOn'] ?? '',
      createdBy: json['createdBy'] ?? '',
      status: json['status'] ?? '',
      closedBy: json['closedBy'] ?? '',
      closedOn: json['closedOn'] ?? '',
      lifespan: json['lifespan'] ?? '',
      closingComments: json['closingComments'] ?? '',
      movements: (json['movements'] as List<dynamic>?)
              ?.map((item) => Movement.fromJson(item))
              .toList() ??
          [],
    );
  }

  bool get hasValidData {
    return fileName.isNotEmpty && ftsId.isNotEmpty;
  }
}

class Movement {
  final String receivedBy;
  final String receivedOn;
  final String markedTo;
  final String sentBy;
  final String sentOn;
  final String sentTo;
  final String cmsId;
  final String remarks;

  Movement({
    required this.receivedBy,
    required this.receivedOn,
    required this.markedTo,
    required this.sentBy,
    required this.sentOn,
    required this.sentTo,
    required this.cmsId,
    required this.remarks,
  });

  factory Movement.fromJson(Map<String, dynamic> json) {
    return Movement(
      receivedBy: json['receivedBy'] ?? '',
      receivedOn: json['receivedOn'] ?? '',
      markedTo: json['markedTo'] ?? '',
      sentBy: json['sentBy'] ?? '',
      sentOn: json['sentOn'] ?? '',
      sentTo: json['sentTo'] ?? '',
      cmsId: json['cmsId'] ?? '',
      remarks: json['remarks'] ?? '',
    );
  }
}

// Service
class FTSService {
  static const String _baseUrl = 'https://api.nitrkl.ac.in/FTS';
  
  static Future<FTSResponse> trackFTS(String ftsId) async {
    final url = Uri.parse('$_baseUrl/TrackFTS?FtsId=$ftsId');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseText = response.body;
        if (responseText.isEmpty || responseText.trim().toLowerCase() == 'null') {
          throw Exception(AppStrings.noDataError);
        }
        
        final jsonData = json.decode(responseText);
        if (jsonData == null) {
          throw Exception(AppStrings.noDataError);
        }
        
        final ftsResponse = FTSResponse.fromJson(jsonData);
        if (!ftsResponse.hasValidData) {
          throw Exception(AppStrings.invalidDataError);
        }
        
        return ftsResponse;
      } else {
        throw Exception('${AppStrings.fetchError}. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(AppStrings.networkError);
    }
  }
}

// Utilities
class TextUtils {
  static String cleanText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
  
  static String cleanField(String text) {
    // Remove extra spaces and ensure consistent formatting
    return text.trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r':\s*'), ': ')
        .replaceAll(RegExp(r'\s*:\s*'), ': ');
  }
}

class DateFormatter {
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
  
  static String formatDateShort(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

// FTS Helper Functions
class FTSTrackingHelper {
  /// Show FTS Input Bottom Sheet
  /// Call this function to show the FTS input bottom sheet from any page
  static void showFTSInputBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const FTSInputModal(),
        );
      },
    );
  }

  /// Navigate to FTS Status Screen
  /// Call this function to navigate directly to FTS status page with data
  static void navigateToFTSStatus(BuildContext context, FTSResponse ftsData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FTSStatusScreen(ftsData: ftsData),
      ),
    );
  }
}

// FTS Input Modal (Bottom Sheet)
class FTSInputModal extends StatefulWidget {
  const FTSInputModal({super.key});

  @override
  State<FTSInputModal> createState() => _FTSInputModalState();
}

class _FTSInputModalState extends State<FTSInputModal> {
  final TextEditingController _ftsController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          const SizedBox(height: 32),
          _buildHeader(),
          const SizedBox(height: 32),
          _buildFTSInput(),
          const SizedBox(height: 24),
          _buildCheckButton(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 48,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/file-tracking.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.enterFtsNumber,
          style: AppTypography.headline2.copyWith(
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.enterFtsDescription,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textColor.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFTSInput() {
    return TextField(
      controller: _ftsController,
      style: AppTypography.bodyLarge,
      decoration: InputDecoration(
        labelText: AppStrings.enterFtsNumber,
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.primaryColor,
        ),
        prefixIcon: Icon(
          Icons.numbers_outlined,
          color: AppColors.primaryColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      cursorColor: AppColors.primaryColor,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _trackFTS(),
    );
  }

  Widget _buildCheckButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _trackFTS,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.checkStatus,
                    style: AppTypography.button.copyWith(color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _trackFTS() async {
    if (_ftsController.text.trim().isEmpty) {
      _showSnackBar(AppStrings.enterFtsNumberError, isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ftsData = await FTSService.trackFTS(_ftsController.text.trim());
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        FTSTrackingHelper.navigateToFTSStatus(context, ftsData);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: isError ? AppColors.primaryColor : AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.redStatus),
            const SizedBox(width: 12),
            Text(
              'Error',
              style: AppTypography.headline3.copyWith(
                color: AppColors.textColor,
              ),
            ),
          ],
        ),
        content: Text(
          error.replaceAll('Exception: ', ''),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'OK',
              style: AppTypography.button.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ftsController.dispose();
    super.dispose();
  }
}

// FTS Status Screen (View Page)
class FTSStatusScreen extends StatelessWidget {
  final FTSResponse ftsData;

  const FTSStatusScreen({super.key, required this.ftsData});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            AppStrings.ftsStatus,
            style: AppTypography.headline2.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => _onWillPop(context),
            color: Colors.white,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FileHeaderCard(ftsData: ftsData),
              const SizedBox(height: 20),
              FileDetailsCard(ftsData: ftsData),
              const SizedBox(height: 20),
              MovementTimeline(movements: ftsData.movements),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppStrings.goBackTitle,
          style: AppTypography.headline3.copyWith(
            color: AppColors.textColor,
          ),
        ),
        content: Text(
          AppStrings.goBackMessage,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textColor.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.textColor.withOpacity(0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppStrings.stay,
              style: AppTypography.button.copyWith(
                color: AppColors.textColor.withOpacity(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppStrings.goBack,
              style: AppTypography.button.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }
}

// File Header Card
class FileHeaderCard extends StatelessWidget {
  final FTSResponse ftsData;

  const FileHeaderCard({super.key, required this.ftsData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TextUtils.cleanText(ftsData.fileName.isNotEmpty ? ftsData.fileName : 'No Title'),
                      style: AppTypography.headline3.copyWith(
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${TextUtils.cleanText(ftsData.ftsId)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (ftsData.lifespan.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Duration: ${TextUtils.cleanText(ftsData.lifespan)}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// File Details Card - Compact Grid Layout
class FileDetailsCard extends StatelessWidget {
  final FTSResponse ftsData;

  const FileDetailsCard({super.key, required this.ftsData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.fileDetails,
                style: AppTypography.headline3.copyWith(
                  color: AppColors.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCompactDetailsGrid(),
        ],
      ),
    );
  }

  Widget _buildCompactDetailsGrid() {
    final details = [
      {'label': 'File Type', 'value': ftsData.fileType},
      {'label': 'Docket No', 'value': ftsData.docketNo},
      {'label': 'Priority', 'value': ftsData.priority},
      {'label': 'Area', 'value': ftsData.area},
      {'label': 'Department', 'value': ftsData.createdDept},
      {'label': 'Station', 'value': ftsData.station},
      {'label': 'Status', 'value': ftsData.status},
      {'label': 'Created On', 'value': DateFormatter.formatDate(ftsData.createdOn)},
      {'label': 'Created By', 'value': ftsData.createdBy},
      if (ftsData.closedOn.isNotEmpty)
        {'label': 'Closed On', 'value': DateFormatter.formatDate(ftsData.closedOn)},
      if (ftsData.closedBy.isNotEmpty)
        {'label': 'Closed By', 'value': ftsData.closedBy},
      if (ftsData.closingComments.isNotEmpty)
        {'label': 'Closing Comments', 'value': ftsData.closingComments},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSecondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.lightSecondaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < details.length; i += 2)
            Padding(
              padding: EdgeInsets.only(bottom: i < details.length - 2 ? 12 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      details[i]['label'] as String,
                      details[i]['value'] as String,
                    ),
                  ),
                  if (i + 1 < details.length) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailItem(
                        details[i + 1]['label'] as String,
                        details[i + 1]['value'] as String,
                      ),
                    ),
                  ] else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    final cleanValue = TextUtils.cleanText(value);
    if (cleanValue.isEmpty || cleanValue == 'N/A') {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textColor.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          cleanValue,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textColor,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Movement Timeline - Compact with internal numbering
class MovementTimeline extends StatelessWidget {
  final List<Movement> movements;

  const MovementTimeline({super.key, required this.movements});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline_outlined,
                color: AppColors.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.movementHistory,
                style: AppTypography.headline3.copyWith(
                  color: AppColors.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (movements.isEmpty)
            _buildEmptyState()
          else
            _buildCompactTimeline(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.lightSecondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.lightSecondaryColor.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.timeline_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noMovementHistory,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTimeline() {
    return Column(
      children: movements.asMap().entries.map((entry) {
        final index = entry.key;
        final movement = entry.value;
        
        return CompactTimelineItem(
          movement: movement,
          position: index + 1,
          isLast: index == movements.length - 1,
        );
      }).toList(),
    );
  }
}

// Compact Timeline Item - Better structured with icons
class CompactTimelineItem extends StatelessWidget {
  final Movement movement;
  final int position;
  final bool isLast;

  const CompactTimelineItem({
    super.key,
    required this.movement,
    required this.position,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = movement.sentBy.isNotEmpty || 
                   movement.sentTo.isNotEmpty || 
                   movement.receivedBy.isNotEmpty ||
                   movement.markedTo.isNotEmpty ||
                   movement.cmsId.isNotEmpty ||
                   movement.remarks.isNotEmpty;

    if (!hasData) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.lightSecondaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.lightSecondaryColor.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(),
            const SizedBox(height: 16),
            _buildMovementDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$position',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Movement Step $position',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMovementDetails() {
    List<Widget> details = [];

    // Sent By & Sent To
    if (movement.sentBy.isNotEmpty) {
      details.add(_buildDetailRow(
        icon: Icons.send_outlined,
        label: 'From',
        value: TextUtils.cleanField(movement.sentBy),
        date: movement.sentOn.isNotEmpty ? DateFormatter.formatDateShort(movement.sentOn) : null,
      ));
    }

    if (movement.sentTo.isNotEmpty) {
      details.add(_buildDetailRow(
        icon: Icons.call_received_outlined,
        label: 'To',
        value: TextUtils.cleanField(movement.sentTo),
        date: null,
      ));
    }

    // Received By
    if (movement.receivedBy.isNotEmpty) {
      details.add(_buildDetailRow(
        icon: Icons.person_outline,
        label: 'Received By',
        value: TextUtils.cleanField(movement.receivedBy),
        date: movement.receivedOn.isNotEmpty ? DateFormatter.formatDateShort(movement.receivedOn) : null,
      ));
    }

    // Marked To
    if (movement.markedTo.isNotEmpty) {
      details.add(_buildDetailRow(
        icon: Icons.bookmark_border_outlined,
        label: 'Marked To',
        value: TextUtils.cleanField(movement.markedTo),
        date: null,
      ));
    }

    // CMS ID
    if (movement.cmsId.isNotEmpty) {
      details.add(_buildDetailRow(
        icon: Icons.numbers_outlined,
        label: 'CMS ID',
        value: TextUtils.cleanField(movement.cmsId),
        date: null,
      ));
    }

    // Remarks
    if (movement.remarks.isNotEmpty) {
      details.add(_buildDetailRow(
        icon: Icons.comment_outlined,
        label: 'Remarks',
        value: TextUtils.cleanField(movement.remarks),
        date: null,
        isRemark: true,
      ));
    }

    return Column(
      children: details,
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    String? date,
    bool isRemark = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.lightSecondaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '$label:',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textColor.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (date != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    date,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textColor,
                fontWeight: FontWeight.w500,
                height: isRemark ? 1.4 : 1.2,
              ),
              maxLines: isRemark ? null : 2,
              overflow: isRemark ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}