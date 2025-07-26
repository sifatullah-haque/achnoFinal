import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:achno/providers/auth_provider.dart';
import 'package:achno/services/city_mapping_service.dart';
import 'package:achno/services/notification_service.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audio_session/audio_session.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

class AddPostController extends ChangeNotifier {
  // Form controllers
  final TextEditingController messageController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController activityController = TextEditingController();

  // Form state
  String? _selectedActivity;
  String? _selectedDuration = 'Unlimited';
  bool _isLoading = false;
  String _errorMessage = '';

  // Audio recording state
  String? _recordedAudioPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  PermissionStatus _micPermissionStatus = PermissionStatus.denied;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  final int _maxRecordingDuration = 60;

  // Audio components
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _recorderInitialized = false;

  // Audio visualization
  final List<double> _audioWaveform = [];
  final int _maxWaveformPoints = 30;

  // Google Places API
  final places = GoogleMapsPlaces(
    apiKey: 'AIzaSyD3Mr3cCo8RIrkqbR-seZaUODMxFrfvLSI',
  );
  List<dynamic> _placePredictions = [];

  // Notification service
  final NotificationService _notificationService = NotificationService();

  // Activity options
  final List<Map<String, dynamic>> _mainActivities = [
    {'name': 'Plumber', 'key': 'plumber', 'icon': Icons.plumbing},
    {
      'name': 'Electrician',
      'key': 'electrician',
      'icon': Icons.electrical_services
    },
    {'name': 'Painter', 'key': 'painter', 'icon': Icons.format_paint},
    {'name': 'Carpenter', 'key': 'carpenter', 'icon': Icons.carpenter},
    {'name': 'Mason', 'key': 'mason', 'icon': Icons.domain},
    {'name': 'Tiler', 'key': 'tiler', 'icon': Icons.grid_on},
  ];

  final List<Map<String, String>> _additionalActivities = [
    {'name': 'Gardener', 'key': 'gardener'},
    {'name': 'Cleaner', 'key': 'cleaner'},
    {'name': 'Roofer', 'key': 'roofer'},
    {'name': 'Welder', 'key': 'welder'},
    {'name': 'Window Installer', 'key': 'windowInstaller'},
    {'name': 'HVAC Technician', 'key': 'hvacTechnician'},
    {'name': 'Flooring Installer', 'key': 'flooringInstaller'},
    {'name': 'Landscaper', 'key': 'landscaper'},
    {'name': 'Other', 'key': 'other'},
  ];

  final List<Map<String, dynamic>> _durationOptions = [
    {
      'value': 'Unlimited',
      'labelKey': 'unlimited',
      'icon': Icons.all_inclusive
    },
    {'value': '48h', 'labelKey': 'hours48', 'icon': Icons.hourglass_bottom},
    {'value': '7d', 'labelKey': 'days7', 'icon': Icons.calendar_today},
    {'value': '30d', 'labelKey': 'days30', 'icon': Icons.date_range},
  ];

  // Getters
  String? get selectedActivity => _selectedActivity;
  String? get selectedDuration => _selectedDuration;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String? get recordedAudioPath => _recordedAudioPath;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  PermissionStatus get micPermissionStatus => _micPermissionStatus;
  int get recordingDuration => _recordingDuration;
  int get maxRecordingDuration => _maxRecordingDuration;
  bool get recorderInitialized => _recorderInitialized;
  List<double> get audioWaveform => _audioWaveform;
  List<dynamic> get placePredictions => _placePredictions;
  List<Map<String, dynamic>> get mainActivities => _mainActivities;
  List<Map<String, String>> get additionalActivities => _additionalActivities;
  List<Map<String, dynamic>> get durationOptions => _durationOptions;

  // Initialize controller
  Future<void> initialize(BuildContext context) async {
    await _initializeRecordingFunctionality();
    await _initializePlayer();
    await _fetchUserDefaultActivity(context);
    await _fetchUserDefaultCity(context);
  }

