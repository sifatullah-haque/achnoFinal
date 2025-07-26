import 'package:achno/config/theme.dart';
import 'package:achno/pages/main_screen.dart';
import 'package:achno/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
// Uncomment Google Maps API now that we have an API key
import 'package:google_maps_webservice/places.dart';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:achno/services/city_mapping_service.dart'; // Add this import
import 'package:achno/services/notification_service.dart'; // Add this import

class Addpost extends StatefulWidget {
  const Addpost({super.key});

  @override
  State<Addpost> createState() => _AddpostState();
}

class _AddpostState extends State<Addpost> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();

  String? _selectedActivity;
  // Updated activity options with icons and localization keys
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

  // Post duration options
  String? _selectedDuration = 'Unlimited';
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

  bool _isLoading = false;
  String _errorMessage = '';
  String? _recordedAudioPath;
  bool _isRecording = false;
  PermissionStatus _micPermissionStatus = PermissionStatus.denied;

  // Recording duration tracking
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  // Add a constant for maximum recording duration (60 seconds)
  final int _maxRecordingDuration = 60; // 60 seconds = 1 minute

  // Animation controller for fancy transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Google Places API client - using the provided API key
  final places = GoogleMapsPlaces(
    apiKey: 'AIzaSyD3Mr3cCo8RIrkqbR-seZaUODMxFrfvLSI',
  );
  List<dynamic> _placePredictions = [];

  // Audio recorder
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _recorderInitialized = false;
  bool _isPlaying = false;

  // Audio visualization
  final List<double> _audioWaveform = [];
  final int _maxWaveformPoints = 30;

  // Add notification service instance
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeRecordingFunctionality();
    _initializePlayer();
    _fetchUserDefaultActivity();
    _fetchUserDefaultCity(); // Add this to fetch the user's city

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

  Future<void> _initializePlayer() async {
    try {
      await _player.openPlayer();
      await _player.setSubscriptionDuration(const Duration(milliseconds: 100));

      // Configure audio session for playback
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

  // Initialize recording functionality
  Future<void> _initializeRecordingFunctionality() async {
    try {
      // Request multiple permissions at once
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.storage,
      ].request();

      // Check if all permissions are granted
      bool allGranted = statuses.values.every((status) => status.isGranted);

      setState(() {
        _micPermissionStatus =
            statuses[Permission.microphone] ?? PermissionStatus.denied;
      });

      if (allGranted) {
        await _initializeRecorder();
      } else {
        setState(() {
          _errorMessage =
              'Both microphone and storage permissions are required';
        });
      }
    } catch (e) {
      debugPrint('Error initializing recording: $e');
      setState(() {
        _errorMessage = 'Failed to initialize recording: $e';
      });
    }
  }

  // Check microphone permission
  Future<void> _checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      setState(() {
        _micPermissionStatus = status;
      });

      if (status.isGranted) {
        await _initializeRecorder();
      }
    } catch (e) {
      debugPrint('Error checking microphone permission: $e');
    }
  }

  // Request microphone permission
  Future<void> _requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      setState(() {
        _micPermissionStatus = status;
      });

      if (status.isGranted) {
        await _initializeRecorder();
      } else {
        // Open app settings if permission is permanently denied
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
        setState(() {
          _errorMessage =
              'Microphone permission is required for voice messages';
        });
      }
    } catch (e) {
      debugPrint('Error requesting microphone permission: $e');
      setState(() {
        _errorMessage = 'Failed to request microphone permission';
      });
    }
  }

  // Initialize recorder after permission is granted
  Future<void> _initializeRecorder() async {
    try {
      await _recorder.openRecorder();

      // Simplified audio session configuration
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
      ));

      setState(() {
        _recorderInitialized = true;
        _errorMessage = '';
      });
      debugPrint('Recorder initialized successfully');
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
      setState(() {
        _recorderInitialized = false;
        _errorMessage = 'Failed to initialize voice recorder: $e';
      });
    }
  }

  Future<void> _fetchUserDefaultActivity() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final user = authProvider.currentUser!;

        // Check if the user is a professional and has an activity set
        if (user.userType == 'Professional' && user.activity != null) {
          setState(() {
            _selectedActivity = user.activity;
            // Check if the activity is in the main activities or additional activities
            final bool isInMainActivities = _mainActivities
                .any((activity) => activity['name'] == user.activity);
            if (!isInMainActivities) {
              final bool isInAdditionalActivities = _additionalActivities
                  .any((activity) => activity['name'] == user.activity);
              if (!isInAdditionalActivities) {
                // If not in either list, add it to additional activities
                _additionalActivities.add({
                  'name': user.activity!,
                  'key': 'other', // Use 'other' key for custom activities
                });
              }
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile data: ${e.toString()}';
      });
    }
  }

  // Add a method to fetch the user's default city
  Future<void> _fetchUserDefaultCity() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final user = authProvider.currentUser!;

        // If the user has a city set in their profile, use that
        if (user.city != null && user.city!.isNotEmpty) {
          setState(() {
            _cityController.text = user.city!;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user city: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_recordedAudioPath == null || _isPlaying) return;

    try {
      // Make sure the player is stopped before starting
      await _player.stopPlayer();

      await _player.startPlayer(
        fromURI: _recordedAudioPath,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
          });
        },
      );

      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      debugPrint('Error playing audio: $e');
      setState(() {
        _errorMessage = 'Failed to play recording: ${e.toString()}';
        _isPlaying = false;
      });
    }
  }

  Future<void> _stopPlaying() async {
    if (!_isPlaying) return;

    try {
      await _player.stopPlayer();
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    } finally {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _cityController.dispose();
    _activityController.dispose();
    _animationController.dispose();
    _stopRecording();

    // Safe cleanup of recorder
    try {
      if (_recorderInitialized) {
        _recorder.closeRecorder();
      }
    } catch (e) {
      debugPrint('Error closing recorder: $e');
    }

    _recordingTimer?.cancel();
    _stopPlaying();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_recorderInitialized) {
      // If recorder is not initialized, try to request permissions again
      await _requestMicrophonePermission();

      if (!_recorderInitialized) {
        setState(() {
          _errorMessage =
              'Voice recorder is not initialized. Please check microphone permissions.';
        });
        return;
      }
    }

    try {
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/recorded_audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      // Set up audio level subscription for visualization
      _audioWaveform.clear();
      _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
      _recorder.onProgress!.listen((event) {
        double level = event.decibels ?? -160.0;
        level = (level + 160) / 160; // Normalize between 0 and 1

        setState(() {
          if (_audioWaveform.length >= _maxWaveformPoints) {
            _audioWaveform.removeAt(0);
          }
          _audioWaveform.add(level.clamp(0.05, 1.0));
        });
      });

      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _recordedAudioPath = filePath;
        _errorMessage = ''; // Clear any previous error
      });

      // Start a timer to track recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;

          // Automatically stop recording when reaching the maximum duration
          if (_recordingDuration >= _maxRecordingDuration) {
            _stopRecording();
            // Show a small notification that max time was reached
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maximum recording time of 1 minute reached.'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        });
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start recording: ${e.toString()}';
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) {
      return;
    }

    try {
      _recordingTimer?.cancel();
      await _recorder.stopRecorder();

      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to stop recording: ${e.toString()}';
        _isRecording = false;
      });
    }
  }

  Future<void> _deleteRecording() async {
    if (_recordedAudioPath != null) {
      try {
        final file = File(_recordedAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Handle error silently
        debugPrint('Error deleting recording: $e');
      }

      setState(() {
        _recordedAudioPath = null;
        _recordingDuration = 0;
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Improved Google Places search function
  void _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _placePredictions = [];
      });
      return;
    }

    try {
      PlacesAutocompleteResponse response = await places.autocomplete(
        query,
        components: [
          Component(Component.country, "ma")
        ], // Changed from "us" to "ma" for Morocco
      );

      if (response.status == "OK") {
        setState(() {
          _placePredictions = response.predictions;
        });
      } else {
        setState(() {
          _errorMessage = 'Place search failed';
          _placePredictions = [];
        });
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
      setState(() {
        _errorMessage = 'Failed to search places';
        _placePredictions = [];
      });
    }
  }

  // Update the method to work with Google Places API data
  void _selectPlace(dynamic prediction) {
    final cityName = _extractCityName(prediction.description);
    setState(() {
      _cityController.text = cityName;
      _placePredictions = [];
    });
    FocusScope.of(context).unfocus();
  }

  Future<String?> _convertAudioToBase64() async {
    if (_recordedAudioPath == null) {
      return null;
    }

    try {
      final file = File(_recordedAudioPath!);
      if (!await file.exists()) {
        debugPrint('Audio file does not exist at path: $_recordedAudioPath');
        return null;
      }

      // Read file as bytes and convert to base64
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      // Check size - limit to 1MB (Firestore has a 1MB document size limit)
      if (base64String.length > 1000000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Audio file too large. Please record a shorter message.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      return base64String;
    } catch (e) {
      debugPrint('Error converting audio to base64: $e');
      return null;
    }
  }

  void _resetForm() {
    setState(() {
      _messageController.clear();
      _cityController.clear();
      _selectedActivity = null;
      _errorMessage = '';
      if (_recordedAudioPath != null) {
        _deleteRecording();
      }
    });
  }

  Future<void> _submitPost() async {
    final l10n = AppLocalizations.of(context);

    if (_messageController.text.isEmpty && _recordedAudioPath == null) {
      setState(() {
        _errorMessage = l10n.textOrVoiceRequired ??
            'Please provide either text or voice message';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        setState(() {
          _errorMessage =
              l10n.mustBeLoggedIn ?? 'You must be logged in to post';
          _isLoading = false;
        });
        return;
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

      // Calculate expiry date based on selected duration
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

      // Get current user location with better error handling
      Position? userPosition;
      try {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          // Check permissions
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            // Get current position with high accuracy
            userPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 10),
            );

            debugPrint(
                'Post location captured: ${userPosition.latitude}, ${userPosition.longitude}');
          }
        }
      } catch (e) {
        debugPrint('Error getting location for post: $e');
        // Continue without location - don't stop post creation
      }

      // Create post document in Firestore with PENDING status (REMOVED auto-approval)
      DocumentReference postRef =
          await FirebaseFirestore.instance.collection('posts').add({
        'userId': currentUser.id,
        'userName': '${currentUser.firstName} ${currentUser.lastName}',
        'userAvatar': currentUser.profilePicture,
        'message': _messageController.text,
        'audioUrl': audioUrl,
        'type': postType,
        'activity': _selectedActivity,
        'city': CityMappingService.normalizeCityName(_cityController.text),
        'createdAt': FieldValue.serverTimestamp(),
        'expiryDate': expiryDate,
        'duration': _selectedDuration,
        'likes': 0,
        'responses': 0,
        'isLiked': false,
        'userType': currentUser.userType,
        'lastUpdated': FieldValue.serverTimestamp(),
        'approvalStatus': 'pending', // Keep as pending - DO NOT auto-approve
        'location': userPosition != null
            ? GeoPoint(userPosition.latitude, userPosition.longitude)
            : null,
        'latitude': userPosition?.latitude,
        'longitude': userPosition?.longitude,
      });

      // ADDED: Increment the user's posts count
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .update({
        'postsCount': FieldValue.increment(1),
      });

      // REMOVED: Auto-approval and notification sending code
      // Posts will now remain pending until admin approval

      if (!mounted) return;

      // After successful post creation, reset form
      _resetForm();

      // Show success message about post awaiting admin approval
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pending_actions,
                      color: Colors.orange,
                      size: 48.r,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.postSuccessfullySubmitted ??
                        'Post Successfully Submitted',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    l10n.postSubmittedAwaitingApproval ??
                        'Your post has been submitted and is awaiting admin approval. It will appear on the homepage once approved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      // Navigate to homepage after dismissing the dialog
                      if (mounted) {
                        context.go("/mainScreen", extra: {
                          'initialIndex': 0, // Navigate to homepage
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      l10n.continue_ ?? 'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Navigation will now happen after the user dismisses the dialog
    } catch (e) {
      setState(() {
        _errorMessage =
            '${l10n.failedToCreatePost ?? 'Failed to create post'}: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Modified helper method to extract and normalize city name
  String _extractCityName(String fullAddress) {
    // Split the address by commas
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
      // Remove any extra information in parentheses if present
      cityPart = cityPart.replaceAll(RegExp(r'\(.*\)'), '').trim();
    }

    // Normalize the extracted city name
    return CityMappingService.normalizeCityName(cityPart);
  }

  // Helper method to get localized activity name
  String _getLocalizedActivityName(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context);

    // Fallback for localization
    final addPostTitle = l10n.addPost ?? 'Add Post';
    final messageHint = l10n.messageHint ?? 'Write your message...';
    final cityHint = l10n.cityHint ?? 'Select city';
    final activityLabel = l10n.activityLabel ?? 'Activity';
    final recordVoice = l10n.recordVoice ?? 'Record voice message';
    final postButtonLabel = l10n.postButtonLabel ?? 'Post';

    // For debug: Print current localization values
    debugPrint('Localization values: ${l10n.toString()}');
    debugPrint('Current locale: ${Localizations.localeOf(context)}');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.h),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16.r),
            bottomRight: Radius.circular(16.r),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: isDarkMode
                  ? Colors.black.withOpacity(0.6)
                  : Colors.white.withOpacity(0.8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              shadowColor: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              surfaceTintColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16.r),
                    bottomRight: Radius.circular(16.r),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                ),
              ),
              title: Text(
                addPostTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              centerTitle: true,
              automaticallyImplyLeading: false,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background patterns similar to login/register pages
          Positioned(
            top: -70.h,
            left: -40.w,
            child: Container(
              width: 150.w,
              height: 150.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -60.h,
            right: -30.w,
            child: Container(
              width: 140.w,
              height: 140.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.09),
              ),
            ),
          ),
          // Small decorative elements
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            right: 30.w,
            child: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.darkAccentColor.withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.25,
            left: 40.w,
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.15),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                  top: 8.h,
                  left: 16.w,
                  right: 16.w,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16.h),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h), // Space for AppBar

                      // HIGHLIGHT: Moved voice recording to be the first and most prominent element
                      _buildCompactVoiceRecordingSection(
                          context, isDarkMode, primaryColor, recordVoice),

                      SizedBox(height: 10.h),

                      // HIGHLIGHT: Added post duration selector
                      _buildDurationSelector(context, isDarkMode),

                      SizedBox(height: 10.h),

                      // Message input (secondary)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            decoration: AppTheme.glassEffect(),
                            padding: EdgeInsets.all(12.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  messageHint,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                TextFormField(
                                  controller: _messageController,
                                  maxLines:
                                      2, // Reduced from 3 to make more compact
                                  decoration: InputDecoration(
                                    hintText: l10n.addOptionalDetails ??
                                        "Add optional details (not required)",
                                    hintStyle: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white.withOpacity(0.4)
                                          : Colors.black.withOpacity(0.4),
                                      fontSize: 12.sp,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                      borderSide: BorderSide(
                                        color: isDarkMode
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.black.withOpacity(0.1),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black.withOpacity(0.03),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 8.h,
                                      horizontal: 10.w,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 10.h),

                      // MODIFIED: Display city selection in full width
                      _buildCompactCitySelector(context, isDarkMode, cityHint),

                      SizedBox(height: 10.h),

                      // NEW: Activity selection grid like registration page
                      _buildActivitySelectionGrid(
                          context, isDarkMode, activityLabel),

                      // Error message
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 10.h),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 6.h, horizontal: 10.w),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 16.w,
                                ),
                                SizedBox(width: 6.w),
                                Flexible(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      SizedBox(height: 16.h),

                      // Post Button
                      Container(
                        width: double.infinity,
                        height: 46.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.darkAccentColor
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitPost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDarkMode
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                )
                              : Text(
                                  postButtonLabel,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Compact voice recording section with simplified visualization
  Widget _buildCompactVoiceRecordingSection(BuildContext context,
      bool isDarkMode, Color primaryColor, String recordVoice) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.darkAccentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                color: Colors.white,
                size: 18.w,
              ),
              SizedBox(width: 8.w),
              Text(
                recordVoice,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: Colors.white,
                ),
              ),
              // Add the max duration info
              Text(
                ' (${l10n.maxOneMinute ?? 'Max 1 minute'})',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withOpacity(0.9),
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (!_micPermissionStatus.isGranted)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: _requestMicrophonePermission,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          l10n.allowMicPermission ?? 'Allow',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          // Audio waveform visualization - more compact
          if (_isRecording && _audioWaveform.isNotEmpty)
            Column(
              children: [
                Container(
                  height: 40.h,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 5.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      _audioWaveform.length,
                      (index) =>
                          _buildWaveformBar(_audioWaveform[index], index),
                    ),
                  ),
                ),
                // Add recording time progress indicator
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: LinearProgressIndicator(
                    value: _recordingDuration / _maxRecordingDuration,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _recordingDuration >= _maxRecordingDuration * 0.8
                          ? Colors.red.shade300 // Red when approaching limit
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            ),

          if (_recordedAudioPath != null && !_isRecording)
            // Display recorded audio player with more compact design
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow,
                        color: Colors.white, size: 20.w),
                    onPressed: _isPlaying ? _stopPlaying : _playRecording,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.audioRecording ?? 'Audio recording',
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _formatDuration(_recordingDuration),
                          style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.white, size: 18.w),
                    onPressed: _deleteRecording,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            )
          else if (!_micPermissionStatus.isGranted)
            // Permission denied message - compact
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Column(
                children: [
                  Icon(
                    Icons.mic_off,
                    size: 32.w,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    l10n.microphoneAccessNeeded ?? 'Microphone access needed',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (!_recorderInitialized)
            // Initialization failed - compact
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 28.w,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    l10n.failedToInitializeRecorder ??
                        'Failed to initialize recorder',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _initializeRecorder,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(l10n.tryAgain ?? 'Try Again',
                        style: TextStyle(fontSize: 12.sp)),
                  ),
                ],
              ),
            )
          else
            // Record button with pulse animation - more compact
            Center(
              child: Column(
                children: [
                  _buildPulseAnimation(
                    child: GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: Container(
                        width: 60.w, // Reduced size
                        height: 60.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? Colors.red : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording ? Colors.red : Colors.white)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: _isRecording
                              ? Colors.white
                              : AppTheme.primaryColor,
                          size: 30.w, // Reduced size
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _isRecording
                        ? _formatDuration(_recordingDuration)
                        : l10n.tapToRecord ?? 'Tap to record',
                    style: TextStyle(
                      fontSize: _isRecording ? 14.sp : 12.sp,
                      fontWeight:
                          _isRecording ? FontWeight.w600 : FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                  if (_isRecording)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        l10n.tapToStop ?? 'Tap to stop',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          SizedBox(height: 6.h),
        ],
      ),
    );
  }

  // Helper method to build waveform bars - more compact
  Widget _buildWaveformBar(double amplitude, int index) {
    final minHeight = 3.h;
    final maxHeight = 25.h;
    final height = minHeight + (maxHeight - minHeight) * amplitude;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 3.w,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(index == _audioWaveform.length - 1
            ? 1.0
            : 0.5 + (index / (_audioWaveform.length * 2))),
        borderRadius: BorderRadius.circular(1.5.r),
      ),
    );
  }

  // Pulse animation wrapper
  Widget _buildPulseAnimation({required Widget child}) {
    if (!_isRecording) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.05),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
      onEnd: () {
        setState(() {}); // Force rebuild to restart animation
      },
    );
  }

  // More compact duration selector
  Widget _buildDurationSelector(BuildContext context, bool isDarkMode) {
    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: AppTheme.glassEffect(),
          padding: EdgeInsets.all(10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    size: 16.w,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    l10n.postDuration ?? "Post Duration",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _durationOptions.map((option) {
                    final isSelected = _selectedDuration == option['value'];
                    final labelKey = option['labelKey'] as String;

                    // Map labelKey to localized text
                    String localizedLabel;
                    switch (labelKey) {
                      case 'unlimited':
                        localizedLabel = l10n.unlimited ?? 'Unlimited';
                        break;
                      case 'hours48':
                        localizedLabel = l10n.hours48 ?? '48 Hours';
                        break;
                      case 'days7':
                        localizedLabel = l10n.days7 ?? '7 Days';
                        break;
                      case 'days30':
                        localizedLabel = l10n.days30 ?? '30 Days';
                        break;
                      default:
                        localizedLabel = labelKey;
                    }

                    return Container(
                      margin: EdgeInsets.only(right: 8.w),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDuration = option['value'] as String;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : isDarkMode
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : isDarkMode
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.1),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                option['icon'] as IconData,
                                color: isSelected
                                    ? Colors.white
                                    : isDarkMode
                                        ? Colors.white70
                                        : AppTheme.textSecondaryColor,
                                size: 14.w,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                localizedLabel,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.white
                                      : isDarkMode
                                          ? Colors.white70
                                          : AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Compact city selector for horizontal layout
  Widget _buildCompactCitySelector(
      BuildContext context, bool isDarkMode, String cityHint) {
    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: AppTheme.glassEffect(),
          padding: EdgeInsets.all(10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_city,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    size: 14.w,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    cityHint,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  hintText: l10n.typeToSearch ?? 'Type to search',
                  hintStyle: TextStyle(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.5),
                    fontSize: 11.sp,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 16.w,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 6.h,
                    horizontal: 8.w,
                  ),
                  isDense: true,
                ),
                style: TextStyle(fontSize: 12.sp),
                onChanged: _searchPlaces,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.cityRequired ?? 'City required';
                  }
                  return null;
                },
              ),
              if (_placePredictions.isNotEmpty)
                Container(
                  height: 100.h,
                  margin: EdgeInsets.only(top: 6.h),
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _placePredictions.length,
                    itemBuilder: (context, index) {
                      final prediction = _placePredictions[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4.r),
                          onTap: () => _selectPlace(prediction),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 4.h, horizontal: 4.w),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                  size: 12.w,
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prediction.description.split(',').first,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11.sp,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        prediction.description
                                            .split(',')
                                            .skip(1)
                                            .join(',')
                                            .trim(),
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white54
                                              : Colors.black45,
                                          fontSize: 9.sp,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Activity selection grid like in registration page
  Widget _buildActivitySelectionGrid(
      BuildContext context, bool isDarkMode, String activityLabel) {
    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: AppTheme.glassEffect(),
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.work_outline,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    size: 16.w,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    activityLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Grid of main activities with icons
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 8.w,
                  mainAxisSpacing: 8.h,
                ),
                itemCount: _mainActivities.length,
                itemBuilder: (context, index) {
                  final activity = _mainActivities[index];
                  final localizedName = _getLocalizedActivityName(
                      activity['name'], activity['key'], l10n);
                  return _buildActivityCard(
                    activity['name'], // Store English name for database
                    localizedName, // Display localized name
                    activity['icon'],
                    isDarkMode,
                  );
                },
              ),

              SizedBox(height: 12.h),

              // Dropdown for additional activities
              DropdownButtonFormField<String>(
                value: _additionalActivities.any(
                        (activity) => activity['name'] == _selectedActivity)
                    ? _selectedActivity
                    : null,
                decoration: InputDecoration(
                  labelText: l10n.otherActivities ?? "Other Activities",
                  prefixIcon: Icon(
                    Icons.add_circle_outline,
                    size: 18.w,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8.h,
                    horizontal: 10.w,
                  ),
                  isDense: true,
                ),
                items:
                    _additionalActivities.map((Map<String, String> activity) {
                  final localizedName = _getLocalizedActivityName(
                      activity['name']!, activity['key'], l10n);
                  return DropdownMenuItem<String>(
                    value: activity['name'], // Store English name for database
                    child: Text(
                      localizedName, // Display localized name
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedActivity = newValue;
                  });
                },
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  size: 22.w,
                ),
                dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                hint: Text(
                  l10n.selectOtherActivity ?? "Select other activity",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Activity card builder similar to registration page
  Widget _buildActivityCard(
      String activityName, String displayName, IconData icon, bool isDarkMode) {
    final isSelected = _selectedActivity == activityName;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedActivity = activityName; // Store English name for database
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey[200]!),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24.w,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode
                      ? Colors.white.withOpacity(0.8)
                      : AppTheme.textPrimaryColor),
            ),
            SizedBox(height: 4.h),
            Text(
              displayName, // Display localized name
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode
                        ? Colors.white.withOpacity(0.8)
                        : AppTheme.textPrimaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
