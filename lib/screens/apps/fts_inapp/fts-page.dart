// lib/fts_tracking_components.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';

// ================ CONSTANTS ================

/// Text constants used throughout the FTS tracking module
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
  static const String searchYourPinnedFts = 'Search your pinned FTS';
  static const String refreshPinnedFts = 'Refresh pinned FTS';
  static const String noPinnedFtsFound = 'No pinned FTS found';
  static const String loadingFtsData = 'Loading FTS data...';
}

/// Typography styles used throughout the FTS tracking module
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

/// Animation durations used throughout the application
class AnimationDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

// ================ MODELS ================

/// Response model for FTS data
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

/// Model for movement history of an FTS
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

/// Model for pinned FTS items
class PinnedFTS {
  final String ftsId;
  final String fileName;
  final String status;
  final String location;

  PinnedFTS({
    required this.ftsId,
    required this.fileName,
    required this.status,
    required this.location,
  });

  factory PinnedFTS.fromJson(Map<String, dynamic> json) {
    return PinnedFTS(
      ftsId: json['ftsId'] ?? '',
      fileName: json['fileName'] ?? '',
      status: json['status'] ?? '',
      location: json['location'] ?? '',
    );
  }
}

// ================ SERVICES ================

/// Service for FTS API interactions
class FTSService {
  static const String _baseUrl = 'https://api.nitrkl.ac.in/FTS';

  /// Fetches FTS data by ID
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

  /// Fetches pinned FTS items for current user
  static Future<List<PinnedFTS>> getPinnedFTS() async {
    final loginResponse = await LocalStorageService.getLoginResponse();
    var empCode = loginResponse?.empCode;
    
    // Return dummy data for demo purposes
    if (empCode == "1000000") {
      return _getDummyPinnedFTS();
    }

    final url = Uri.parse('$_baseUrl/GetPinnedFTS?empcode=$empCode');

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
          return [];
        }

        final jsonData = json.decode(responseText) as List<dynamic>;
        if (jsonData.isEmpty) {
          return [];
        }

        return jsonData.map((item) => PinnedFTS.fromJson(item)).toList();
      } else {
        throw Exception('${AppStrings.fetchError}. Status: ${response.statusCode}');
      }
    } catch (e) {
      // Just return empty list on error, to not disrupt the UI flow
      return [];
    }
  }
  
  /// Returns dummy pinned FTS items for demo purposes
  static List<PinnedFTS> _getDummyPinnedFTS() {
    return [
      PinnedFTS(
        ftsId: '123456',
        fileName: 'Test File 1',
        status: 'Operational',
        location: 'Location 1',
      ),
      PinnedFTS(
        ftsId: '654321',
        fileName: 'Test File 2',
        status: 'Operational',
        location: 'Location 2',
      ),
      PinnedFTS(
        ftsId: '789012',
        fileName: 'Test File 3',
        status: 'Operational',
        location: 'Location 3',
      ),
      PinnedFTS(
        ftsId: '345678',
        fileName: 'Test File 4',
        status: 'Operational',
        location: 'Location 4',
      ),
      PinnedFTS(
        ftsId: '901234',
        fileName: 'Test File 5',
        status: 'Operational',
        location: 'Location 5',
      ),
    ];
  }
}

// ================ UTILITIES ================

/// Utilities for text formatting and cleaning
class TextUtils {
  /// Cleans text by removing extra whitespace
  static String cleanText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Cleans field text for consistent formatting
  static String cleanField(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r':\s*'), ': ')
        .replaceAll(RegExp(r'\s*:\s*'), ': ');
  }
}