  // Initialize recording functionality
  Future<void> _initializeRecordingFunctionality() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.storage,
      ].request();

      bool allGranted = statuses.values.every((status) => status.isGranted);

      _micPermissionStatus =
          statuses[Permission.microphone] ?? PermissionStatus.denied;
      notifyListeners();

      if (allGranted) {
        await initializeRecorder();
      } else {
        _errorMessage = 'Both microphone and storage permissions are required';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error initializing recording: $e');
      _errorMessage = 'Failed to initialize recording: $e';
      notifyListeners();
    }
  }

  // Initialize player
  Future<void> _initializePlayer() async {
    try {
      await _player.openPlayer();
      await _player.setSubscriptionDuration(const Duration(milliseconds: 100));

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ));
    } catch (e) {
      debugPrint('Error initializing player: $e');
    }
  }

  // Initialize recorder
  Future<void> initializeRecorder() async {
    try {
      await _recorder.openRecorder();

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
      ));

      _recorderInitialized = true;
      _errorMessage = '';
      notifyListeners();
      debugPrint('Recorder initialized successfully');
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
      _recorderInitialized = false;
      _errorMessage = 'Failed to initialize voice recorder: $e';
      notifyListeners();
    }
  }

  // Fetch user default activity
  Future<void> _fetchUserDefaultActivity(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final user = authProvider.currentUser!;

        if (user.userType == 'Professional' && user.activity != null) {
          _selectedActivity = user.activity;

          final bool isInMainActivities = _mainActivities
              .any((activity) => activity['name'] == user.activity);
          if (!isInMainActivities) {
            final bool isInAdditionalActivities = _additionalActivities
                .any((activity) => activity['name'] == user.activity);
            if (!isInAdditionalActivities) {
              _additionalActivities.add({
                'name': user.activity!,
                'key': 'other',
              });
            }
          }
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load profile data: ${e.toString()}';
      notifyListeners();
    }
  }

  // Fetch user default city
  Future<void> _fetchUserDefaultCity(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final user = authProvider.currentUser!;

        if (user.city != null && user.city!.isNotEmpty) {
          cityController.text = user.city!;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading user city: $e');
    }
  }

  // Set selected activity
  void setSelectedActivity(String? activity) {
    _selectedActivity = activity;
    notifyListeners();
  }

  // Set selected duration
  void setSelectedDuration(String? duration) {
    _selectedDuration = duration;
    notifyListeners();
  }

  // Set error message
  void setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error message
  void clearErrorMessage() {
    _errorMessage = '';
    notifyListeners();
  }

  // Start recording
  Future<void> startRecording() async {
    if (!_recorderInitialized) {
      await requestMicrophonePermission();
      if (!_recorderInitialized) {
        _errorMessage =
            'Voice recorder is not initialized. Please check microphone permissions.';
        notifyListeners();
        return;
      }
    }

    try {
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/recorded_audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      _audioWaveform.clear();
      _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
      _recorder.onProgress!.listen((event) {
        double level = event.decibels ?? -160.0;
        level = (level + 160) / 160;

        if (_audioWaveform.length >= _maxWaveformPoints) {
          _audioWaveform.removeAt(0);
        }
        _audioWaveform.add(level.clamp(0.05, 1.0));
        notifyListeners();
      });

      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      _isRecording = true;
      _recordingDuration = 0;
      _recordedAudioPath = filePath;
      _errorMessage = '';
      notifyListeners();

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration++;

        if (_recordingDuration >= _maxRecordingDuration) {
          stopRecording();
          if (_recordingTimer != null) {
            _recordingTimer!.cancel();
          }
        }
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Failed to start recording: ${e.toString()}';
      notifyListeners();
    }
  }

  // Stop recording
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      _recordingTimer?.cancel();
      await _recorder.stopRecorder();

      _isRecording = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to stop recording: ${e.toString()}';
      _isRecording = false;
      notifyListeners();
    }
  }

  // Play recording
  Future<void> playRecording() async {
    if (_recordedAudioPath == null || _isPlaying) return;

    try {
      await _player.stopPlayer();

      await _player.startPlayer(
        fromURI: _recordedAudioPath,
        codec: Codec.aacADTS,
        whenFinished: () {
          _isPlaying = false;
          notifyListeners();
        },
      );

      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _errorMessage = 'Failed to play recording: ${e.toString()}';
      _isPlaying = false;
      notifyListeners();
    }
  }

  // Stop playing
  Future<void> stopPlaying() async {
    if (!_isPlaying) return;

    try {
      await _player.stopPlayer();
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    } finally {
      _isPlaying = false;
      notifyListeners();
    }
  }

  // Delete recording
  Future<void> deleteRecording() async {
    if (_recordedAudioPath != null) {
      try {
        final file = File(_recordedAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting recording: $e');
      }

      _recordedAudioPath = null;
      _recordingDuration = 0;
      notifyListeners();
    }
  }

  // Request microphone permission
  Future<void> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      _micPermissionStatus = status;
      notifyListeners();

      if (status.isGranted) {
        await initializeRecorder();
      } else {
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
        _errorMessage = 'Microphone permission is required for voice messages';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error requesting microphone permission: $e');
      _errorMessage = 'Failed to request microphone permission';
      notifyListeners();
    }
  }

  // Search places
  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      _placePredictions = [];
      notifyListeners();
      return;
    }

    try {
      PlacesAutocompleteResponse response = await places.autocomplete(
        query,
        components: [Component(Component.country, "ma")],
      );

      if (response.status == "OK") {
        _placePredictions = response.predictions;
        notifyListeners();
      } else {
        _errorMessage = 'Place search failed';
        _placePredictions = [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
      _errorMessage = 'Failed to search places';
      _placePredictions = [];
      notifyListeners();
    }
  }

  // Select place
  void selectPlace(dynamic prediction) {
    final cityName = _extractCityName(prediction.description);
    cityController.text = cityName;
    _placePredictions = [];
    notifyListeners();
  }

  // Extract city name
  String _extractCityName(String fullAddress) {
    final parts = fullAddress.split(',');

    String cityPart;
    if (parts.isEmpty) {
      cityPart = fullAddress.trim();
    } else if (parts.length == 1) {
      cityPart = parts[0].trim();
    } else if (parts.length == 2) {
      cityPart = parts[0].trim();
    } else {
      cityPart = parts[0].trim();
      cityPart = cityPart.replaceAll(RegExp(r'\(.*\)'), '').trim();
    }

    return CityMappingService.normalizeCityName(cityPart);
  }

  // Convert audio to base64
  Future<String?> convertAudioToBase64() async {
    if (_recordedAudioPath == null) return null;

    try {
      final file = File(_recordedAudioPath!);
      if (!await file.exists()) {
        debugPrint('Audio file does not exist at path: $_recordedAudioPath');
        return null;
      }

      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      if (base64String.length > 1000000) {
        _errorMessage =
            'Audio file too large. Please record a shorter message.';
        notifyListeners();
        return null;
      }

      return base64String;
    } catch (e) {
      debugPrint('Error converting audio to base64: $e');
      return null;
    }
  }

  // Reset form
  void resetForm() {
    messageController.clear();
    cityController.clear();
    _selectedActivity = null;
    _errorMessage = '';
    if (_recordedAudioPath != null) {
      deleteRecording();
    }
    notifyListeners();
  }

  // Submit post
  Future<bool> submitPost(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    if (messageController.text.isEmpty && _recordedAudioPath == null) {
      _errorMessage = l10n.textOrVoiceRequired ??
          'Please provide either text or voice message';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        _errorMessage = l10n.mustBeLoggedIn ?? 'You must be logged in to post';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Upload audio file if exists
      String? audioUrl;
      if (_recordedAudioPath != null) {
        final file = File(_recordedAudioPath!);
        final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.aac';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('audio_messages')
            .child(fileName);

        await storageRef.putFile(file);
        audioUrl = await storageRef.getDownloadURL();
      }

      final postType =
          currentUser.userType == 'Professional' ? 'offer' : 'request';

      // Calculate expiry date
      DateTime? expiryDate;
      if (_selectedDuration != null && _selectedDuration != 'Unlimited') {
        expiryDate = DateTime.now();
        if (_selectedDuration == '48h') {
          expiryDate = expiryDate.add(const Duration(hours: 48));
        } else if (_selectedDuration == '7d') {
          expiryDate = expiryDate.add(const Duration(days: 7));
        } else if (_selectedDuration == '30d') {
          expiryDate = expiryDate.add(const Duration(days: 30));
        }
      }

      // Get current user location
      Position? userPosition;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            userPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 10),
            );
          }
        }
      } catch (e) {
        debugPrint('Error getting location for post: $e');
      }

      // Create post document
      DocumentReference postRef =
          await FirebaseFirestore.instance.collection('posts').add({
        'userId': currentUser.id,
        'userName': '${currentUser.firstName} ${currentUser.lastName}',
        'userAvatar': currentUser.profilePicture,
        'message': messageController.text,
        'audioUrl': audioUrl,
        'type': postType,
        'activity': _selectedActivity,
        'city': CityMappingService.normalizeCityName(cityController.text),
        'createdAt': FieldValue.serverTimestamp(),
        'expiryDate': expiryDate,
        'duration': _selectedDuration,
        'likes': 0,
        'responses': 0,
        'isLiked': false,
        'userType': currentUser.userType,
        'lastUpdated': FieldValue.serverTimestamp(),
        'approvalStatus': 'pending',
        'location': userPosition != null
            ? GeoPoint(userPosition.latitude, userPosition.longitude)
            : null,
        'latitude': userPosition?.latitude,
        'longitude': userPosition?.longitude,
      });

      // Increment user's posts count
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .update({
        'postsCount': FieldValue.increment(1),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          '${l10n.failedToCreatePost ?? 'Failed to create post'}: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Format duration
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Get localized activity name
  String getLocalizedActivityName(
      String activityName, String? key, AppLocalizations? l10n) {
    if (key == null || l10n == null) return activityName;

    switch (key) {
      case 'plumber':
        return l10n.plumber;
      case 'electrician':
        return l10n.electrician;
      case 'painter':
        return l10n.painter;
      case 'carpenter':
        return l10n.carpenter;
      case 'mason':
        return l10n.mason;
      case 'tiler':
        return l10n.tiler;
      case 'gardener':
        return l10n.gardener;
      case 'cleaner':
        return l10n.cleaner;
      case 'roofer':
        return l10n.roofer;
      case 'welder':
        return l10n.welder;
      case 'windowInstaller':
        return l10n.windowInstaller;
      case 'hvacTechnician':
        return l10n.hvacTechnician;
      case 'flooringInstaller':
        return l10n.flooringInstaller;
      case 'landscaper':
        return l10n.landscaper;
      case 'other':
        return l10n.other;
      default:
        return activityName;
    }
  }

  // Dispose
  @override
  void dispose() {
    messageController.dispose();
    cityController.dispose();
    activityController.dispose();
    stopRecording();
    _recordingTimer?.cancel();
    stopPlaying();
    _player.closePlayer();

    try {
      if (_recorderInitialized) {
        _recorder.closeRecorder();
      }
    } catch (e) {
      debugPrint('Error closing recorder: $e');
    }

    super.dispose();
  }
}
