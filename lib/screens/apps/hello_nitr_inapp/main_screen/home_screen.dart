// hello_nitr_home_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:logging/logging.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/constants/app_constants.dart';
import 'package:nitris/core/models/user.dart';
import 'package:nitris/core/utils/dialogs_and_prompts.dart';
import 'package:nitris/core/utils/link_launcher.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/contacts/profile/contact_profile_screen.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/main_screen/provider/home_provider.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/main_screen/widgets/avatar.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/main_screen/widgets/contact_list.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/main_screen/widgets/user_profile_bottom_sheet_content.dart';
import 'search_screen.dart';

class HelloNITRHomeScreen extends StatefulWidget {
  const HelloNITRHomeScreen({super.key});

  @override
  _HelloNITRHomeScreenState createState() => _HelloNITRHomeScreenState();
}

class _HelloNITRHomeScreenState extends State<HelloNITRHomeScreen>
    with TickerProviderStateMixin {
  static const _pageSize = AppConstants.pageSize;
  final PagingController<int, User> _pagingController =
      PagingController(firstPageKey: 0);
  final Duration animationDuration = const Duration(milliseconds: 300);
  final Logger _logger = Logger('HomeScreen');

  int? _expandedIndex;
  String _currentFilter = 'All Employee';
  bool _isAscending = true;
  int _contactCount = 0;
  final Map<String, Widget> _profileImagesCache = {};

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Add _lastBackPressed variable
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
    _setupLogging();
    _fetchContactCount();
  }

  void _setupLogging() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await HomeProvider.fetchContacts(
          pageKey, _pageSize, _currentFilter, _isAscending);

      if (!mounted) return; // Prevent further actions if disposed

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
      _cacheProfileImages(newItems);
    } catch (error) {
      if (!mounted) return; // Prevent setting error if disposed
      _pagingController.error = error;
    }
  }

  Future<void> _fetchContactCount() async {
    try {
      final count = await HomeProvider.fetchContactCount(_currentFilter);
      if (!mounted) return; // Prevent setState if disposed
      setState(() {
        _contactCount = count;
      });
    } catch (error) {
      if (!mounted) return; // Prevent logging if disposed
      _logger.severe('Failed to fetch contact count: $error');
    }
  }

  void _cacheProfileImages(List<User> users) {
    for (User user in users) {
      if (user.empCode != null &&
          !_profileImagesCache.containsKey(user.empCode)) {
        _profileImagesCache[user.empCode!] =
            Avatar(photoUrl: user.photo, firstName: user.firstName);
        _logger.info('Image cached for user ${user.empCode}');
      }
    }
  }

  // Show custom filter names based on the current filter
  String get _filterName {
    switch (_currentFilter) {
      case 'All Employee':
        return 'All Employees';
      case 'Faculty':
        return 'Faculties';
      case 'Officer':
        return 'Officers';
      default:
        return _currentFilter;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  void _handleContactTap(int index) {
    if (!mounted) return; // Optional: Ensure widget is still mounted
    setState(() {
      _expandedIndex = (_expandedIndex == index) ? null : index;
    });
  }

  // Implement the _onWillPop function
  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      final shouldExit =
          await DialogsAndPrompts.showExitConfirmationDialog(context);
      return shouldExit ?? false; // Exit if the user confirms
    }
    return false; // Prevent accidental exits
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Use the _onWillPop function
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          // Add a back button in the leading position
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            iconSize: 30,
            onPressed: () async {
              if (await _onWillPop()) {
                // Pop the current screen instead of pushing a new one
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text(
            'Hello NITR',
            style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 20,
                fontFamily: 'Sans-serif',
                fontWeight: FontWeight.w500),
          ),
          actions: [
            // Update the hamburger menu to open a bottom sheet
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              iconSize: 30,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: false, // Wrap content height
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(25.0)),
                  ),
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: UserProfileBottomSheetContent(
                        currentFilter: _currentFilter,
                        onFilterSelected: (filter) {
                          _applyFilter(filter);
                          Navigator.of(context).pop(); // Close the bottom sheet
                        },
                      ),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              iconSize: 30,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SearchScreen(currentFilter: _currentFilter),
                  ),
                );
              },
            ),
            IconButton(
              iconSize: 30,
              icon: Icon(_isAscending
                  ? CupertinoIcons.sort_up
                  : CupertinoIcons.sort_down),
              onPressed: _toggleSortOrder,
            ),
          ],
        ),
        // Removed the drawer property
        body: Column(
          children: [
            Padding(
              // Padding top and left
              padding: const EdgeInsets.only(top: 4.0, left: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$_filterName ($_contactCount)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Sans-serif',
                    color: AppColors.primaryColor.withOpacity(0.8),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PagedListView<int, User>(
                pagingController: _pagingController,
                builderDelegate: PagedChildBuilderDelegate<User>(
                  itemBuilder: (context, item, index) {
                    return ContactListItem(
                      contact: item,
                      isExpanded: _expandedIndex == index,
                      onTap: () => _handleContactTap(index),
                      onDismissed: () {},
                      onCall: () {
                        LinkLauncher.makeCall(context, item.mobile ?? '');
                      },
                      onViewProfile: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContactProfileScreen(item),
                          ),
                        );
                      },
                      avatar: _profileImagesCache[item.empCode] ??
                          Avatar(
                              photoUrl: item.photo, firstName: item.firstName),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilter(String filter) {
    if (!mounted) return; // Prevent actions if disposed
    setState(() {
      _currentFilter = filter;
      _pagingController.refresh();
      _fetchContactCount();
    });
    // Removed Navigator.of(context).pop() to prevent multiple pops
  }

  void _toggleSortOrder() {
    if (!mounted) return; // Prevent actions if disposed
    setState(() {
      _isAscending = !_isAscending;
      _pagingController.refresh();
    });
  }
}
