import 'package:flutter/material.dart';
import 'package:achno/l10n/app_localizations.dart';
import '../profile/settings_page.dart';
import '../profile/viewProfile.dart'; // Add this import
import 'package:achno/config/theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'package:achno/models/post_model.dart';
import 'package:achno/services/post_service.dart';
import 'package:achno/widgets/post_card.dart';
import 'package:achno/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:achno/services/geocoding_service.dart'; // Import the new service
import 'package:achno/utils/activity_icon_helper.dart'; // Add this import
import 'package:achno/services/city_mapping_service.dart'; // Add this import

class Homepage extends StatefulWidget {
  // Add onNavigateToAddPost callback
  final Function? onNavigateToAddPost;

  const Homepage({super.key, this.onNavigateToAddPost});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
    with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  final GeocodingService _geocodingService =
      GeocodingService(); // Add geocoding service

  // Add a map to store calculated distances between cities
  final Map<String, Map<String, double>> _distanceBetweenCities = {};
  bool _isCalculatingDistances = false;
  String? _userHomeCity;

  bool _isLoading = false;
  bool _hasError = false;
  final List<Post> _posts = [];
  String? _selectedCity; // Initialize to null - no city filter by default
  String? _selectedActivity;
  PostType? _selectedPostType;

  // Add distance filter variable - initialized to null
  int? _selectedDistance;
  final List<int> _distanceOptions = [5, 10, 25];

  String _currentlyPlayingId = '';
  bool _isPlaying = false;

  // Add new variables for audio progress tracking
  Duration? _audioDuration;
  Duration? _audioPosition;
  Timer? _audioProgressTimer;
  StreamSubscription? _playerSubscription;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Location tracking
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String _locationError = '';

  // Filter option lists
  final List<String> _activities = [
    'All',
    'Plumber',
    'Electrician',
    'Wood Worker',
    'Painter',
    'Carpenter',
    'Mason',
    'Gardener',
    'Cleaner',
    'Other'
  ];

  // Replace the static cities list with a dynamic one
  List<String> _cities = ['All']; // Initialize with just 'All'

  String _errorMessage = '';

  // Add cache for audio durations
  final Map<String, Duration> _audioDurations = {};

  // Add search text controller
  final TextEditingController _searchController = TextEditingController();

  // Add default distance filter
  final int _defaultDistanceFilter = 10;

  bool _hasInitialized = false; // Add flag to prevent multiple initializations

