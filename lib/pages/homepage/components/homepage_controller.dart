import 'package:flutter/material.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:achno/models/post_model.dart';
import 'package:achno/services/post_service.dart';
import 'package:achno/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:achno/services/geocoding_service.dart';
import 'package:achno/services/city_mapping_service.dart';

class HomepageController extends ChangeNotifier {
  final PostService _postService = PostService();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  final GeocodingService _geocodingService = GeocodingService();

  // State variables
  bool _isLoading = false;
  bool _hasError = false;
  final List<Post> _posts = [];
  String? _selectedCity;
  String? _selectedActivity;
  PostType? _selectedPostType;
  int? _selectedDistance;
  final List<int> _distanceOptions = [5, 10, 25];
  final int _defaultDistanceFilter = 10;

  HomepageController() {
    _selectedDistance = _defaultDistanceFilter;
  }

  // Cache variables
  DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 2);
  bool _isInitialized = false;
  List<Post> _cachedPosts = [];

  // Audio state
  String _currentlyPlayingId = '';
  bool _isPlaying = false;
  Duration? _audioDuration;
  Duration? _audioPosition;
  Timer? _audioProgressTimer;
  StreamSubscription? _playerSubscription;
  final Map<String, Duration> _audioDurations = {};

  // Location state
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String _locationError = '';

  // Distance calculation state
  final Map<String, Map<String, double>> _distanceBetweenCities = {};
  bool _isCalculatingDistances = false;
  String? _userHomeCity;

  // Filter options
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
  List<String> _cities = ['All'];

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _errorMessage = '';

  // Getters
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  List<Post> get posts => _posts;
  String? get selectedCity => _selectedCity;
  String? get selectedActivity => _selectedActivity;
  PostType? get selectedPostType => _selectedPostType;
  int? get selectedDistance => _selectedDistance;
  List<int> get distanceOptions => _distanceOptions;
  int get defaultDistanceFilter => _defaultDistanceFilter;
  String get currentlyPlayingId => _currentlyPlayingId;
  bool get isPlaying => _isPlaying;
  Duration? get audioDuration => _audioDuration;
  Duration? get audioPosition => _audioPosition;
  Position? get currentPosition => _currentPosition;
  bool get isLoadingLocation => _isLoadingLocation;
  String get locationError => _locationError;
  bool get isCalculatingDistances => _isCalculatingDistances;
  String? get userHomeCity => _userHomeCity;
  List<String> get activities => _activities;
  List<String> get cities => _cities;
  TextEditingController get searchController => _searchController;
  String get errorMessage => _errorMessage;
  Map<String, Duration> get audioDurations => _audioDurations;
  Map<String, Map<String, double>> get distanceBetweenCities =>
      _distanceBetweenCities;

  @override
  void dispose() {
    _stopAudio();
    _playerSubscription?.cancel();
    _audioProgressTimer?.cancel();
    _audioPlayer.closePlayer();
    _searchController.dispose();
    super.dispose();
  }

  // Audio methods
  Future<void> initAudioPlayer() async {
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

      _playerSubscription = _audioPlayer.onProgress?.listen((event) {
        _audioPosition = event.position;
        _audioDuration = event.duration;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  Future<void> playAudio(String audioUrl, String postId) async {
    if (_currentlyPlayingId == postId && _isPlaying) {
      await _stopAudio();
      return;
    }

    if (_isPlaying) {
      await _stopAudio();
    }

    try {
      _audioPosition = Duration.zero;
      notifyListeners();

      if (_audioDurations.containsKey(postId)) {
        _audioDuration = _audioDurations[postId];
        notifyListeners();
      } else {
        final post = _posts.firstWhere((p) => p.id == postId,
            orElse: () => throw Exception('Post not found'));

        final storedDuration =
            post.audioDuration != null && post.audioDuration! > 0
                ? Duration(seconds: post.audioDuration!)
                : Duration.zero;

        _audioDuration = storedDuration;
        notifyListeners();
      }

      await _audioPlayer.startPlayer(
        fromURI: audioUrl,
        codec: Codec.aacADTS,
        whenFinished: () {
          _isPlaying = false;
          _currentlyPlayingId = '';
          _audioPosition = null;
          notifyListeners();
        },
      );

      _isPlaying = true;
      _currentlyPlayingId = postId;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> _stopAudio() async {
    if (!_isPlaying) return;

    try {
      await _audioPlayer.stopPlayer();
      _isPlaying = false;
      _currentlyPlayingId = '';
      _audioPosition = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  Future<void> fetchAudioDuration(String postId, String audioUrl) async {
    if (_audioDurations.containsKey(postId)) {
      return;
    }

    try {
      final FlutterSoundPlayer tempPlayer = FlutterSoundPlayer();
      await tempPlayer.openPlayer();

      await tempPlayer.startPlayer(
        fromURI: audioUrl,
        codec: Codec.aacADTS,
        whenFinished: () async {
          await tempPlayer.stopPlayer();
        },
      );

      await Future.delayed(const Duration(milliseconds: 300));

      Duration? duration =
          await tempPlayer.getProgress().then((value) => value['duration']);
      await tempPlayer.stopPlayer();
      await tempPlayer.closePlayer();

      if (duration != null && duration.inMilliseconds > 0) {
        _audioDurations[postId] = duration;
        notifyListeners();

        final postIndex = _posts.indexWhere((post) => post.id == postId);
        if (postIndex != -1) {
          final post = _posts[postIndex];
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .update({
            'audioDuration': duration.inSeconds,
          });

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

  // Location methods
  Future<void> getCurrentLocationWithoutLocalization() async {
    _isLoadingLocation = true;
    _locationError = '';
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = 'Location services are disabled';
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationError = 'Location permission denied';
          _isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationError = 'Location permissions are permanently denied';
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = position;
      _isLoadingLocation = false;
      notifyListeners();

      debugPrint('Got location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('Error getting location: $e');
      _locationError = 'Failed to get location: ${e.toString()}';
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  Future<void> getCurrentLocation(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    _isLoadingLocation = true;
    _locationError = '';
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = l10n.locationServicesDisabled;
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationError = l10n.locationPermissionDenied;
          _isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationError = l10n.locationPermissionsPermanentlyDenied;
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = position;
      _isLoadingLocation = false;
      notifyListeners();

      debugPrint(
          '${l10n.gotLocation}: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('Error getting location: $e');
      _locationError = '${l10n.failedToGetLocation}: ${e.toString()}';
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  void startLocationUpdates(BuildContext context) {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      getCurrentLocation(context);
    });
  }

  // Posts methods
  Future<void> fetchPosts([BuildContext? context]) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      debugPrint('Starting to fetch posts...');

      // Check if posts are cached and valid
      if (_isInitialized &&
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration &&
          _cachedPosts.isNotEmpty) {
        debugPrint('Using cached posts.');
        _posts.clear();
        _posts.addAll(_cachedPosts);
        _isLoading = false;
        debugPrint(
            'Posts loaded successfully from cache. Loading state set to false. Posts count: ${_posts.length}');
        notifyListeners();
        return;
      }

      // Fetch posts first - don't wait for user city
      final posts = await _postService.getPosts();
      debugPrint('Fetched ${posts.length} approved posts for homepage');

      if (posts.isNotEmpty) {
        _debugPostsData(posts);
        _updateCityFiltersList(posts);

        // Update posts immediately
        _posts.clear();
        _posts.addAll(posts);
        // Cache the posts
        _cachedPosts = List.from(posts);
        _lastFetchTime = DateTime.now();
        _isInitialized = true;
        _isLoading = false;
        debugPrint(
            'Posts loaded successfully. Loading state set to false. Posts count: ${_posts.length}');
        notifyListeners();
      } else {
        // No posts found
        _posts.clear();
        _isLoading = false;
        debugPrint('No posts found. Loading state set to false.');
        notifyListeners();
      }

      // Try to fetch user city in background (non-blocking)
      if (_userHomeCity == null) {
        _fetchUserCityInBackground(context);
      }

      // Try to precalculate distances in background if user city is available
      if (_userHomeCity != null &&
          _userHomeCity!.isNotEmpty &&
          posts.isNotEmpty) {
        _precalculateDistancesInBackground(posts);
      }
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Failed to load posts: ${e.toString()}';
      debugPrint('Error fetching posts: $e');
      notifyListeners();
    }
  }

  // Background method to fetch user city without blocking the UI
  Future<void> _fetchUserCityInBackground([BuildContext? context]) async {
    try {
      await fetchUserCity(context);
      debugPrint('User city fetched in background: $_userHomeCity');

      // If we now have user city and posts, try to precalculate distances
      if (_userHomeCity != null &&
          _userHomeCity!.isNotEmpty &&
          _posts.isNotEmpty) {
        await _precalculateDistancesInBackground(_posts);
      }
    } catch (e) {
      debugPrint('Failed to fetch user city in background: $e');
    }
  }

  // Background method to precalculate distances without blocking the UI
  Future<void> _precalculateDistancesInBackground(List<Post> posts) async {
    if (_userHomeCity == null) {
      debugPrint(
          'Cannot precalculate distances - user home city is not available');
      return;
    }

    _isCalculatingDistances = true;
    notifyListeners();

    try {
      final normalizedUserCity =
          CityMappingService.normalizeCityName(_userHomeCity!);
      debugPrint(
          'Precalculating distances from $normalizedUserCity to post cities...');

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

      debugPrint('Successfully calculated $calculatedCount new distances');
    } catch (e) {
      debugPrint('Error precalculating distances: $e');
    } finally {
      _isCalculatingDistances = false;
      notifyListeners();
    }
  }

  Future<void> refreshPosts([BuildContext? context]) async {
    // Clear cache to force fresh fetch
    _lastFetchTime = null;
    _cachedPosts.clear();
    _isInitialized = false;
    return fetchPosts(context);
  }

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

  void _updateCityFiltersList(List<Post> posts) {
    final Set<String> uniqueCities = {'All'};

    for (final post in posts) {
      if (post.city.isNotEmpty) {
        final normalizedCity = CityMappingService.normalizeCityName(post.city);
        uniqueCities.add(normalizedCity);
      }
    }

    final sortedCities = uniqueCities.toList()
      ..sort((a, b) {
        if (a == 'All') return -1;
        if (b == 'All') return 1;
        return a.compareTo(b);
      });

    debugPrint(
        'Updated city filters list with ${sortedCities.length - 1} unique normalized cities');
    _cities = sortedCities;
    notifyListeners();
  }

  // Filter methods
  List<Post> getFilteredPosts(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return _posts.where((post) {
      if (_selectedCity != null && _selectedCity != l10n.all) {
        final normalizedSelectedCity =
            CityMappingService.normalizeCityName(_selectedCity!);
        final normalizedPostCity =
            CityMappingService.normalizeCityName(post.city);

        if (normalizedSelectedCity != normalizedPostCity) {
          return false;
        }
      }

      if (_selectedActivity != null && _selectedActivity != l10n.all) {
        final activityKey =
            _getActivityKeyFromLocalizedName(_selectedActivity!, l10n);
        if (activityKey != null && post.activity != activityKey) {
          return false;
        }
      }

      if (_selectedPostType != null && post.type != _selectedPostType) {
        return false;
      }

      if (_selectedDistance != null && _userHomeCity != null) {
        double? distanceInKm = getDistanceBetweenCities(post.city);

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

  List<String> getLocalizedActivities(AppLocalizations l10n) {
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

  String? _getActivityKeyFromLocalizedName(
      String localizedName, AppLocalizations l10n) {
    final localizedActivities = getLocalizedActivities(l10n);
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

  void resetFilters() {
    _selectedCity = null;
    _selectedActivity = null;
    _selectedPostType = null;
    _selectedDistance = null;
    notifyListeners();
  }

  void setSelectedCity(String? city) {
    _selectedCity = city;
    if (city != null && city != 'All') {
      _selectedDistance = _defaultDistanceFilter;
    }
    notifyListeners();
  }

  void setSelectedActivity(String? activity) {
    _selectedActivity = activity;
    notifyListeners();
  }

  void setSelectedPostType(PostType? type) {
    _selectedPostType = type;
    notifyListeners();
  }

  void setSelectedDistance(int? distance) {
    _selectedDistance = distance;
    notifyListeners();
  }

  // User city methods
  Future<void> fetchUserCity([BuildContext? context]) async {
    try {
      BuildContext? currentContext = context ?? navigatorKey.currentContext;

      if (currentContext == null) {
        debugPrint('Cannot fetch user city - no context available');
        return;
      }

      final authProvider =
          Provider.of<AuthProvider>(currentContext, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        debugPrint('Cannot fetch user city - user not logged in');
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        final city = userData['city'] as String?;

        if (city != null && city.isNotEmpty) {
          _userHomeCity = city;
          notifyListeners();
          debugPrint('User home city fetched: $_userHomeCity');
          return;
        }
      }

      debugPrint('No city found in user document, falling back to PostService');

      final city = await _postService.getCurrentUserCity();
      _userHomeCity = city;
      notifyListeners();
      debugPrint('User home city fetched from service: $_userHomeCity');
    } catch (e) {
      debugPrint('Error fetching user city: $e');
    }
  }

  // Distance calculation methods
  double? getDistanceBetweenCities(String postCity) {
    if (_userHomeCity == null) {
      debugPrint('Cannot get distance - user home city is null');
      return null;
    }

    final normalizedUserCity =
        CityMappingService.normalizeCityName(_userHomeCity!);
    final normalizedPostCity = CityMappingService.normalizeCityName(postCity);

    if (normalizedUserCity == normalizedPostCity) {
      debugPrint(
          'Same city (normalized): $normalizedUserCity = $normalizedPostCity, distance is 0');
      return 0;
    }

    if (_distanceBetweenCities.containsKey(normalizedUserCity) &&
        _distanceBetweenCities[normalizedUserCity]!
            .containsKey(normalizedPostCity)) {
      final distance =
          _distanceBetweenCities[normalizedUserCity]![normalizedPostCity];
      debugPrint(
          'Found precalculated distance between $normalizedUserCity and $normalizedPostCity: $distance km');
      return distance;
    }

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
    return null;
  }

  // Post update methods
  void updatePostLikeStatus(String postId, bool isLiked, int likeCount) {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex != -1) {
      final updatedPost = _posts[postIndex].copyWith(
        isLiked: isLiked,
        likes: likeCount,
      );
      _posts[postIndex] = updatedPost;
      notifyListeners();
    }
  }
}

// Global navigator key for accessing context in controller
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