/// Utilities for date formatting
class DateFormatter {
  /// Formats date string to readable format
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  /// Formats date string to short format
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

/// Helper for status color determination
class StatusHelper {
  /// Gets color for status based on status text
  static Color getStatusColor(String status) {
    status = status.toLowerCase();

    if (status.contains('operational') || status.contains('active') || status.isEmpty) {
      return const Color(0xFF5CB85C); // Green for active status
    } else if (status.contains('pending') || status.contains('review')) {
      return const Color(0xFFFFAA00); // Amber for pending status
    } else if (status.contains('close') || status.contains('completed')) {
      return const Color(0xFF6C757D); // Gray for closed status
    } else {
      return const Color(0xFF5CB85C); // Default green
    }
  }
}

// ================ NAVIGATION HELPER ================

/// Helper for navigation between FTS screens
class FTSNavigator {
  /// Navigate to FTS input screen
  static void navigateToFTSInput(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const FTSInputScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: AnimationDurations.medium,
      ),
    );
  }

  /// Navigate to FTS status screen
  static Future<void> navigateToFTSStatus(BuildContext context, FTSResponse ftsData) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FTSStatusScreen(ftsData: ftsData),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: AnimationDurations.medium,
      ),
    );
  }
  
  /// Navigate directly to FTS status screen by FTS ID
  static Future<void> navigateToFTSStatusByID(BuildContext context, String ftsId) async {
    // Show loading dialog
    _showLoadingDialog(context);
    
    try {
      final ftsData = await FTSService.trackFTS(ftsId);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Navigate to status screen
      await navigateToFTSStatus(context, ftsData);
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error dialog
      _showErrorDialog(context, e.toString());
    }
  }
  
  /// Shows loading dialog
  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(message: AppStrings.loadingFtsData),
    );
  }
  
  /// Shows error dialog
  static void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => const ErrorDialog(error: "Something went wrong Please try again later"),
    );
  }
}

// ================ COMMON WIDGETS ================

/// Loading dialog widget
class LoadingDialog extends StatelessWidget {
  final String message;
  
  const LoadingDialog({
    super.key,
    required this.message,
  });
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error dialog widget
class ErrorDialog extends StatelessWidget {
  final String error;
  
  const ErrorDialog({
    super.key,
    required this.error,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE74C3C)),
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
    );
  }
}

/// Empty state widget for lists
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              message,
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
}

/// Collapsible section widget
class CollapsibleSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget content;
  final bool isExpanded;
  final VoidCallback onTap;
  
  const CollapsibleSection({
    super.key,
    required this.title,
    required this.icon,
    required this.content,
    required this.isExpanded,
    required this.onTap,
  });
  
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
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: AppTypography.headline3.copyWith(
                      color: AppColors.textColor,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: AnimationDurations.fast,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: content,
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: AnimationDurations.medium,
          ),
        ],
      ),
    );
  }
}

// ================ PINNED FTS ITEM WIDGET ================

/// Widget for displaying a pinned FTS item
class PinnedFTSItem extends StatelessWidget {
  final PinnedFTS item;
  final VoidCallback onTap;
  
