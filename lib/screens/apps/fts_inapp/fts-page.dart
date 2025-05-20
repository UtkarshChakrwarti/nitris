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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          const SizedBox(height: 24),
          _buildHeader(),
          const SizedBox(height: 28),
          _buildFTSInput(),
          const SizedBox(height: 24),
          _buildCheckButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
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
        Icon(
          Icons.search,
          size: 36,
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 14),
        Text(
          AppStrings.enterFtsNumber,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.enterFtsDescription,
          style: TextStyle(
            fontSize: 14,
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
      decoration: InputDecoration(
        labelText: AppStrings.enterFtsNumber,
        labelStyle: TextStyle(color: AppColors.primaryColor), // label color
        prefixIcon: Icon(Icons.numbers, color: AppColors.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor), // outline color
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor), // outline color
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2), // outline color
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      cursorColor: AppColors.primaryColor, // pointer color
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _trackFTS(),
    );
  }

  Widget _buildCheckButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _trackFTS,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.checkStatus,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
        content: Text(message),
        backgroundColor: isError ? AppColors.redStatus : AppColors.greenStatus,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.redStatus),
            const SizedBox(width: 10),
            const Text('Error'),
          ],
        ),
        content: Text(
          error.replaceAll('Exception: ', ''),
          style: TextStyle(color: AppColors.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.primaryColor,
            ),
            child: const Text('OK'),
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
          title: const Text(AppStrings.ftsStatus),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onWillPop(context),
            color: Colors.white,
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FileHeaderCard(ftsData: ftsData),
              const SizedBox(height: 14),
              FileDetailsCard(ftsData: ftsData),
              const SizedBox(height: 14),
              MovementTimeline(movements: ftsData.movements),
              const SizedBox(height: 14),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          AppStrings.goBackTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        content: Text(
          AppStrings.goBackMessage,
          style: TextStyle(color: AppColors.textColor.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.textColor.withOpacity(0.7),
            ),
            child: const Text(AppStrings.stay),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.primaryColor,
            ),
            child: const Text(AppStrings.goBack),
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
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.lightSecondaryColor.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ftsData.fileName.isNotEmpty ? ftsData.fileName : 'No Title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${ftsData.ftsId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (ftsData.lifespan.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 12, color: AppColors.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    'Duration: ${ftsData.lifespan}',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
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

// File Details Card - Ultra Compact Layout
class FileDetailsCard extends StatelessWidget {
  final FTSResponse ftsData;

  const FileDetailsCard({super.key, required this.ftsData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.fileDetails,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildUltraCompactGrid(),
        ],
      ),
    );
  }

  Widget _buildUltraCompactGrid() {
    final details = [
      {'label': 'File Type', 'value': ftsData.fileType},
      {'label': 'Docket No', 'value': ftsData.docketNo},
      {'label': 'Priority', 'value': ftsData.priority},
      {'label': 'Subject Area', 'value': ftsData.area},
      {'label': 'Department', 'value': ftsData.createdDept},
      {'label': 'File Station', 'value': ftsData.station},
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

    return Column(
      children: details.map((detail) => _buildCompactRow(
        label: detail['label'] as String,
        value: detail['value'] as String,
      )).toList(),
    );
  }

  Widget _buildCompactRow({
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightSecondaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textColor.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              color: AppColors.textColor.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                color: AppColors.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Movement Timeline - Minimal Design
class MovementTimeline extends StatelessWidget {
  final List<Movement> movements;

  const MovementTimeline({super.key, required this.movements});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: AppColors.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.movementHistory,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (movements.isEmpty)
            _buildEmptyState()
          else
            _buildMinimalTimeline(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightSecondaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.timeline,
              size: 36,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.noMovementHistory,
              style: TextStyle(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalTimeline() {
    return Column(
      children: movements.asMap().entries.map((entry) {
        final index = entry.key;
        final movement = entry.value;
        final isLast = index == movements.length - 1;
        
        return MinimalTimelineItem(
          movement: movement,
          isLast: isLast,
          position: index + 1,
        );
      }).toList(),
    );
  }
}

// Minimal Timeline Item - Super Compact
class MinimalTimelineItem extends StatelessWidget {
  final Movement movement;
  final bool isLast;
  final int position;

  const MinimalTimelineItem({
    super.key,
    required this.movement,
    required this.isLast,
    required this.position,
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
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMinimalIndicator(),
          const SizedBox(width: 10),
          Expanded(child: _buildMovementContent()),
        ],
      ),
    );
  }

  Widget _buildMinimalIndicator() {
    return Column(
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
              '$position',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
        if (!isLast)
          Container(
            width: 2,
            height: 30,
            color: AppColors.primaryColor.withOpacity(0.3),
          ),
      ],
    );
  }

  Widget _buildMovementContent() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.lightSecondaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildMovementFields(),
      ),
    );
  }

  List<Widget> _buildMovementFields() {
    List<Widget> fields = [];

    if (movement.sentBy.isNotEmpty) {
      fields.add(_buildMinimalField('From', movement.sentBy));
    }
    if (movement.sentOn.isNotEmpty) {
      fields.add(_buildMinimalField('Sent', DateFormatter.formatDateShort(movement.sentOn)));
    }
    if (movement.sentTo.isNotEmpty) {
      fields.add(_buildMinimalField('To', movement.sentTo));
    }
    if (movement.receivedBy.isNotEmpty) {
      fields.add(_buildMinimalField('Received By', movement.receivedBy));
    }
    if (movement.receivedOn.isNotEmpty) {
      fields.add(_buildMinimalField('Received', DateFormatter.formatDateShort(movement.receivedOn)));
    }
    if (movement.markedTo.isNotEmpty) {
      fields.add(_buildMinimalField('Marked To', movement.markedTo));
    }
    if (movement.cmsId.isNotEmpty) {
      fields.add(_buildMinimalField('CMS ID', movement.cmsId));
    }
    if (movement.remarks.isNotEmpty) {
      fields.add(_buildMinimalField('Remarks', movement.remarks));
    }

    return fields;
  }

  Widget _buildMinimalField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textColor.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              color: AppColors.textColor.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}