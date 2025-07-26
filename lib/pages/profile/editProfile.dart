import 'dart:async';
import 'dart:io';
import 'package:achno/config/theme.dart';
import 'package:achno/providers/auth_provider.dart';
import 'package:achno/providers/language_provider.dart'; // Add this import
import 'package:achno/pages/profile/settings_page.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:google_maps_webservice/places.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path/path.dart' as path;
import 'package:device_info_plus/device_info_plus.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();

  // User data variables
  bool _isProfessional = false;
  String? _selectedActivity;
  String? _userId;
  String? _existingProfilePicture;
  File? _selectedImage;
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';

  // Audio bio variables
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  String? _audioPath;
  String? _existingAudioBioUrl;
  bool _isRecording = false;
  bool _isPlaying = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  // For city search with Google Places API
  final places =
      GoogleMapsPlaces(apiKey: 'AIzaSyD3Mr3cCo8RIrkqbR-seZaUODMxFrfvLSI');
  List<dynamic> _placePredictions = [];
  bool _isGettingLocation = false;

  // Lists for profession selection (copied from registration)
  final List<Map<String, dynamic>> _mainActivities = [
    {'name': 'Plumber', 'icon': Icons.plumbing},
    {'name': 'Electrician', 'icon': Icons.electrical_services},
    {'name': 'Painter', 'icon': Icons.format_paint},
    {'name': 'Carpenter', 'icon': Icons.carpenter},
    {'name': 'Mason', 'icon': Icons.domain},
    {'name': 'Tiler', 'icon': Icons.grid_on},
  ];

  final List<String> _additionalActivities = [
    'Gardener',
    'Cleaner',
    'Roofer',
    'Welder',
    'Window Installer',
    'HVAC Technician',
    'Flooring Installer',
    'Landscaper',
    'Other'
  ];

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Add a DeviceInfoPlugin instance
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Add language-related variables
  String? _selectedLanguage;

  // Available languages (same as registration page)
  final List<Map<String, dynamic>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ar', 'name': 'العربية'},
    {'code': 'fr', 'name': 'Français'},
  ];

  @override
  void initState() {
    super.initState();

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

    _initAudioRecorder();
    _initAudioPlayer();
    _loadUserData();
    _animationController.forward();

    // Initialize selected language
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      setState(() {
        _selectedLanguage = languageProvider.locale.languageCode;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _animationController.dispose();
    _stopRecording();
    _stopAudio();
    _audioRecorder.closeRecorder();
    _audioPlayer.closePlayer();
    _recordingTimer?.cancel();
    super.dispose();
  }

  // Initialize audio recorder
  Future<void> _initAudioRecorder() async {
    try {
      await _audioRecorder.openRecorder();
      await _audioRecorder.setSubscriptionDuration(
        const Duration(milliseconds: 100),
      );
    } catch (e) {
      debugPrint('Error initializing audio recorder: $e');
    }
  }

  // Initialize audio player
  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.openPlayer();
      await _audioPlayer.setSubscriptionDuration(
        const Duration(milliseconds: 100),
      );

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media,
        ),
      ));
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  // Request microphone permission
  Future<bool> _requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _errorMessage = 'Microphone permission denied';
      });
      return false;
    }
    return true;
  }

  // Start recording audio bio
  Future<void> _startRecording() async {
    if (!await _requestMicrophonePermission()) {
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      _audioPath =
          '${tempDir.path}/audio_bio_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _audioRecorder.startRecorder(
        toFile: _audioPath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });

      // Start timer to track recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      setState(() {
        _errorMessage = 'Failed to start recording: ${e.toString()}';
      });
    }
  }

  // Stop recording audio bio
  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      _recordingTimer?.cancel();
      await _audioRecorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  // Play recorded audio bio
  Future<void> _playAudio() async {
    if (_isPlaying) {
      await _stopAudio();
      return;
    }

    try {
      String? audioUrl = _audioPath ?? _existingAudioBioUrl;
      if (audioUrl == null) {
        setState(() {
          _errorMessage = 'No audio to play';
        });
        return;
      }

      await _audioPlayer.startPlayer(
        fromURI: audioUrl,
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
        _errorMessage = 'Failed to play audio: ${e.toString()}';
        _isPlaying = false;
      });
    }
  }

  // Stop playing audio bio
  Future<void> _stopAudio() async {
    if (!_isPlaying) return;

    try {
      await _audioPlayer.stopPlayer();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  // Load the user's current data
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      _userId = user.id;

      // Get full user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final data = userDoc.data() as Map<String, dynamic>;

      // Set controllers and state variables
      _nameController.text =
          data['firstName'] != null && data['lastName'] != null
              ? '${data['firstName']} ${data['lastName']}'
              : data['name'] ?? '';
      _bioController.text = data['bio'] ?? '';
      _cityController.text = data['city'] ?? '';
      _existingProfilePicture = data['profilePicture'];
      _existingAudioBioUrl = data['audioBioUrl'];
      _isProfessional = data['isProfessional'] ?? false;
      _selectedActivity = data['activity'];
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile data: ${e.toString()}';
      });
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Upload image to Firebase Storage with improved error handling
  Future<String?> _uploadProfileImage() async {
    if (_selectedImage == null) return _existingProfilePicture;

    try {
      // Set loading state
      setState(() {
        _isSaving = true;
        _errorMessage = '';
      });

      debugPrint('Starting profile image upload for user: $_userId');

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(_userId!);

      debugPrint('Created storage reference: ${storageRef.fullPath}');

      // Track upload progress
      final uploadTask = storageRef.putFile(
        _selectedImage!,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': _userId!},
        ),
      );

      // Listen to upload progress for debugging
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');

        if (snapshot.state == TaskState.error) {
          debugPrint('Upload error state detected');
        }
      });

      // Wait for upload to complete
      await uploadTask;
      debugPrint('Upload completed successfully');

      // Get the download URL
      final downloadUrl = await storageRef.getDownloadURL();
      debugPrint('Download URL obtained: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      final errorDetails = e.toString();

      // More detailed error logging
      if (e is FirebaseException) {
        debugPrint('Firebase error code: ${e.code}');
        debugPrint('Firebase error message: ${e.message}');
      }

      setState(() {
        _errorMessage = 'Failed to upload profile picture: $errorDetails';
      });
      return null;
    }
  }

  // Upload audio bio to Firebase Storage
  Future<String?> _uploadAudioBio() async {
    if (_audioPath == null) return _existingAudioBioUrl;

    try {
      final audioFile = File(_audioPath!);
      if (!await audioFile.exists()) return _existingAudioBioUrl;

      // Log for debugging
      debugPrint('Starting audio bio upload for user: $_userId');

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('audio_bios')
          .child('$_userId.aac');

      debugPrint('Created audio storage reference: ${storageRef.fullPath}');

      // Add metadata including content type and userId
      final uploadTask = storageRef.putFile(
        audioFile,
        SettableMetadata(
          contentType: 'audio/aac',
          customMetadata: {'userId': _userId!},
        ),
      );

      // Listen to upload progress for debugging
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint(
            'Audio upload progress: ${(progress * 100).toStringAsFixed(2)}%');

        if (snapshot.state == TaskState.error) {
          debugPrint('Audio upload error state detected');
        }
      });

      // Wait for upload to complete
      await uploadTask;
      debugPrint('Audio upload completed successfully');

      // Get the download URL
      final downloadUrl = await storageRef.getDownloadURL();
      debugPrint('Audio download URL obtained: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading audio bio: $e');

      // More detailed error logging
      if (e is FirebaseException) {
        debugPrint('Firebase error code: ${e.code}');
        debugPrint('Firebase error message: ${e.message}');
      }

      setState(() {
        _errorMessage = 'Failed to upload audio bio: ${e.toString()}';
      });
      return null;
    }
  }

  // Save updated profile with improved error handling
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      debugPrint('Starting profile update for user: $_userId');

      // Extract first and last name
      final fullName = _nameController.text.trim();
      final nameParts = fullName.split(' ');
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Upload image if selected
      debugPrint('Uploading profile image...');
      final profilePictureUrl = await _uploadProfileImage();
      debugPrint('Profile image URL obtained: $profilePictureUrl');

      // Upload audio bio if recorded
      final audioBioUrl = await _uploadAudioBio();

      // Prepare data to update
      Map<String, Object> userData = {
        'firstName': firstName,
        'lastName': lastName,
        'bio': _bioController.text.trim(),
        'city': _cityController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Add professional-specific fields if applicable
      if (_isProfessional && _selectedActivity != null) {
        userData['activity'] = _selectedActivity as Object;
      }

      // Add profile picture URL if available (using the correct field name)
      if (profilePictureUrl != null) {
        userData['profilePicture'] = profilePictureUrl;
        debugPrint('Adding profilePicture URL to update: $profilePictureUrl');
      }

      // Add audio bio URL if available
      if (audioBioUrl != null) {
        userData['audioBioUrl'] = audioBioUrl;
      }

      // Log the data being sent to Firestore
      debugPrint('Updating Firestore with data: ${userData.toString()}');

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .update(userData);

      debugPrint('Firestore update successful');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).profileUpdated)),
        );
        Navigator.of(context)
            .pop(true); // Pass true to indicate successful update
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');

      // More detailed error logging
      if (e is FirebaseException) {
        debugPrint('Firebase error code: ${e.code}');
        debugPrint('Firebase error message: ${e.message}');
      }

      setState(() {
        _errorMessage = 'Error updating profile: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Image picker with error handling for device info
  Future<void> _pickImage(ImageSource source) async {
    try {
      PermissionStatus status;

      if (source == ImageSource.camera) {
        status = await Permission.camera.request();
      } else {
        // For gallery access, request the appropriate permission
        // Use a more robust approach that doesn't rely solely on DeviceInfoPlugin
        if (Platform.isAndroid) {
          try {
            // Try to get Android SDK version, but have a fallback
            int? sdkVersion;
            try {
              final androidInfo = await _deviceInfo.androidInfo;
              sdkVersion = androidInfo.version.sdkInt;
            } catch (e) {
              // If DeviceInfoPlugin fails, log the error but continue
              debugPrint('Error getting Android SDK version: $e');
              // We'll use a fallback approach
              sdkVersion = null;
            }

            // Request the appropriate permission based on SDK version if available
            // Otherwise, request both permissions to be safe
            if (sdkVersion != null && sdkVersion >= 33) {
              // Android 13+ uses photos permission
              status = await Permission.photos.request();
            } else {
              // Try storage permission first (works on older Android)
              status = await Permission.storage.request();

              // If storage permission didn't work, also try photos permission
              if (status.isDenied) {
                status = await Permission.photos.request();
              }
            }
          } catch (e) {
            // If all else fails, try both permissions
            debugPrint('Error determining correct permission: $e');
            status = await Permission.storage.request();
            if (status.isDenied) {
              status = await Permission.photos.request();
            }
          }
        } else if (Platform.isIOS) {
          // For iOS, just use photos permission
          status = await Permission.photos.request();
        } else {
          // For other platforms
          status = await Permission.storage.request();
        }
      }

      if (status.isGranted) {
        final picker = ImagePicker();
        final pickedImage = await picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (pickedImage != null) {
          setState(() {
            _selectedImage = File(pickedImage.path);
          });
        }
      } else if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog();
      } else {
        setState(() {
          _errorMessage =
              'Permission denied to access ${source == ImageSource.camera ? 'camera' : 'gallery'}';
        });
        debugPrint('Permission denied: $status');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      setState(() {
        _errorMessage =
            'Error accessing ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e';
      });
    }
  }

  // Add this helper method to show dialog when permission is permanently denied
  void _showPermissionDeniedDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.permissionRequired),
        content: Text(l10n.mediaPermissionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
  }

  // Show image source selection
  void _showImageSourceOptions() {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.selectImageSource,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(context, Icons.camera_alt, l10n.camera,
                    () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                }),
                _buildImageSourceOption(
                    context, Icons.photo_library, l10n.gallery, () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                }),
              ],
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60.h,
            width: 60.w,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 30.w,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Implement city search methods
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
        // Safely convert predictions to a List that doesn't cause type issues
        final safeList = response.predictions
            .map((prediction) => prediction as Object)
            .toList();

        setState(() {
          _placePredictions = safeList;
        });
      } else {
        setState(() {
          _placePredictions = [];
        });
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
      setState(() {
        _placePredictions = [];
      });
    }
  }

  void _selectPlace(dynamic prediction) {
    // Fix the type issue by ensuring prediction is treated properly before accessing properties
    if (prediction == null) return;

    try {
      // Handle the prediction.description property safely
      String description;
      if (prediction.description is String) {
        description = prediction.description;
      } else {
        // Convert to string if not already a string
        description = prediction.description?.toString() ?? '';
      }

      final cityName = _extractCityName(description);

      setState(() {
        _cityController.text = cityName;
        _placePredictions = [];
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint('Error selecting place: $e');
    }
  }

  String _extractCityName(String fullAddress) {
    final parts = fullAddress.split(',');
    if (parts.length < 2) return fullAddress.trim();

    String cityPart =
        parts.length > 2 ? parts[parts.length - 3].trim() : parts[0].trim();

    cityPart = cityPart.replaceAll(RegExp(r'\(.*\)'), '').trim();

    return cityPart;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _errorMessage = '';
    });

    try {
      // Request location permission
      final permission = await Permission.location.request();
      if (permission.isDenied) {
        setState(() {
          _errorMessage = 'Location permission denied';
          _isGettingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Use Places API to get the city name from coordinates
      final response = await places.searchNearbyWithRadius(
        Location(lat: position.latitude, lng: position.longitude),
        1000, // 1km radius
        type: "locality",
      );

      if (response.status == "OK" && response.results.isNotEmpty) {
        // Find the locality (city) in the results
        String cityName = "Unknown location";
        for (var result in response.results) {
          if (result.types.contains("locality")) {
            cityName = result.name;
            break;
          }
        }

        setState(() {
          _cityController.text = cityName;
        });
      } else {
        // If no specific locality found, try reverse geocoding
        final placemarks = await places.searchNearbyWithRadius(
          Location(lat: position.latitude, lng: position.longitude),
          100,
        );

        if (placemarks.status == "OK" && placemarks.results.isNotEmpty) {
          setState(() {
            _cityController.text =
                _extractCityName(placemarks.results.first.name);
          });
        } else {
          setState(() {
            _errorMessage = 'Could not determine your city';
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _errorMessage = 'Error getting location: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  // Navigate to settings page
  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              title: Text(
                AppLocalizations.of(context).editProfile ?? 'Edit Profile',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppTheme.textSecondaryColor,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                // Remove language button from here since we're adding it to the form
                TextButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context);

    return Stack(
      children: [
        // Background design elements
        Positioned(
          top: -70.h,
          left: -40.w,
          child: Container(
            width: 170.w,
            height: 170.w,
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
            width: 160.w,
            height: 160.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentColor.withOpacity(0.09),
            ),
          ),
        ),

        // Main form content
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: child,
                );
              },
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 16.h),

                    // Profile Image
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 120.w,
                          height: 120.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: _selectedImage != null
                              ? CircleAvatar(
                                  radius: 58.r,
                                  backgroundImage: FileImage(_selectedImage!),
                                )
                              : _existingProfilePicture != null
                                  ? CircleAvatar(
                                      radius: 58.r,
                                      backgroundImage: NetworkImage(
                                          _existingProfilePicture!),
                                    )
                                  : CircleAvatar(
                                      radius: 58.r,
                                      backgroundColor: Colors.grey[200],
                                      child: Text(
                                        _nameController.text.isNotEmpty
                                            ? _nameController.text[0]
                                                .toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 40.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                        ),
                        GestureDetector(
                          onTap: _showImageSourceOptions,
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.w,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18.w,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // Form Fields
                    // Name Field
                    _buildTextField(
                      controller: _nameController,
                      labelText: l10n.fullName,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterName;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    // Phone Field (disabled)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        enabled: false,
                        initialValue: l10n.phoneCannotBeChanged,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.phone,
                          labelStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 13.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            size: 20.w,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 14.h, horizontal: 18.w),
                          isDense: true,
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Bio Field (Text)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _bioController,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: AppTheme.textPrimaryColor,
                        ),
                        maxLines: 2,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: l10n.textBio,
                          labelStyle: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 13.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.description_outlined,
                            size: 20.w,
                            color: AppTheme.textSecondaryColor,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 14.h, horizontal: 18.w),
                          isDense: true,
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Audio Bio Recorder
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.mic,
                                size: 20.w,
                                color: AppTheme.primaryColor,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                l10n.audioBio,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          if (_isRecording)
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 12.w,
                                      height: 12.w,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      l10n.recording(
                                          _formatDuration(_recordingDuration)),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                ElevatedButton.icon(
                                  onPressed: _stopRecording,
                                  icon: const Icon(Icons.stop),
                                  label: Text(l10n.stopRecording),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else if (_audioPath != null ||
                              _existingAudioBioUrl != null)
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 12.h, horizontal: 16.w),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.audiotrack,
                                          color: AppTheme.primaryColor,
                                          size: 20.w,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          l10n.audioBioAvailable,
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: Icon(
                                            _isPlaying
                                                ? Icons.stop
                                                : Icons.play_arrow,
                                            color: AppTheme.primaryColor,
                                          ),
                                          onPressed: _playAudio,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                IconButton(
                                  onPressed: _startRecording,
                                  icon: const Icon(Icons.refresh),
                                  tooltip: l10n.recordNewAudio,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                  ),
                                ),
                              ],
                            )
                          else
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _startRecording,
                                icon: const Icon(Icons.mic),
                                label: Text(l10n.recordAudioBio),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24.w, vertical: 12.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(height: 8.h),
                          Text(
                            l10n.audioBioDescription,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Add Language Selector here, before the city field
                    SizedBox(height: 16.h),

                    // Language selector
                    _buildLanguageSelector(l10n.preferredLanguage),

                    SizedBox(height: 16.h),

                    // City field with search and geolocation
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _cityController,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: AppTheme.textPrimaryColor,
                            ),
                            onChanged: _searchPlaces,
                            decoration: InputDecoration(
                              labelText: l10n.city,
                              labelStyle: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 13.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.location_city_outlined,
                                size: 20.w,
                                color: AppTheme.textSecondaryColor,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Clear button - only show when there's text
                                  if (_cityController.text.isNotEmpty)
                                    IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        size: 16.w,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _cityController.clear();
                                          _placePredictions = [];
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  // Get current location button
                                  IconButton(
                                    icon: _isGettingLocation
                                        ? SizedBox(
                                            width: 16.w,
                                            height: 16.w,
                                            child:
                                                const CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                      AppTheme.primaryColor),
                                            ),
                                          )
                                        : Icon(
                                            Icons.my_location,
                                            size: 16.w,
                                            color: AppTheme.primaryColor,
                                          ),
                                    onPressed: _isGettingLocation
                                        ? null
                                        : _getCurrentLocation,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide: BorderSide(
                                  color: AppTheme.primaryColor.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide: BorderSide(
                                  color: Colors.red.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 14.h, horizontal: 18.w),
                              isDense: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.pleaseEnterCity;
                              }
                              return null;
                            },
                          ),
                        ),

                        // Place predictions dropdown
                        if (_placePredictions.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            constraints: BoxConstraints(maxHeight: 150.h),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: _placePredictions.length > 5
                                  ? 5
                                  : _placePredictions.length,
                              itemBuilder: (context, index) {
                                final prediction = _placePredictions[index];
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _selectPlace(prediction),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12.w, vertical: 8.h),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 16.w,
                                            color: AppTheme.primaryColor,
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  prediction
                                                          .structuredFormatting
                                                          ?.mainText ??
                                                      prediction.description
                                                          .split(',')
                                                          .first,
                                                  style: TextStyle(
                                                    fontSize: 13.sp,
                                                    color: AppTheme
                                                        .textPrimaryColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (prediction
                                                        .structuredFormatting
                                                        ?.secondaryText !=
                                                    null)
                                                  Text(
                                                    prediction
                                                        .structuredFormatting!
                                                        .secondaryText!,
                                                    style: TextStyle(
                                                      fontSize: 11.sp,
                                                      color: AppTheme
                                                          .textSecondaryColor,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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

                    // For professional users, add activity selection
                    if (_isProfessional) ...[
                      SizedBox(height: 24.h),

                      Text(
                        l10n.professionalActivity,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Grid of profession cards
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 8.w,
                          mainAxisSpacing: 8.h,
                        ),
                        itemCount: _mainActivities.length,
                        itemBuilder: (context, index) {
                          final activity = _mainActivities[index];
                          final isSelected =
                              _selectedActivity == activity['name'];

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedActivity = activity['name'];
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey[200]!,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.3),
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
                                    activity['icon'],
                                    size: 24.w,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimaryColor,
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    activity['name'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 16.h),

                      // Dropdown for other activities
                      _buildDropdownField(
                        labelText: l10n.selectOtherActivity,
                        prefixIcon: Icons.work_outline_rounded,
                        value: _additionalActivities.contains(_selectedActivity)
                            ? _selectedActivity
                            : null,
                        items: _additionalActivities.map((String activity) {
                          return DropdownMenuItem<String>(
                            value: activity,
                            child: Text(activity,
                                style: TextStyle(fontSize: 13.sp)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedActivity = newValue;
                          });
                        },
                      ),
                    ],

                    // Error message
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 10.h, horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: Colors.red,
                                size: 18.w,
                              ),
                              SizedBox(width: 8.w),
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

                    SizedBox(height: 24.h),

                    // Save and Cancel buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              side: const BorderSide(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            child: Text(
                              l10n.cancel,
                              style:
                                  const TextStyle(color: AppTheme.primaryColor),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: _isSaving
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.saveChanges),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 15.sp,
          color: AppTheme.textPrimaryColor,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 13.sp,
          ),
          prefixIcon: Icon(
            prefixIcon,
            size: 20.w,
            color: AppTheme.textSecondaryColor,
          ),
          prefixIconConstraints:
              BoxConstraints(minWidth: 40.w, minHeight: 40.h),
          suffixIcon: suffixIcon,
          suffixIconConstraints: suffixIcon != null
              ? BoxConstraints(minWidth: 40.w, minHeight: 40.h)
              : null,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: AppTheme.primaryColor.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: Colors.red.withOpacity(0.5),
              width: 1,
            ),
          ),
          contentPadding:
              EdgeInsets.symmetric(vertical: 14.h, horizontal: 18.w),
          isDense: true,
          errorStyle: TextStyle(fontSize: 11.sp),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String labelText,
    required IconData prefixIcon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: TextStyle(
        fontSize: 14.sp,
        color: AppTheme.textPrimaryColor,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: AppTheme.textSecondaryColor,
          fontSize: 12.sp,
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: 18.w,
          color: AppTheme.textSecondaryColor,
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
      dropdownColor: Colors.white,
      icon: Icon(
        Icons.arrow_drop_down_rounded,
        size: 20.w,
        color: AppTheme.textSecondaryColor,
      ),
      isExpanded: true,
      menuMaxHeight: 200.h,
      hint: Text(
        "Select an option",
        style: TextStyle(
          fontSize: 12.sp,
          color: AppTheme.textSecondaryColor.withOpacity(0.5),
        ),
      ),
    );
  }

  // Add the language selector widget copied from registration page
  Widget _buildLanguageSelector(String labelText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(14.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _languages.map((language) {
                  final isSelected = _selectedLanguage == language['code'];
                  return GestureDetector(
                    onTap: () {
                      // Get the language provider and update it immediately
                      final languageProvider =
                          Provider.of<LanguageProvider>(context, listen: false);
                      final String languageCode = language['code'] as String;

                      // Update both the UI state and the app's language
                      setState(() {
                        _selectedLanguage = languageCode;
                      });

                      // Apply the language change immediately
                      languageProvider.setLocale(Locale(languageCode));
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding:
                          EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        language['name'],
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