  const PinnedFTSItem({
    super.key,
    required this.item,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEEFEA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'FTS: ${item.ftsId}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textColor.withOpacity(0.7),
                          ),
                        ),
                        const Spacer(),
                        if (item.status.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: StatusHelper.getStatusColor(item.status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.status,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (item.location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textColor.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================ FILE DETAILS WIDGETS ================

/// Widget for displaying file header
class FileHeaderCard extends StatelessWidget {
  final FTSResponse ftsData;
  
  const FileHeaderCard({
    super.key,
    required this.ftsData,
  });
  
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEEFEA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // File title and ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TextUtils.cleanText(ftsData.fileName.isNotEmpty
                          ? ftsData.fileName
                          : 'No Title'),
                      style: AppTypography.headline3.copyWith(
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'FTS ID: ',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          TextUtils.cleanText(ftsData.ftsId),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Duration and status row
          Row(
            children: [
              // Duration badge
              if (ftsData.lifespan.isNotEmpty)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEEFEA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 16,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Duration: ${TextUtils.cleanText(ftsData.lifespan)}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (ftsData.lifespan.isNotEmpty) const SizedBox(width: 12),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: StatusHelper.getStatusColor(ftsData.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ftsData.status.isEmpty ? 'Operational' : ftsData.status,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Journey visualization
          if (ftsData.movements.isNotEmpty && _hasValidMovements(ftsData.movements)) ...[
            const SizedBox(height: 20),
            _buildJourneyVisualization(ftsData.movements),
          ],
        ],
      ),
    );
  }
  
  bool _hasValidMovements(List<Movement> movements) {
    return movements.any((m) => m.sentBy.isNotEmpty && m.sentTo.isNotEmpty);
  }
  
  Widget _buildJourneyVisualization(List<Movement> movements) {
    // Extract first and last valid movement for visualization
    Movement? firstMovement;
    Movement? lastMovement;

    for (var movement in movements) {
      if (movement.sentBy.isNotEmpty && movement.sentTo.isNotEmpty) {
        if (firstMovement == null) {
          firstMovement = movement;
        }
        lastMovement = movement;
      }
    }

    if (firstMovement == null || lastMovement == null) {
      return const SizedBox.shrink();
    }

    // Extract department code and date
    String firstDept = _extractDeptCode(firstMovement.sentBy);
    String firstDate = _formatShortDate(firstMovement.sentOn);

    String lastDept = _extractDeptCode(lastMovement.sentTo);
    String lastDate = _formatShortDate(lastMovement.sentOn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.divider,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // From department
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstDept,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      firstDate,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Expanded(
                flex: 1,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: AnimationDurations.slow,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(20 * (1 - value), 0),
                      child: Opacity(
                        opacity: value,
                        child: const Icon(
                          Icons.arrow_forward,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // To department
              Expanded(
                flex: 2,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: AnimationDurations.slow,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(20 * (1 - value), 0),
                      child: Opacity(
                        opacity: value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lastDept,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastDate,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textColor.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _extractDeptCode(String dept) {
    // Extract department code, e.g. "CAT : Centre for..." -> "CAT"
    if (dept.contains(':')) {
      return dept.split(':').first.trim();
    }
    return dept.trim();
  }

  String _formatShortDate(String dateStr) {
    if (dateStr.isEmpty) return '';

    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

/// Widget for displaying file details
class FileDetailsCard extends StatelessWidget {
  final FTSResponse ftsData;
  
  const FileDetailsCard({
    super.key,
    required this.ftsData,
  });
  
  @override
  Widget build(BuildContext context) {
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
          for (int i = 0; i < _buildDetailsList().length; i += 2)
            Padding(
              padding: EdgeInsets.only(bottom: i < _buildDetailsList().length - 2 ? 12 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      _buildDetailsList()[i]['label'] as String,
                      _buildDetailsList()[i]['value'] as String,
                    ),
                  ),
                  if (i + 1 < _buildDetailsList().length) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailItem(
                        _buildDetailsList()[i + 1]['label'] as String,
                        _buildDetailsList()[i + 1]['value'] as String,
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
  
  List<Map<String, String>> _buildDetailsList() {
    return [
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

// ================ MOVEMENT TIMELINE WIDGETS ================

/// Widget for displaying movement timeline
class MovementTimeline extends StatelessWidget {
  final List<Movement> movements;
  
  const MovementTimeline({
    super.key,
    required this.movements,
  });
  
  @override
  Widget build(BuildContext context) {
    return movements.isEmpty 
      ? const EmptyStateWidget(
          icon: Icons.timeline_outlined,
          message: AppStrings.noMovementHistory,
        ) 
      : _buildCompactTimeline();
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

/// Widget for displaying a timeline item
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
            ..._buildMovementDetails(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepHeader() {
    return Row(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: AnimationDurations.medium,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
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
            );
          },
        ),
        const SizedBox(width: 12),
        Text(
          'Movement Step',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  List<Widget> _buildMovementDetails() {
    List<Widget> details = [];

    // Received By
    if (movement.receivedBy.isNotEmpty) {
      details.add(_buildDetailRow(
        icon: Icons.person_outline,
        label: 'Received By',
        value: TextUtils.cleanField(movement.receivedBy),
        date: movement.receivedOn.isNotEmpty
            ? DateFormatter.formatDateShort(movement.receivedOn)
            : null,
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

    // Sent By & Sent To
    if (movement.sentBy.isNotEmpty) {
      details.add(_buildDetailRow(
        icon: Icons.send_outlined,
        label: 'From',
        value: TextUtils.cleanField(movement.sentBy),
        date: movement.sentOn.isNotEmpty
            ? DateFormatter.formatDateShort(movement.sentOn)
            : null,
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

    return details;
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

// ================ SCREENS ================

/// FTS Input Screen
class FTSInputScreen extends StatefulWidget {
  const FTSInputScreen({super.key});

  @override
  State<FTSInputScreen> createState() => _FTSInputScreenState();
}

class _FTSInputScreenState extends State<FTSInputScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _ftsController = TextEditingController();
  final FocusNode _ftsFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isPinnedLoading = true;
  List<PinnedFTS> _pinnedFTSItems = [];
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AnimationDurations.medium,
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
    _loadPinnedFTS();
  }

  Future<void> _loadPinnedFTS() async {
    setState(() {
      _isPinnedLoading = true;
    });

    try {
      final pinnedItems = await FTSService.getPinnedFTS();
      if (mounted) {
        setState(() {
          _pinnedFTSItems = pinnedItems;
          _isPinnedLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPinnedLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            AppStrings.enterFtsNumber,
            style: AppTypography.headline2.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
            color: Colors.white,
          ),
          actions: [
            // Refresh button in app bar
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: AppStrings.refreshPinnedFts,
              onPressed: _loadPinnedFTS,
              color: Colors.white,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildTopSection(),
            Expanded(
              child: _buildPinnedSection(),
            ),
          ],
        ),
      ),
    );
  }

  // Compact top section with input and button
  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Description text
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              AppStrings.enterFtsDescription,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Input field with check button
          Row(
            children: [
              // Input field
              Expanded(
                child: TextField(
                  controller: _ftsController,
                  focusNode: _ftsFocusNode,
                  style: AppTypography.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'FTS ID',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textColor.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(
                      Icons.numbers_outlined,
                      color: AppColors.primaryColor,
                    ),
                    suffixIcon: _ftsController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.primaryColor),
                          onPressed: () {
                            setState(() {
                              _ftsController.clear();
                            });
                          },
                        )
                      : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primaryColor.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  cursorColor: AppColors.primaryColor,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _trackFTS(),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ),
              
              // Check button
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: AnimationDurations.medium,
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      margin: const EdgeInsets.only(left: 12),
                      width: 50,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _trackFTS,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.search, size: 20),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.searchYourPinnedFts,
                style: AppTypography.headline3.copyWith(
                  color: AppColors.textColor,
                  fontSize: 16,
                ),
              ),
              if (_isPinnedLoading)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                ),
            ],
          ),
        ),
        if (_isPinnedLoading && _pinnedFTSItems.isEmpty)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ),
          )
        else if (_pinnedFTSItems.isEmpty)
          Expanded(
            child: EmptyStateWidget(
              icon: Icons.bookmark_outline,
              message: AppStrings.noPinnedFtsFound,
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _pinnedFTSItems.length,
              itemBuilder: (context, index) {
                return PinnedFTSItem(
                  item: _pinnedFTSItems[index],
                  onTap: () => _navigateToFTSStatus(_pinnedFTSItems[index].ftsId),
                );
              },
            ),
          ),
      ],
    );
  }

  // Method to navigate directly to FTS status screen
  Future<void> _navigateToFTSStatus(String ftsId) async {
    _ftsFocusNode.unfocus();
    await FTSNavigator.navigateToFTSStatusByID(context, ftsId);
  }

  // Method to track FTS from input field
  Future<void> _trackFTS() async {
    if (_ftsController.text.trim().isEmpty) {
      _showSnackBar(AppStrings.enterFtsNumberError, isError: true);
      return;
    }

    _ftsFocusNode.unfocus();
    await FTSNavigator.navigateToFTSStatusByID(context, _ftsController.text.trim());
    // Clear text field after navigating
    _ftsController.clear();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _ftsController.dispose();
    _ftsFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

/// FTS Status Screen
class FTSStatusScreen extends StatefulWidget {
  final FTSResponse ftsData;

  const FTSStatusScreen({super.key, required this.ftsData});

  @override
  State<FTSStatusScreen> createState() => _FTSStatusScreenState();
}

class _FTSStatusScreenState extends State<FTSStatusScreen> with SingleTickerProviderStateMixin {
  bool _isFileDetailsExpanded = false;
  bool _isMovementTimelineExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AnimationDurations.medium,
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: WillPopScope(
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
                // Hero animation for file header
                Hero(
                  tag: 'fts-${widget.ftsData.ftsId}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: FileHeaderCard(ftsData: widget.ftsData),
                  ),
                ),
                const SizedBox(height: 20),
                // Collapsible sections
                CollapsibleSection(
                  title: AppStrings.fileDetails,
                  icon: Icons.info_outline,
                  isExpanded: _isFileDetailsExpanded,
                  onTap: () {
                    setState(() {
                      _isFileDetailsExpanded = !_isFileDetailsExpanded;
                    });
                  },
                  content: FileDetailsCard(ftsData: widget.ftsData),
                ),
                const SizedBox(height: 20),
                CollapsibleSection(
                  title: AppStrings.movementHistory,
                  icon: Icons.timeline_outlined,
                  isExpanded: _isMovementTimelineExpanded,
                  onTap: () {
                    setState(() {
                      _isMovementTimelineExpanded = !_isMovementTimelineExpanded;
                    });
                  },
                  content: MovementTimeline(movements: widget.ftsData.movements),
                ),
                const SizedBox(height: 20),
              ],
            ),
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
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}