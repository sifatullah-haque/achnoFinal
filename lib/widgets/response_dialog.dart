import 'dart:io';
import 'package:achno/services/notification_service.dart';
import 'package:achno/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:achno/config/theme.dart';
import 'package:achno/models/post_model.dart';
import 'package:provider/provider.dart';
import 'package:achno/providers/auth_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';

class ResponseDialog extends StatefulWidget {
  final Post post;
  final VoidCallback? onSuccess;

  const ResponseDialog({
    super.key,
    required this.post,
    this.onSuccess,
  });

  @override
  _ResponseDialogState createState() => _ResponseDialogState();
}

class _ResponseDialogState extends State<ResponseDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  // Audio recording variables
  String? _recordedAudioPath;
  bool _isRecording = false;
  bool _recorderInitialized = false;
  PermissionStatus _micPermissionStatus = PermissionStatus.denied;
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  // Audio recorder and player
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;

  // Animation controller for UI effects
  late AnimationController _animationController;

  // Audio visualization
  final List<double> _audioWaveform = [];
  final int _maxWaveformPoints = 30;

  @override
  void initState() {
    super.initState();
    _initializeRecordingFunctionality();
    _initializePlayer();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.storage,
      ].request();

      bool allGranted = statuses.values.every((status) => status.isGranted);

      setState(() {
        _micPermissionStatus =
            statuses[Permission.microphone] ?? PermissionStatus.denied;
      });

      if (allGranted) {
        await _initializeRecorder();
      } else {
        setState(() {
          _errorMessage = 'Microphone and storage permissions are required';
        });
      }
    } catch (e) {
      debugPrint('Error initializing recording: $e');
      setState(() {
        _errorMessage = 'Failed to initialize recording: $e';
      });
    }
  }

  // Initialize recorder
  Future<void> _initializeRecorder() async {
    try {
      await _recorder.openRecorder();

      // Configure audio session
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
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
      setState(() {
        _recorderInitialized = false;
        _errorMessage = 'Failed to initialize recorder: $e';
      });
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
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
        setState(() {
          _errorMessage = 'Microphone permission required';
        });
      }
    } catch (e) {
      debugPrint('Error requesting microphone permission: $e');
    }
  }

  // Start recording
  Future<void> _startRecording() async {
    if (!_recorderInitialized) {
      await _requestMicrophonePermission();
      if (!_recorderInitialized) {
        setState(() {
          _errorMessage = 'Voice recorder not initialized';
        });
        return;
      }
    }

    try {
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/response_audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      // Set up audio level subscription for visualization
      _audioWaveform.clear();
      _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));

      // Use null-aware operator
      _recorder.onProgress?.listen((event) {
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
        _errorMessage = '';
      });

      // Start timer to track recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start recording: ${e.toString()}';
      });
    }
  }

  // Stop recording
  Future<void> _stopRecording() async {
    if (!_isRecording) return;

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

  // Play recording
  Future<void> _playRecording() async {
    if (_recordedAudioPath == null || _isPlaying) return;

    try {
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
        _errorMessage = 'Failed to play recording';
        _isPlaying = false;
      });
    }
  }

  // Stop playing
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

  // Delete recording
  Future<void> _deleteRecording() async {
    if (_recordedAudioPath != null) {
      try {
        final file = File(_recordedAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting recording: $e');
      }

      setState(() {
        _recordedAudioPath = null;
        _recordingDuration = 0;
      });
    }
  }

  // Format duration for display
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Send response - update to create a conversation
  Future<void> _sendResponse() async {
    // Check if we have message or audio
    if (_messageController.text.isEmpty && _recordedAudioPath == null) {
      setState(() {
        _errorMessage = 'Please provide a message or record audio';
      });
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
          _errorMessage = 'You must be logged in to respond';
          _isLoading = false;
        });
        return;
      }

      // Upload audio if recorded
      String? audioUrl;
      if (_recordedAudioPath != null) {
        final file = File(_recordedAudioPath!);
        final fileName =
            'response_audio_${DateTime.now().millisecondsSinceEpoch}.aac';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('audio_responses')
            .child(fileName);

        await storageRef.putFile(file);
        audioUrl = await storageRef.getDownloadURL();
      }

      // Create or get existing conversation
      String conversationId =
          await _getOrCreateConversation(currentUser.id, widget.post.userId);

      // Handle both text and audio presence
      bool hasText = _messageController.text.isNotEmpty;
      bool hasAudio = audioUrl != null;

      // If both text and audio are present, send two separate messages
      if (hasText && hasAudio) {
        // Send text message first
        final textMessage = {
          'senderId': currentUser.id,
          'content': _messageController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'text',
          'status': 'MessageStatus.sent',
        };

        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .add(textMessage);

        // Then send audio message
        final audioMessage = {
          'senderId': currentUser.id,
          'content': audioUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'audio',
          'status': 'MessageStatus.sent',
          'audioDuration': _recordingDuration,
        };

        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .add(audioMessage);

        // Update conversation metadata with audio as the latest message
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .update({
          'lastMessage': 'Audio message',
          'lastMessageType': 'audio',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'lastMessageSenderId': currentUser.id,
          'unreadCount.${widget.post.userId}': FieldValue.increment(1),
        });
      } else {
        // Handle single message type (text or audio)
        final message = {
          'senderId': currentUser.id,
          'content': hasText ? _messageController.text : audioUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'type': hasText ? 'text' : 'audio',
          'status': 'MessageStatus.sent',
        };

        // If it's an audio message, add audioDuration
        if (!hasText && hasAudio) {
          message['audioDuration'] = _recordingDuration;
        }

        // Add message to conversation
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .add(message);

        // Update conversation metadata
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .update({
          'lastMessage': hasText ? _messageController.text : 'Audio message',
          'lastMessageType': hasText ? 'text' : 'audio',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'lastMessageSenderId': currentUser.id,
          'unreadCount.${widget.post.userId}': FieldValue.increment(1),
        });
      }

      // Create response document in Firestore (for the original post tracking)
      // Update to include both text and audio if available
      await FirebaseFirestore.instance.collection('responses').add({
        'postId': widget.post.id,
        'postOwnerId': widget.post.userId,
        'responderId': currentUser.id,
        'responderName': '${currentUser.firstName} ${currentUser.lastName}',
        'responderAvatar': currentUser.profilePicture,
        'message': _messageController.text,
        'audioUrl': audioUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'postType': widget.post.type == PostType.request ? 'request' : 'offer',
        'postActivity': widget.post.activity,
        'conversationId': conversationId, // Store the conversation ID
      });

      // Update responses count in the post
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .update({
        'responses': FieldValue.increment(1),
      });

      // Create notification for the post owner about the new message
      final notificationService = NotificationService();
      await notificationService.sendNotificationToUser(
        userId: widget.post.userId,
        title: 'New Message',
        message:
            '${currentUser.firstName} ${currentUser.lastName} sent you a message',
        type: NotificationType.message,
        relatedItemId: conversationId,
        senderName: '${currentUser.firstName} ${currentUser.lastName}',
        senderAvatar: currentUser.profilePicture,
        senderId: currentUser.id,
      );

      // Close dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Call success callback if provided
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }

      // Navigate to message details page with additional post information
      GoRouter.of(context).push(
        '/chat/$conversationId',
        extra: {
          'contactName': widget.post.userName,
          'contactAvatar': widget.post.userAvatar,
          'contactId': widget.post.userId,
          'relatedPost': widget.post, // Pass the post object
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send response: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to get existing conversation or create a new one
  Future<String> _getOrCreateConversation(
      String userId1, String userId2) async {
    try {
      // Order the user IDs to ensure consistent conversation IDs
      final List<String> participants = [userId1, userId2];
      participants.sort(); // Sort to ensure consistent ordering

      // Check if a conversation already exists between these users
      final querySnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', isEqualTo: participants)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Conversation exists, return its ID
        return querySnapshot.docs.first.id;
      }

      // No conversation exists, create a new one
      // Get user data for both users
      final user1Doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId1)
          .get();

      final user2Doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId2)
          .get();

      if (!user1Doc.exists || !user2Doc.exists) {
        throw Exception('One or both users do not exist');
      }

      final user1Data = user1Doc.data()!;
      final user2Data = user2Doc.data()!;

      // Create conversation with metadata
      final conversationRef =
          FirebaseFirestore.instance.collection('conversations').doc();
      await conversationRef.set({
        'participants': participants,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageType': 'text',
        'lastMessageSenderId': userId1,
        'unreadCount': {
          userId1: 0,
          userId2: 0,
        },
        'userData': {
          userId1: {
            'name': '${user1Data['firstName']} ${user1Data['lastName']}',
            'avatar': user1Data['profilePicture'],
          },
          userId2: {
            'name': '${user2Data['firstName']} ${user2Data['lastName']}',
            'avatar': user2Data['profilePicture'],
          },
        },
      });

      return conversationRef.id;
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    _stopRecording();
    _stopPlaying();
    _recordingTimer?.cancel();

    // Clean up recorder and player
    try {
      if (_recorderInitialized) {
        _recorder.closeRecorder();
      }
      _player.closePlayer();
    } catch (e) {
      debugPrint('Error disposing resources: $e');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: 500.w,
                maxHeight: 550.h,
              ),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey[900]!.withOpacity(0.9)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.darkAccentColor
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Respond to Post',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                borderRadius: BorderRadius.circular(20.r),
                                child: Container(
                                  padding: EdgeInsets.all(5.w),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18.w,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(
                                widget.post.type == PostType.request
                                    ? Icons.help_outline
                                    : Icons.handyman_outlined,
                                size: 14.w,
                                color: Colors.white70,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  widget.post.activity,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Original post preview
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[800]!.withOpacity(0.5)
                                  : Colors.grey[100]!.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.02),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16.r,
                                      backgroundColor: AppTheme.primaryColor
                                          .withOpacity(0.2),
                                      backgroundImage: widget.post.userAvatar !=
                                                  null &&
                                              widget.post.userAvatar!.isNotEmpty
                                          ? NetworkImage(
                                              widget.post.userAvatar!)
                                          : null,
                                      child: widget.post.userAvatar == null ||
                                              widget.post.userAvatar!.isEmpty
                                          ? Icon(
                                              Icons.person,
                                              color: AppTheme.primaryColor,
                                              size: 18.r,
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 8.w),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.post.userName,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          widget.post.city,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: isDarkMode
                                                ? Colors.white60
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                if (widget.post.message.isNotEmpty)
                                  Text(
                                    widget.post.message,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),

                          SizedBox(height: 16.h),

                          // Voice recording section (prioritized)
                          Container(
                            padding: EdgeInsets.all(12.w),
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
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _buildVoiceRecordingSection(isDarkMode),
                          ),

                          SizedBox(height: 16.h),

                          // Message input (secondary)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Message (Optional)',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Add a text message...',
                                  filled: true,
                                  fillColor: isDarkMode
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: isDarkMode
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 12.h,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                maxLines: 3,
                                minLines: 2,
                              ),
                            ],
                          ),

                          // Error message
                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 12.h),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 16.w,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
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
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.2)
                          : Colors.grey[100]?.withOpacity(0.8),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20.r),
                        bottomRight: Radius.circular(20.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 2, // Give less space to cancel button
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              side: BorderSide(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 3, // Give more space to send button
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendResponse,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              shadowColor:
                                  AppTheme.primaryColor.withOpacity(0.4),
                              elevation: 2,
                              minimumSize: Size(double.infinity, 50.h),
                            ).copyWith(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return isDarkMode
                                        ? Colors.grey.withOpacity(0.3)
                                        : Colors.grey.shade300;
                                  }
                                  return Colors.transparent;
                                },
                              ),
                              overlayColor: WidgetStateProperty.all(
                                  Colors.white.withOpacity(0.1)),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: _isLoading
                                    ? null
                                    : const LinearGradient(
                                        colors: [
                                          AppTheme.primaryColor,
                                          AppTheme.darkAccentColor
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Container(
                                height: 50.h, // Fixed height
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? SizedBox(
                                        height: 24.h,
                                        width: 24.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            isDarkMode
                                                ? Colors.white
                                                : AppTheme.primaryColor,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.send,
                                            size: 18.w,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 10.w),
                                          Text(
                                            'Send Response',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Voice recording section
  Widget _buildVoiceRecordingSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(
              Icons.mic,
              color: Colors.white,
              size: 16.w,
            ),
            SizedBox(width: 6.w),
            Text(
              'Voice Message',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: Colors.white,
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
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        'Allow',
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

        // Audio waveform visualization
        if (_isRecording && _audioWaveform.isNotEmpty)
          Container(
            height: 40.h,
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 5.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                _audioWaveform.length,
                (index) => _buildWaveformBar(_audioWaveform[index], index),
              ),
            ),
          ),

        if (_recordedAudioPath != null && !_isRecording)
          // Display recorded audio player
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                    size: 20.w,
                  ),
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
                        'Audio recording',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _formatDuration(_recordingDuration),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
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
          // Permission denied message
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
                  'Microphone access needed',
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
          // Initialization failed
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
                    padding: EdgeInsets.symmetric(
                      vertical: 4.h,
                      horizontal: 8.w,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text('Try Again', style: TextStyle(fontSize: 12.sp)),
                ),
              ],
            ),
          )
        else
          // Record button with pulse animation
          Center(
            child: Column(
              children: [
                _buildPulseAnimation(
                  child: GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: Container(
                      width: 60.w,
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
                        color:
                            _isRecording ? Colors.white : AppTheme.primaryColor,
                        size: 30.w,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _isRecording
                      ? _formatDuration(_recordingDuration)
                      : 'Tap to record',
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
                      'Tap to stop',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // Helper method to build waveform bars
  Widget _buildWaveformBar(double amplitude, int index) {
    final minHeight = 3.h;
    final maxHeight = 25.h;
    final height = minHeight + (maxHeight - minHeight) * amplitude;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 3.w,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          index == _audioWaveform.length - 1
              ? 1.0
              : 0.5 + (index / (_audioWaveform.length * 2)),
        ),
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
}