  @override
  void initState() {
    super.initState();
    // Add debug message to verify initial filter state
    debugPrint('Homepage initState - No filters active initially');
    debugPrint('Initial selectedCity: $_selectedCity');
    debugPrint('Initial selectedDistance: $_selectedDistance');

    _initAudioPlayer();
    _fetchUserCity(); // New method to fetch the user's city
    _getCurrentLocationWithoutLocalization(); // Use version without localization
    _fetchPosts();
    _startLocationUpdates();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only initialize once when localization becomes available
    if (!_hasInitialized) {
      _hasInitialized = true;
      // Any localization-dependent initialization can go here if needed
    }
  }

  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.openPlayer();
      await _audioPlayer
          .setSubscriptionDuration(const Duration(milliseconds: 100));

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media,
        ),
      ));

      // Fix the null check issue with null-aware operator
      // Set up audio progress subscription to track playback progress
      _playerSubscription = _audioPlayer.onProgress?.listen((event) {
        setState(() {
          _audioPosition = event.position;
          _audioDuration = event.duration;
        });
      });
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  @override
  void dispose() {
    _stopAudio();
    _playerSubscription?.cancel();
    _audioProgressTimer?.cancel();
    _audioPlayer.closePlayer();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Create a version of _getCurrentLocation that doesn't use localization for initState
  Future<void> _getCurrentLocationWithoutLocalization() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = '';
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled';
          _isLoadingLocation = false;
        });
        return;
      }

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      // Handle permanently denied permissions
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permissions are permanently denied';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      debugPrint('Got location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _locationError = 'Failed to get location: ${e.toString()}';
        _isLoadingLocation = false;
      });
    }
  }

  // Get current user location with better error handling (localized version)
  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    setState(() {
      _isLoadingLocation = true;
      _locationError = '';
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = l10n.locationServicesDisabled;
          _isLoadingLocation = false;
        });
        return;
      }

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = l10n.locationPermissionDenied;
            _isLoadingLocation = false;
          });
          return;
        }
      }

      // Handle permanently denied permissions
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = l10n.locationPermissionsPermanentlyDenied;
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      debugPrint(
          '${l10n.gotLocation}: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _locationError = '${l10n.failedToGetLocation}: ${e.toString()}';
        _isLoadingLocation = false;
      });
    }
  }

  // Add a method to refresh the location periodically
  void _startLocationUpdates() {
    // Refresh location every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        // Use the localized version for periodic updates
        _getCurrentLocation();
      } else {
        timer.cancel();
      }
    });
  }

  // Add this method to print detailed debug information about the posts
  void _debugPostsData(List<Post> posts) {
    debugPrint('--- DEBUG POSTS DATA ---');
    debugPrint('Found ${posts.length} posts');

    for (int i = 0; i < posts.length; i++) {
      final post = posts[i];
      debugPrint('Post ${i + 1}: ${post.id}');
      debugPrint('  - UserID: ${post.userId}');
      debugPrint('  - UserName: ${post.userName}');
      debugPrint('  - UserAvatar: ${post.userAvatar}');
      debugPrint('  - isProfessional: ${post.isProfessional}');
      debugPrint('  - Rating: ${post.rating}');
      debugPrint('  - ReviewCount: ${post.reviewCount}');
    }
    debugPrint('----------------------');
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // First ensure we have the user's city
      if (_userHomeCity == null) {
        await _fetchUserCity();
      }

      // Get all approved posts without filtering by city initially
      final posts = await _postService.getPosts();

      // Debug log to confirm we're only getting approved posts
      debugPrint('Fetched ${posts.length} approved posts for homepage');

      // Debug post information
      _debugPostsData(posts);

      // Extract unique cities for filter list from all posts
      _updateCityFiltersList(posts);

      // Precalculate distances from user's home city to all post cities
      if (_userHomeCity != null && _userHomeCity!.isNotEmpty) {
        await _precalculateDistances(posts);
      } else {
        debugPrint(
            'Cannot precalculate distances - user home city is not available');
      }

      setState(() {
        _posts.clear();
        _posts.addAll(posts);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load posts: ${e.toString()}';
      });
    }
  }

  // Add new method to extract unique cities from posts
  void _updateCityFiltersList(List<Post> posts) {
    // Start with 'All' and then add unique normalized cities
    final Set<String> uniqueCities = {'All'};

    // Add normalized cities from posts
    for (final post in posts) {
      if (post.city.isNotEmpty) {
        final normalizedCity = CityMappingService.normalizeCityName(post.city);
        uniqueCities.add(normalizedCity);
      }
    }

    // Sort cities alphabetically (but keep 'All' at first position)
    final sortedCities = uniqueCities.toList()
      ..sort((a, b) {
        if (a == 'All') return -1;
        if (b == 'All') return 1;
        return a.compareTo(b);
      });

    debugPrint(
        'Updated city filters list with ${sortedCities.length - 1} unique normalized cities');
    setState(() {
      _cities = sortedCities;
    });
  }

  Future<void> _refreshPosts() async {
    return _fetchPosts();
  }

  // Add this method to get localized activities
  List<String> _getLocalizedActivities(AppLocalizations l10n) {
    return [
      l10n.all,
      l10n.plumber,
      l10n.electrician,
      l10n.woodWorker,
      l10n.painter,
      l10n.carpenter,
      l10n.mason,
      l10n.gardener,
      l10n.cleaner,
      l10n.other
    ];
  }

  // Add method to get English activity key from localized display name
  String? _getActivityKeyFromLocalizedName(
      String localizedName, AppLocalizations l10n) {
    final localizedActivities = _getLocalizedActivities(l10n);
    final englishActivities = [
      'All',
      'Plumber',
      'Electrician',
      'Wood Worker',
      'Painter',
      'Carpenter',
      'Mason',
      'Gardener',
      'Cleaner',
      'Other'
    ];

    final index = localizedActivities.indexOf(localizedName);
    if (index != -1 && index < englishActivities.length) {
      return englishActivities[index];
    }
    return null;
  }

  // Modified filtering method to handle localized activities
  List<Post> _getFilteredPosts() {
    final l10n = AppLocalizations.of(context);

    return _posts.where((post) {
      // Filter by city only if explicitly selected - use normalized comparison
      if (_selectedCity != null && _selectedCity != l10n.all) {
        final normalizedSelectedCity =
            CityMappingService.normalizeCityName(_selectedCity!);
        final normalizedPostCity =
            CityMappingService.normalizeCityName(post.city);

        if (normalizedSelectedCity != normalizedPostCity) {
          return false;
        }
      }

      // Filter by activity - convert localized name to English key for comparison
      if (_selectedActivity != null && _selectedActivity != l10n.all) {
        final activityKey =
            _getActivityKeyFromLocalizedName(_selectedActivity!, l10n);
        if (activityKey != null && post.activity != activityKey) {
          return false;
        }
      }

      // Filter by post type
      if (_selectedPostType != null && post.type != _selectedPostType) {
        return false;
      }

      // Filter by distance ONLY if distance filter is explicitly selected
      if (_selectedDistance != null && _userHomeCity != null) {
        // Use normalized city names for distance calculation
        double? distanceInKm = _getDistanceBetweenCities(post.city);

        // Only fall back to GPS if city-based distance is not available
        if (distanceInKm == null &&
            _currentPosition != null &&
            post.latitude != null &&
            post.longitude != null) {
          try {
            double distanceInMeters = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                post.latitude!,
                post.longitude!);

            distanceInKm = distanceInMeters / 1000;
            debugPrint(
                'Using GPS-based distance for post ${post.id}: $distanceInKm km');
          } catch (e) {
            debugPrint('Error calculating distance for post ${post.id}: $e');
          }
        }

        // Filter out if distance is available and exceeds the selected distance
        if (distanceInKm != null) {
          debugPrint(
              'Post ${post.id} distance: $distanceInKm km, filter: $_selectedDistance km');
          if (distanceInKm > _selectedDistance!) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _selectedCity = null;
      _selectedActivity = null;
      _selectedPostType = null;
      _selectedDistance = null;
    });
  }

  // Add method to fetch audio duration
  Future<void> _fetchAudioDuration(String postId, String audioUrl) async {
    // Check if we already have this audio's duration in cache
    if (_audioDurations.containsKey(postId)) {
      return;
    }

    try {
      // Temporarily load the audio to get its duration without playing
      final FlutterSoundPlayer tempPlayer = FlutterSoundPlayer();
      await tempPlayer.openPlayer();

      // Use this method to get the duration
      await tempPlayer.startPlayer(
        fromURI: audioUrl,
        codec: Codec.aacADTS,
        whenFinished: () async {
          await tempPlayer.stopPlayer();
        },
      );

      // Wait briefly to ensure the player has started and metadata is available
      await Future.delayed(const Duration(milliseconds: 300));

      // Get the duration
      Duration? duration =
          await tempPlayer.getProgress().then((value) => value['duration']);
      await tempPlayer.stopPlayer();
      await tempPlayer.closePlayer();

      // Store in cache and update UI if duration was retrieved
      if (duration != null && duration.inMilliseconds > 0) {
        setState(() {
          _audioDurations[postId] = duration;
        });

        // Also update the post in the list to save duration for future
        final postIndex = _posts.indexWhere((post) => post.id == postId);
        if (postIndex != -1) {
          final post = _posts[postIndex];
          // Update Firestore with the audio duration for future use
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .update({
            'audioDuration': duration.inSeconds,
          });

          // Update locally
          final updatedPost = post.copyWith(
            audioDuration: duration.inSeconds,
          );
          _posts[postIndex] = updatedPost;
        }
      }
    } catch (e) {
      debugPrint('Error fetching audio duration: $e');
    }
  }

  Future<void> _playAudio(String audioUrl, String postId) async {
    if (_currentlyPlayingId == postId && _isPlaying) {
      await _stopAudio();
      return;
    }

    if (_isPlaying) {
      await _stopAudio();
    }

    try {
      // Reset audio progress tracking
      setState(() {
        _audioPosition = Duration.zero;
      });

      // If we have it in the cache, use it
      if (_audioDurations.containsKey(postId)) {
        setState(() {
          _audioDuration = _audioDurations[postId];
        });
      } else {
        // Find post to get stored duration if available
        final post = _posts.firstWhere((p) => p.id == postId,
            orElse: () => throw Exception('Post not found'));

        // Use the stored duration if available (fallback to 0)
        final storedDuration =
            post.audioDuration != null && post.audioDuration! > 0
                ? Duration(seconds: post.audioDuration!)
                : Duration.zero;

        setState(() {
          _audioDuration = storedDuration;
        });
      }

      // Play the audio
      await _audioPlayer.startPlayer(
        fromURI: audioUrl,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _currentlyPlayingId = '';
            _audioPosition = null;
          });
        },
      );

      setState(() {
        _isPlaying = true;
        _currentlyPlayingId = postId;
      });
    } catch (e) {
      debugPrint('Error playing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: ${e.toString()}')),
      );
    }
  }

  Future<void> _stopAudio() async {
    if (!_isPlaying) return;

    try {
      await _audioPlayer.stopPlayer();
      setState(() {
        _isPlaying = false;
        _currentlyPlayingId = '';
        _audioPosition = null;
      });
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildFilterBottomSheet();
      },
    );
  }

  Widget _buildFilterBottomSheet() {
    final l10n = AppLocalizations.of(context);
    final localizedActivities = _getLocalizedActivities(l10n);

    return StatefulBuilder(builder: (context, setModalState) {
      return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Title with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.filters,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 20.r),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Post Type Filter
                    Text(
                      l10n.postType,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        _buildTypeFilterChip(
                          PostType.request,
                          l10n.request,
                          setModalState,
                        ),
                        SizedBox(width: 8.w),
                        _buildTypeFilterChip(
                          PostType.offer,
                          l10n.offer,
                          setModalState,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // City Filter
                    Text(
                      l10n.city,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      height: 40.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text(l10n.selectCity),
                          value: _selectedCity,
                          items: _cities.map((String city) {
                            return DropdownMenuItem<String>(
                              value: city == 'All' ? null : city,
                              child: Text(
                                city == 'All' ? l10n.all : city,
                                style: TextStyle(fontSize: 14.sp),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setModalState(() {
                              _selectedCity = newValue;
                            });

                            setState(() {
                              _selectedCity = newValue;

                              if (newValue != null && newValue != 'All') {
                                _selectedDistance = _defaultDistanceFilter;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Distance filters - fixed condition
                    if (_selectedCity != null && _selectedCity != 'All')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.distance,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: _distanceOptions.map((distance) {
                              return Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: _buildDistanceFilterChipForModal(
                                    distance, setModalState),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 8.h),
                        ],
                      ),

                    // Activity Filter
                    Text(
                      l10n.activity,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 8.h),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: localizedActivities
                              .map((activity) => _buildActivityFilterChip(
                                  activity, setModalState, l10n))
                              .toList(),
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Apply and Clear buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedCity = null;
                                _selectedActivity = null;
                                _selectedPostType = null;
                                _selectedDistance = null;
                              });

                              setState(() {
                                _selectedCity = null;
                                _selectedActivity = null;
                                _selectedPostType = null;
                                _selectedDistance = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              side: const BorderSide(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            child: Text(
                              l10n.clearFilters,
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text(
                              l10n.apply,
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ));
    });
  }

  // More compact distance filter chips for the modal
  Widget _buildDistanceFilterChipForModal(
      int distance, StateSetter setModalState) {
    final l10n = AppLocalizations.of(context);
    final isSelected = _selectedDistance == distance;

    return ChoiceChip(
      label: Text(l10n.kmDistance(distance)),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          _selectedDistance = selected ? distance : null;
        });

        setState(() {
          _selectedDistance = selected ? distance : null;
        });
      },
      backgroundColor: Colors.grey.withOpacity(0.1),
      selectedColor: AppTheme.primaryColor.withOpacity(0.8),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
        fontSize: 12.sp,
      ),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  // More compact type filter chips
  Widget _buildTypeFilterChip(
      PostType type, String label, StateSetter setModalState) {
    final isSelected = _selectedPostType == type;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setModalState(() {
            _selectedPostType = isSelected ? null : type;
          });

          setState(() {
            _selectedPostType = isSelected ? null : type;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h), // Reduced from 12.h
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r), // Reduced from 12.r
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : theme.colorScheme.outline.withOpacity(0.5),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 14.sp, // Specify smaller font size
            ),
          ),
        ),
      ),
    );
  }

  // More compact activity filter chips - Updated to handle localization
  Widget _buildActivityFilterChip(
      String activity, StateSetter setModalState, AppLocalizations l10n) {
    final isSelected = _selectedActivity == activity;

    return ChoiceChip(
      label: Text(
        activity,
        style: TextStyle(
          fontSize: 12.sp,
          color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          _selectedActivity = selected ? activity : null;
          if (activity == l10n.all) _selectedActivity = null;
        });

        setState(() {
          _selectedActivity = selected ? activity : null;
          if (activity == l10n.all) _selectedActivity = null;
        });
      },
      backgroundColor: Colors.grey.withOpacity(0.1),
      selectedColor: AppTheme.primaryColor.withOpacity(0.8),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  // More compact distance filter chips for the main UI
  Widget _buildDistanceFilterChip(int distance) {
    final l10n = AppLocalizations.of(context);
    final isSelected = _selectedDistance == distance;

    return ChoiceChip(
      label: Text(l10n.kmDistance(distance)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDistance = selected ? distance : null;

          if (selected && _currentPosition == null) {
            _getCurrentLocation();
          }
        });
      },
      backgroundColor: Colors.grey.withOpacity(0.1),
      selectedColor: AppTheme.primaryColor.withOpacity(0.8),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
        fontSize: 11.sp,
      ),
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  // More compact filter indicator
  Widget _buildFilterIndicator() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bool hasActiveFilters = _selectedCity != null ||
        _selectedActivity != null ||
        _selectedPostType != null ||
        _selectedDistance != null;

    if (!hasActiveFilters) return const SizedBox.shrink();

    List<String> activeFilters = [];
    if (_selectedCity != null) activeFilters.add(_selectedCity!);
    if (_selectedActivity != null) activeFilters.add(_selectedActivity!);
    if (_selectedPostType != null) {
      activeFilters.add(
          _selectedPostType == PostType.request ? l10n.request : l10n.offer);
    }
    if (_selectedDistance != null) {
      if (_currentPosition == null) {
        activeFilters.add(l10n.waitingForLocation(_selectedDistance!));
      } else {
        activeFilters.add(l10n.kmDistance(_selectedDistance!));
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      margin: EdgeInsets.only(bottom: 6.h),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 18.w,
            color: AppTheme.primaryColor,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '${l10n.activeFilters}: ${activeFilters.join(", ")}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _resetFilters,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 14.w,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add method to fetch the user's home city
  Future<void> _fetchUserCity() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        debugPrint('Cannot fetch user city - user not logged in');
        return;
      }

      // Get user city from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        final city = userData['city'] as String?;

        if (city != null && city.isNotEmpty) {
          setState(() {
            _userHomeCity = city;
          });
          debugPrint('User home city fetched: $_userHomeCity');
          return;
        }
      }

      debugPrint('No city found in user document, falling back to PostService');

      // Fallback to the PostService method if available
      final city = await _postService.getCurrentUserCity();
      setState(() {
        _userHomeCity = city;
      });
      debugPrint('User home city fetched from service: $_userHomeCity');
    } catch (e) {
      debugPrint('Error fetching user city: $e');
    }
  }

  // Add method to precalculate distances between cities
  Future<void> _precalculateDistances(List<Post> posts) async {
    if (!mounted) return;

    // Use fallback message if localization is not available yet
    String debugMessage =
        'Cannot precalculate distances - user home city is not available';
    try {
      final l10n = AppLocalizations.of(context);
      debugMessage = l10n.cannotPrecalculateDistances;
    } catch (e) {
      // Localization not available yet, use fallback
    }

    if (_userHomeCity == null) {
      debugPrint(debugMessage);
      return;
    }

    setState(() {
      _isCalculatingDistances = true;
    });

    final normalizedUserCity =
        CityMappingService.normalizeCityName(_userHomeCity!);
    debugPrint(
        'Precalculating distances from $normalizedUserCity to post cities...');

    try {
      final uniqueCities = <String>{};
      for (final post in posts) {
        if (post.city.isNotEmpty) {
          final normalizedPostCity =
              CityMappingService.normalizeCityName(post.city);
          if (normalizedPostCity != normalizedUserCity) {
            uniqueCities.add(normalizedPostCity);
          }
        }
      }

      debugPrint(
          'Found ${uniqueCities.length} unique normalized cities in posts');

      int calculatedCount = 0;
      for (final city in uniqueCities) {
        if (_distanceBetweenCities.containsKey(normalizedUserCity) &&
            _distanceBetweenCities[normalizedUserCity]!.containsKey(city)) {
          debugPrint(
              'Distance from $normalizedUserCity to $city already calculated: ${_distanceBetweenCities[normalizedUserCity]![city]} km');
          continue;
        }

        final distance = await _geocodingService.calculateDistanceBetweenCities(
          normalizedUserCity,
          city,
        );

        if (distance != null) {
          _distanceBetweenCities[normalizedUserCity] ??= {};
          _distanceBetweenCities[normalizedUserCity]![city] = distance;
          debugPrint(
              'Calculated distance from $normalizedUserCity to $city: $distance km');
          calculatedCount++;
        } else {
          debugPrint(
              'Failed to calculate distance between $normalizedUserCity and $city');
        }
      }

      // Use fallback message if localization is not available yet
      String successMessage =
          'Successfully calculated $calculatedCount new distances';
      try {
        final l10n = AppLocalizations.of(context);
        successMessage =
            '${l10n.userHomeCityFetched}: Successfully calculated $calculatedCount new distances';
      } catch (e) {
        // Localization not available yet, use fallback
      }

      debugPrint(successMessage);
    } catch (e) {
      debugPrint('Error precalculating distances: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCalculatingDistances = false;
        });
      }
    }
  }

  // Method to get distance between cities using normalized names
  double? _getDistanceBetweenCities(String postCity) {
    if (_userHomeCity == null) {
      debugPrint('Cannot get distance - user home city is null');
      return null;
    }

    // Normalize both city names for comparison
    final normalizedUserCity =
        CityMappingService.normalizeCityName(_userHomeCity!);
    final normalizedPostCity = CityMappingService.normalizeCityName(postCity);

    // Same city check with normalized names
    if (normalizedUserCity == normalizedPostCity) {
      debugPrint(
          'Same city (normalized): $normalizedUserCity = $normalizedPostCity, distance is 0');
      return 0; // Same city
    }

    // Check if we have pre-calculated this distance using normalized names
    if (_distanceBetweenCities.containsKey(normalizedUserCity) &&
        _distanceBetweenCities[normalizedUserCity]!
            .containsKey(normalizedPostCity)) {
      final distance =
          _distanceBetweenCities[normalizedUserCity]![normalizedPostCity];
      debugPrint(
          'Found precalculated distance between $normalizedUserCity and $normalizedPostCity: $distance km');
      return distance;
    }

    // Check for any variations in the distance map
    for (final userCity in _distanceBetweenCities.keys) {
      final normalizedMapUserCity =
          CityMappingService.normalizeCityName(userCity);
      if (normalizedMapUserCity == normalizedUserCity) {
        for (final city in _distanceBetweenCities[userCity]!.keys) {
          final normalizedMapCity = CityMappingService.normalizeCityName(city);
          if (normalizedMapCity == normalizedPostCity) {
            final distance = _distanceBetweenCities[userCity]![city];
            debugPrint(
                'Found distance with normalization between $normalizedUserCity and $normalizedPostCity: $distance km');
            return distance;
          }
        }
      }
    }

    debugPrint(
        'No precalculated distance between $normalizedUserCity and $normalizedPostCity');
    return null; // Distance not calculated yet
  }

  // Method to navigate to add post
  void _navigateToAddPost() {
    if (widget.onNavigateToAddPost != null) {
      widget.onNavigateToAddPost!();
    }
  }

  // Method to build post item
  Widget _buildPostItem(Post post, int index) {
    // Only pass audio progress for currently playing post
    final isCurrentlyPlaying = _isPlaying && _currentlyPlayingId == post.id;

    // Get duration either from cache or post metadata
    Duration? duration;
    if (_audioDurations.containsKey(post.id)) {
      duration = _audioDurations[post.id];
    } else if (post.audioDuration != null && post.audioDuration! > 0) {
      duration = Duration(seconds: post.audioDuration!);
    }

    // Calculate city-based distance if available
    double? distanceInKm;
    if (_userHomeCity != null && post.city != _userHomeCity) {
      distanceInKm = _getDistanceBetweenCities(post.city);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: PostCard(
        post: post,
        isPlayingAudio: isCurrentlyPlaying,
        onPlayAudio: (url) => _playAudio(url, post.id),
        onStopAudio: _stopAudio,
        onLikeUpdated: (isLiked, likeCount) {
          _updatePostLikeStatus(post.id, isLiked, likeCount);
        },
        currentPosition: _currentPosition,
        // Pass audio progress information
        audioDuration: isCurrentlyPlaying ? _audioDuration : duration,
        audioProgress: isCurrentlyPlaying ? _audioPosition : null,
        // Add callback to fetch audio duration if needed
        onNeedDuration: _fetchAudioDuration,
        // Pass the precalculated distance
        distanceFromUserCity: distanceInKm,
        userHomeCity: _userHomeCity,
      ),
    );
  }

  // Update post like status
  void _updatePostLikeStatus(String postId, bool isLiked, int likeCount) {
    setState(() {
      // Find the post in the list and update only its like status
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        final updatedPost = _posts[postIndex].copyWith(
          isLiked: isLiked,
          likes: likeCount,
        );
        _posts[postIndex] = updatedPost;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filteredPosts = _getFilteredPosts();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24.r),
            bottomRight: Radius.circular(24.r),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                ),
              ),
              shadowColor: Colors.grey.withOpacity(0.2),
              surfaceTintColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24.r),
                    bottomRight: Radius.circular(24.r),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                ),
              ),
              title: Image.asset(
                'assets/logo.png',
                height: 40.h,
                fit: BoxFit.cover,
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(
                  Icons.filter_list,
                  color: AppTheme.textSecondaryColor,
                ),
                onPressed: _showFiltersBottomSheet,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background patterns
          Positioned(
            top: -50.h,
            left: -50.w,
            child: Container(
              height: 200.h,
              width: 200.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -100.h,
            right: -60.w,
            child: Container(
              height: 250.h,
              width: 250.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.1),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                    ? _buildErrorState()
                    : _posts.isEmpty
                        ? _buildEmptyState()
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8.h),

                                // Search bar
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.w),
                                  child: GestureDetector(
                                    onTap: _navigateToAddPost,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.w),
                                      height: 50.h,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.search,
                                            color: Colors.grey[400],
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: TextField(
                                              controller: _searchController,
                                              enabled: false,
                                              decoration: InputDecoration(
                                                hintText:
                                                    l10n.whatAreYouLookingFor,
                                                hintStyle: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 14.sp,
                                                ),
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 8.h),

                                // User location indicator
                                if (_userHomeCity != null)
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.w),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.03),
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                        border: Border.all(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.2),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 18.w,
                                            color: AppTheme.primaryColor,
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            l10n.yourLocation(_userHomeCity!),
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                SizedBox(height: 6.h),

                                // Distance filters
                                if (_currentPosition != null)
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.w),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${l10n.distance}:',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Wrap(
                                          spacing: 4.w,
                                          children: _distanceOptions
                                              .map((distance) =>
                                                  _buildDistanceFilterChip(
                                                      distance))
                                              .toList(),
                                        ),
                                        if (_selectedDistance != null)
                                          IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              size: 16.w,
                                              color: AppTheme.primaryColor,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: () {
                                              setState(() {
                                                _selectedDistance = null;
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  ),

                                // Filter indicators
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.w),
                                  child: _buildFilterIndicator(),
                                ),

                                SizedBox(height: 6.h),

                                // Posts list
                                Expanded(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.w),
                                    child: RefreshIndicator(
                                      onRefresh: _refreshPosts,
                                      child: filteredPosts.isEmpty
                                          ? _buildNoResultsState()
                                          : ListView.builder(
                                              physics:
                                                  const AlwaysScrollableScrollPhysics(),
                                              itemCount: filteredPosts.length,
                                              itemBuilder: (context, index) {
                                                return _buildPostItem(
                                                    filteredPosts[index],
                                                    index);
                                              },
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.post_add,
            size: 80.w,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.noPosts,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.createFirstPost,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _navigateToAddPost,
            icon: const Icon(Icons.add),
            label: Text(l10n.addPost),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80.w,
            color: Colors.red[300],
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.errorLoadingPosts,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.pleaseRetry,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _refreshPosts,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Icon(
              Icons.search_off,
              size: 80.w,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.noMatchingResults,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.tryDifferentFilters,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: Text(l10n.clearFilters),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
