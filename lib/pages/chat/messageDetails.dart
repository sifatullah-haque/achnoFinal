import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:achno/config/theme.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:ui';
import 'package:achno/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:achno/providers/auth_provider.dart';
import 'dart:math' as math;
import 'package:achno/models/post_model.dart';
import 'package:achno/pages/profile/viewProfile.dart';
import 'package:image_picker/image_picker.dart';

class MessageDetails extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final String? contactAvatar;
  final String? contactId; // Add contactId parameter
  final Post? relatedPost; // Add this parameter to receive post data

  const MessageDetails({
    super.key,
    required this.conversationId,
    required this.contactName,
    this.contactAvatar,
    this.contactId, // Add this parameter
    this.relatedPost, // Add relatedPost parameter
  });

  @override
  _MessageDetailsState createState() => _MessageDetailsState();
}

class _MessageDetailsState extends State<MessageDetails>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Recording and playback
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _recorderInitialized = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedAudioPath;
  String _currentlyPlayingId = '';
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  PermissionStatus _micPermissionStatus = PermissionStatus.denied;
  final bool _showEmojiPicker = false;

  // Audio visualization
  final List<double> _audioWaveform = [];
  final int _maxWaveformPoints = 30;

  // Animation controllers
  late AnimationController _micAnimationController;
  late AnimationController _sendButtonAnimationController;
  late Animation<double> _micAnimation;

  // Add animation controller for audio visualization
  late AnimationController _audioVisualizationController;

  // Generate random visualization spikes data
  final Map<String, List<double>> _audioVisualizationData = {};
  final int _spikeCount = 27; // Number of spikes to show

  // Messages list - would be replaced with Firebase data
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String _currentUserId = '';
  bool _isSendingMessage = false;
  bool _isSendingAudio = false;
  bool _isSendingImage = false;
  String _contactCity = ''; // Add variable to store contact city

  // Variables to store related post info
  Post? _relatedPost;

  // Add a new state variable to track recording status
  bool _recordingStopped = false;

  // Add a fixed random seed for consistent avatar color
  final int _avatarColorSeed = 42;

  // Add new variables for audio progress tracking
  Duration? _audioDuration;
  Duration? _audioPosition;
  StreamSubscription? _playerSubscription;

  // Track currently playing audio in bottom sheet
  String? _currentlyPlayingModalAudioUrl;
  bool _isModalAudioPlaying = false;

  // Add image picker instance
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _initializeAudio();

    // Add safe check before loading messages
    if (widget.conversationId.isNotEmpty) {
      _loadMessages();
      _setupMessagesListener();
    } else {
      setState(() {
        _isLoading = false;
        _messages = [];
      });
    }

    // Add null check for contact info loading
    if (widget.contactId != null && widget.contactId!.isNotEmpty) {
      _loadContactInfo();
    }

    // Safely load related post info only if there's a valid conversation ID
    if (widget.conversationId.isNotEmpty) {
      _loadRelatedPostInfo();
    }

    // Store the related post if provided
    if (widget.relatedPost != null) {
      _relatedPost = widget.relatedPost;
    }

    // Setup animations
    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _sendButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _micAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _micAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize audio visualization animation controller
    _audioVisualizationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Fix: Make sure the text controller listener is added properly
    _messageController.addListener(_handleTextFieldChange);

    // Add listener for new messages
    _setupMessagesListener();

    // Set up audio progress subscription to track playback progress
    _setupPlayerSubscription();
  }

  Future<void> _getCurrentUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      setState(() {
        _currentUserId = authProvider.currentUser!.id;
      });
    }
  }

  // Add method to load contact city - add null checks
  Future<void> _loadContactInfo() async {
    if (widget.contactId == null || widget.contactId!.isEmpty) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.contactId)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _contactCity = userDoc.data()?['city'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading contact info: $e');
    }
  }

  // Add method to load related post information - add null checks
  Future<void> _loadRelatedPostInfo() async {
    if (_relatedPost != null || widget.conversationId.isEmpty) {
      return; // Skip if already loaded or no conversation ID
    }

    try {
      // Try to find a response document that links this conversation to a post
      final responseQuery = await FirebaseFirestore.instance
          .collection('responses')
          .where('conversationId', isEqualTo: widget.conversationId)
          .limit(1)
          .get();

      if (responseQuery.docs.isNotEmpty) {
        final responseData = responseQuery.docs.first.data();
        final postId = responseData['postId'] as String?;

        if (postId != null) {
          // Fetch the post data
          final postDoc = await FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .get();

          if (postDoc.exists && mounted) {
            // Fix: Extract data from the document snapshot
            final postData = postDoc.data() as Map<String, dynamic>;
            setState(() {
              _relatedPost = Post.fromFirestore(
                  postData, postId, false // Default isLiked value
                  );
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading related post: $e');
    }
  }

  void _handleTextFieldChange() {
    // Fix: Update this method to properly handle text changes without refreshing
    if (_messageController.text.isNotEmpty) {
      if (!_sendButtonAnimationController.isCompleted) {
        _sendButtonAnimationController.forward();
      }
    } else {
      if (_sendButtonAnimationController.isCompleted) {
        _sendButtonAnimationController.reverse();
      }
    }
    // Remove setState here to prevent refreshing the entire page
  }

  Future<void> _initializeAudio() async {
    try {
      // Check microphone permission
      final status = await Permission.microphone.status;
      setState(() {
        _micPermissionStatus = status;
      });

      if (status.isGranted) {
        await _initializeRecorder();
        await _initializePlayer();
      }
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }

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
      });
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
    }
  }

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

  // Add a method to listen for new messages
  void _setupMessagesListener() {
    if (widget.conversationId.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty && mounted) {
          _loadMessages();
        }
      });
    }
  }

  // Modify _loadMessages to fetch from Firestore
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.conversationId.isEmpty) {
        setState(() {
          _messages = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch messages from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .orderBy('timestamp')
          .get();

      final messages = querySnapshot.docs.map((doc) {
        final data = doc.data();
        MessageType messageType;
        switch (data['type']) {
          case 'audio':
            messageType = MessageType.audio;
            break;
          case 'image':
            messageType = MessageType.image;
            break;
          default:
            messageType = MessageType.text;
        }

        return ChatMessage(
          id: doc.id,
          senderId: data['senderId'] ?? '',
          content: data['content'] ?? '',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          type: messageType,
          status: _parseMessageStatus(data['status']),
          audioDuration: data['audioDuration'],
        );
      }).toList();

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Mark messages as read
      _markMessagesAsRead();

      // Scroll to bottom after messages load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading messages: $e');
    }
  }

  // Add method to mark messages as read
  Future<void> _markMessagesAsRead() async {
    if (widget.conversationId.isEmpty || _currentUserId.isEmpty) return;

    try {
      // Get unread messages not sent by current user
      final querySnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: _currentUserId)
          .where('status', isEqualTo: 'MessageStatus.delivered')
          .get();

      // Update each message to read status
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'status': 'MessageStatus.read'});
      }

      // Execute batch update
      await batch.commit();

      // Update conversation last read timestamp
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastReadBy.$_currentUserId': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Helper method to parse MessageStatus
  static MessageStatus? _parseMessageStatus(String? status) {
    if (status == null) return null;
    switch (status) {
      case 'MessageStatus.sending':
        return MessageStatus.sending;
      case 'MessageStatus.sent':
        return MessageStatus.sent;
      case 'MessageStatus.delivered':
        return MessageStatus.delivered;
      case 'MessageStatus.read':
        return MessageStatus.read;
      case 'MessageStatus.error':
        return MessageStatus.error;
      default:
        return MessageStatus.sent;
    }
  }

  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    setState(() {
      _micPermissionStatus = status;
    });

    if (status.isGranted) {
      await _initializeRecorder();
      await _initializePlayer();
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  // Start recording
  Future<void> _startRecording() async {
    if (_isRecording) return; // Don't start if already recording

    setState(() {
      _recordingStopped =
          false; // Reset this flag when starting a new recording
    });

    if (!_recorderInitialized) {
      await _requestMicrophonePermission();
      if (!_recorderInitialized) return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/message_audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      // Set up audio level subscription for visualization
      _audioWaveform.clear();
      _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));

      // Handle null case with null-aware operator
      _recorder.onProgress?.listen((event) {
        double level = event.decibels ?? -160.0;
        level = (level + 160) / 160; // Normalize between 0 and 1

        if (mounted) {
          setState(() {
            if (_audioWaveform.length >= _maxWaveformPoints) {
              _audioWaveform.removeAt(0);
            }
            _audioWaveform.add(level.clamp(0.05, 1.0));
          });
        }
      });

      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _recordedAudioPath = filePath;
        _recordingDuration = 0;
      });

      // Start timer to track recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration++;
          });
        }
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      _recordingTimer?.cancel();
      await _recorder.stopRecorder();
      _micAnimationController.stop();
      _micAnimationController.reset();

      setState(() {
        _isRecording = false;
        _recordingStopped = true; // Set this flag when recording is stopped
      });

      // Don't auto-send the audio anymore
      // _sendAudioMessage(); - Remove this line
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;

    try {
      _recordingTimer?.cancel();
      await _recorder.stopRecorder();
      _micAnimationController.stop();
      _micAnimationController.reset();

      // Delete recorded file
      if (_recordedAudioPath != null) {
        final file = File(_recordedAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      setState(() {
        _isRecording = false;
        _recordedAudioPath = null;
        _recordingDuration = 0;
      });
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    }
  }

  Future<void> _playAudio(String messageId, String audioUrl) async {
    if (_isPlaying && _currentlyPlayingId == messageId) {
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
        _audioDuration = null;
      });

      await _player.startPlayer(
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
        _currentlyPlayingId = messageId;
      });
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> _stopAudio() async {
    if (!_isPlaying) return;

    try {
      await _player.stopPlayer();
      setState(() {
        _isPlaying = false;
        _currentlyPlayingId = '';
      });
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  // Add method to play audio in the modal bottom sheet
  Future<void> _playPostAudio(String audioUrl) async {
    if (_isModalAudioPlaying && _currentlyPlayingModalAudioUrl == audioUrl) {
      await _stopModalAudio();
      return;
    }

    if (_isPlaying) {
      await _stopAudio();
    }

    if (_isModalAudioPlaying) {
      await _stopModalAudio();
    }

    try {
      // Reset audio progress tracking
      setState(() {
        _audioPosition = Duration.zero;
        _audioDuration = null;
      });

      await _player.startPlayer(
        fromURI: audioUrl,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {
            _isModalAudioPlaying = false;
            _currentlyPlayingModalAudioUrl = null;
            _audioPosition = null;
          });
        },
      );

      setState(() {
        _isModalAudioPlaying = true;
        _currentlyPlayingModalAudioUrl = audioUrl;
      });
    } catch (e) {
      debugPrint('Error playing post audio: $e');
    }
  }

  // Stop modal audio playback
  Future<void> _stopModalAudio() async {
    if (!_isModalAudioPlaying) return;

    try {
      await _player.stopPlayer();
      setState(() {
        _isModalAudioPlaying = false;
        _currentlyPlayingModalAudioUrl = null;
        _audioPosition = null;
      });
    } catch (e) {
      debugPrint('Error stopping modal audio: $e');
    }
  }

  String _formatDurationSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Format duration for display when provided with Duration object
  String _formatDurationObj(Duration? duration) {
    if (duration == null) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // Update _sendTextMessage to save to Firestore
  Future<void> _sendTextMessage() async {
    final l10n = AppLocalizations.of(context);

    // Check if conversation ID is valid
    if (widget.conversationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.cannotSendMessage ??
                'Cannot send message: Invalid conversation')),
      );
      return;
    }

    // If there's a stopped recording, send that instead of text
    if (_recordingStopped && _recordedAudioPath != null) {
      await _sendAudioMessage();
      return;
    }

    // Check if there's actual text to send
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      // Create new message
      final newMessage = {
        'senderId': _currentUserId,
        'content': text,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'status': 'MessageStatus.sent',
      };

      // Create local message for immediate UI update
      final localMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        content: text,
        timestamp: DateTime.now(),
        type: MessageType.text,
        status: MessageStatus.sending,
      );

      // Important: First clear the text field
      final textToSend = text; // Keep a copy of the text
      setState(() {
        _messages.add(localMessage);
        _messageController.clear(); // Clear immediately
      });

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Send to Firestore
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add(newMessage);

      // Update conversation metadata - add null check for contactId
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessage': textToSend,
        'lastMessageType': 'text',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _currentUserId,
        // Only increment unread count if contactId is not null or empty
        if (widget.contactId != null && widget.contactId!.isNotEmpty)
          'unreadCount.${widget.contactId}': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${l10n.errorSendingMessage ?? 'Error sending message'}: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  // Update _sendAudioMessage to save to Firestore
  Future<void> _sendAudioMessage() async {
    final l10n = AppLocalizations.of(context);

    if (_recordedAudioPath == null) return;

    // Keep track of path locally since we'll clear it right away
    final String recordingPath = _recordedAudioPath!;
    final int duration = _recordingDuration;

    setState(() {
      _isSendingAudio = true;
      _recordingStopped = false; // Reset this flag
      _recordedAudioPath =
          null; // Clear the path immediately to show text input
    });

    try {
      final file = File(recordingPath);
      if (!await file.exists()) {
        debugPrint('Audio file does not exist');
        setState(() {
          _isSendingAudio = false;
        });
        return;
      }

      // Create local copy of message for immediate UI update
      final localMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
        senderId: _currentUserId,
        content: l10n.sendingAudio ?? "Sending audio...", // Placeholder
        timestamp: DateTime.now(),
        type: MessageType.audio,
        status: MessageStatus.sending,
        audioDuration: duration,
      );

      // Update local UI immediately
      setState(() {
        _messages.add(localMessage);
        _recordingDuration = 0;
      });

      // Scroll to bottom to show the new message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Upload audio to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('audio_messages')
          .child('${DateTime.now().millisecondsSinceEpoch}.aac');

      await storageRef.putFile(file);
      final audioUrl = await storageRef.getDownloadURL();

      // Create new message
      final newMessage = {
        'senderId': _currentUserId,
        'content': audioUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'audio',
        'audioDuration': duration,
        'status': 'MessageStatus.sent',
      };

      // Add message to Firestore
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add(newMessage);

      // Update conversation metadata - add null check for contactId
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessage': l10n.audioMessage ?? 'Audio message',
        'lastMessageType': 'audio',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _currentUserId,
        // Only increment unread count if contactId is not null or empty
        if (widget.contactId != null && widget.contactId!.isNotEmpty)
          'unreadCount.${widget.contactId}': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error sending audio message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${l10n.errorSendingAudio ?? 'Error sending audio message'}: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingAudio = false;
        });
      }
    }
  }

  // Add method to pick and send image
  Future<void> _pickAndSendImage() async {
    final l10n = AppLocalizations.of(context);

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _sendImageMessage(File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${l10n.errorSelectingImage ?? 'Error selecting image'}: ${e.toString()}')),
      );
    }
  }

  // Add method to send image message
  Future<void> _sendImageMessage(File imageFile) async {
    final l10n = AppLocalizations.of(context);

    if (widget.conversationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.cannotSendImage ??
                'Cannot send image: Invalid conversation')),
      );
      return;
    }

    setState(() {
      _isSendingImage = true;
    });

    try {
      // Create local message for immediate UI update
      final localMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        content: l10n.sendingImage ?? "Sending image...",
        timestamp: DateTime.now(),
        type: MessageType.image,
        status: MessageStatus.sending,
      );

      // Update local UI immediately
      setState(() {
        _messages.add(localMessage);
      });

      // Scroll to bottom to show the new message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(imageFile);
      final imageUrl = await storageRef.getDownloadURL();

      // Create new message
      final newMessage = {
        'senderId': _currentUserId,
        'content': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'image',
        'status': 'MessageStatus.sent',
      };

      // Add message to Firestore
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add(newMessage);

      // Update conversation metadata
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessage': l10n.image ?? 'Image',
        'lastMessageType': 'image',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _currentUserId,
        // Only increment unread count if contactId is not null or empty
        if (widget.contactId != null && widget.contactId!.isNotEmpty)
          'unreadCount.${widget.contactId}': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error sending image message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${l10n.errorSendingImage ?? 'Error sending image'}: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingImage = false;
        });
      }
    }
  }

  // Add method to delete recording and show text field again
  void _deleteAudioRecording() {
    if (_recordedAudioPath != null) {
      try {
        // Create a File object from the path
        final file = File(_recordedAudioPath!);

        // Delete the file if it exists (non-awaited since we're in a sync method)
        file.exists().then((exists) {
          if (exists) {
            file.delete();
          }
        });
      } catch (e) {
        debugPrint('Error deleting audio file: $e');
      }
    }

    // Reset recording state
    setState(() {
      _recordingStopped = false;
      _recordedAudioPath = null;
      _recordingDuration = 0;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Initialize audio visualization with random spikes for a message
  List<double> _getAudioVisualizationData(String messageId) {
    if (!_audioVisualizationData.containsKey(messageId)) {
      final random = math.Random(messageId
          .hashCode); // Use messageId as seed for consistent visualization
      final visualizationData = <double>[];

      // Generate random but somewhat realistic looking waveform data
      for (int i = 0; i < _spikeCount; i++) {
        // Create a pattern that looks like audio waveform
        double height;
        if (i < 5 || i > _spikeCount - 5) {
          // Lower at the edges
          height = 0.1 + random.nextDouble() * 0.3;
        } else if ((i > 8 && i < 12) ||
            (i > _spikeCount - 12 && i < _spikeCount - 8)) {
          // Higher in the middle sections
          height = 0.4 + random.nextDouble() * 0.4;
        } else {
          // Highest in the very middle
          height = 0.3 + random.nextDouble() * 0.7;
        }
        visualizationData.add(height);
      }

      _audioVisualizationData[messageId] = visualizationData;
    }

    return _audioVisualizationData[messageId]!;
  }

  // Setup audio player subscription for progress tracking
  void _setupPlayerSubscription() {
    // Use null-aware operator (?.) instead of null assertion operator (!)
    _playerSubscription = _player.onProgress?.listen((event) {
      if (mounted) {
        setState(() {
          _audioPosition = event.position;
          _audioDuration = event.duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _micAnimationController.dispose();
    _sendButtonAnimationController.dispose();
    _audioVisualizationController.dispose();
    _recordingTimer?.cancel();
    _playerSubscription?.cancel();

    // Clean up recorder and player
    _stopRecording();
    _stopAudio();
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

  // Add new method to navigate to the ViewProfile page
  void _navigateToContactProfile() {
    final l10n = AppLocalizations.of(context);

    // Check if we have a valid contactId before navigating
    if (widget.contactId != null && widget.contactId!.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ViewProfile(userId: widget.contactId!),
        ),
      );
    } else {
      // Show an error message if contactId is missing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.cannotViewProfile ??
                'Cannot view profile: User ID not available')),
      );
    }
  }

  // Add this new method to show chat options
  void _showChatOptions() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),

                // View profile option
                if (widget.contactId != null && widget.contactId!.isNotEmpty)
                  ListTile(
                    leading: const Icon(
                      Icons.person_outline,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(l10n.viewProfile ?? 'View Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToContactProfile();
                    },
                  ),

                // View related post option
                if (_relatedPost != null)
                  ListTile(
                    leading: Icon(
                      _relatedPost!.type == PostType.request
                          ? Icons.help_outline
                          : Icons.handyman_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(l10n.viewRelatedPost ?? 'View Related Post'),
                    onTap: () {
                      Navigator.pop(context);
                      _showPostDetailsBottomSheet();
                    },
                  ),

                // Clear chat option
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  title: Text(l10n.clearChat ?? 'Clear Chat'),
                  onTap: () {
                    // Implement clear chat functionality
                    Navigator.pop(context);
                    _showClearChatConfirmation();
                  },
                ),

                SizedBox(height: 8.h),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add this method to show confirmation dialog for clearing chat
  void _showClearChatConfirmation() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearChat ?? 'Clear Chat'),
        content: Text(l10n.clearChatConfirmation ??
            'Are you sure you want to clear this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement clearing chat functionality here
              Navigator.pop(context);
              // You would add the actual implementation to delete messages
            },
            child: Text(
              l10n.clearChat ?? 'Clear',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16.r),
            bottomRight: Radius.circular(16.r),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: isDarkMode
                  ? Colors.black.withOpacity(0.7)
                  : Colors.white.withOpacity(0.9),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              iconTheme: IconThemeData(
                color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
              ),
              title: GestureDetector(
                onTap: _navigateToContactProfile,
                child: Row(
                  children: [
                    _buildContactAvatar(),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.contactName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.white
                                  : AppTheme.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _contactCity.isNotEmpty
                                ? _contactCity
                                : (l10n.user ?? 'User'),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showChatOptions();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
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
                  color: AppTheme.primaryColor.withOpacity(0.05),
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
                  color: AppTheme.accentColor.withOpacity(0.05),
                ),
              ),
            ),

            // Chat content
            Column(
              children: [
                // Post reference bar - add null check
                if (_relatedPost != null) _buildPostReferenceBar(isDarkMode),

                // Messages list
                Expanded(
                  child: _isLoading
                      ? _buildLoadingIndicator()
                      : _buildMessagesList(),
                ),

                // Input field and actions (removed recording indicator)
                _buildMessageInput(isDarkMode),

                // Emoji picker would be here if implemented
                if (_showEmojiPicker) _buildEmojiPicker(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactAvatar() {
    if (widget.contactAvatar != null) {
      return GestureDetector(
        onTap: _navigateToContactProfile,
        child: CircleAvatar(
          radius: 18.r,
          backgroundImage: NetworkImage(widget.contactAvatar!),
        ),
      );
    }

    // Fallback avatar with first letter - use fixed color seed
    return GestureDetector(
      onTap: _navigateToContactProfile,
      child: CircleAvatar(
        radius: 18.r,
        backgroundColor: Color(
                (math.Random(_avatarColorSeed).nextDouble() * 0xFFFFFF).toInt())
            .withOpacity(1.0),
        child: Text(
          widget.contactName.isNotEmpty
              ? widget.contactName[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.loadingMessages ?? 'Loading messages...',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == _currentUserId;
        final showTimestamp = index == 0 ||
            _shouldShowTimestamp(
                _messages[index - 1].timestamp, message.timestamp);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTimestamp) _buildDateDivider(message.timestamp),
            _buildMessageBubble(message, isMe),
          ],
        );
      },
    );
  }

  bool _shouldShowTimestamp(DateTime previous, DateTime current) {
    // Show timestamp if messages are at least 30 minutes apart
    return current.difference(previous).inMinutes >= 30;
  }

  Widget _buildDateDivider(DateTime timestamp) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    String dateText;
    if (messageDate == today) {
      dateText = l10n.today ?? 'Today';
    } else if (messageDate == yesterday) {
      dateText = l10n.yesterday ?? 'Yesterday';
    } else {
      dateText = '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                dateText,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.75.sw,
        ),
        child: Container(
          margin: EdgeInsets.only(
            bottom: 8.h,
            left: isMe ? 50.w : 0,
            right: isMe ? 0 : 50.w,
          ),
          decoration: BoxDecoration(
            color: message.type == MessageType.image
                ? Colors.transparent
                : isMe
                    ? AppTheme.primaryColor
                    : Colors.white,
            borderRadius: BorderRadius.circular(16.r).copyWith(
              bottomRight:
                  isMe ? const Radius.circular(0) : Radius.circular(16.r),
              bottomLeft:
                  isMe ? Radius.circular(16.r) : const Radius.circular(0),
            ),
            boxShadow: message.type == MessageType.image
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
            border: message.type == MessageType.audio ||
                    isMe ||
                    message.type == MessageType.image
                ? null
                : Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Message content
              if (message.type == MessageType.image)
                _buildImageMessage(message, isMe)
              else if (message.type == MessageType.audio)
                _buildAudioMessage(message, isMe)
              else
                _buildTextMessage(message, isMe),

              // Timestamp and status
              if (message.type != MessageType.image)
                Padding(
                  padding: EdgeInsets.only(
                    right: 8.w,
                    bottom: 4.h,
                    left: 8.w,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isMe
                              ? Colors.white70
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      if (isMe) _buildMessageStatus(message.status),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextMessage(ChatMessage message, bool isMe) {
    return Padding(
        padding: EdgeInsets.all(12.w),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 14.sp,
            color: isMe ? Colors.white : AppTheme.textPrimaryColor,
          ),
        ));
  }

  Widget _buildAudioMessage(ChatMessage message, bool isMe) {
    final isPlaying = _isPlaying && _currentlyPlayingId == message.id;
    final visualizationData = _getAudioVisualizationData(message.id);
    // Calculate progress for the visualization
    double progress = 0.0;
    try {
      if (isPlaying &&
          _audioPosition != null &&
          _audioDuration != null &&
          _audioDuration!.inMilliseconds > 0) {
        progress =
            (_audioPosition!.inMilliseconds / _audioDuration!.inMilliseconds)
                .clamp(0.0, 1.0);
      }
    } catch (e) {
      debugPrint('Error calculating progress: $e');
      progress = 0.0;
    }

    return InkWell(
      onTap: () => _playAudio(message.id, message.content),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMe
                    ? Colors.white.withOpacity(0.2)
                    : isPlaying
                        ? Colors.red.shade100
                        : AppTheme.primaryColor.withOpacity(0.1),
                border: Border.all(
                  color: isMe
                      ? Colors.white.withOpacity(0.3)
                      : isPlaying
                          ? Colors.red.shade300
                          : AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: isMe
                    ? Colors.white
                    : isPlaying
                        ? Colors.red
                        : AppTheme.primaryColor,
                size: 20.r,
              ),
            ),
            SizedBox(width: 12.w),

            // Audio visualization and duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Audio visualization
                  SizedBox(
                    height: 20.h,
                    child: Row(
                      children: List.generate(
                        visualizationData.length,
                        (index) {
                          final position =
                              index / (visualizationData.length - 1);
                          final isActive = position <= progress;

                          // Apply subtle animation to make it look alive when playing
                          double heightFactor = visualizationData[index];
                          if (isPlaying && isActive) {
                            final animation = math.sin(
                                        _audioVisualizationController.value *
                                                math.pi +
                                            index * 0.2) *
                                    0.15 +
                                0.85;
                            heightFactor *= animation;
                          }

                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 1.w),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.white.withOpacity(0.7)
                                      : isActive && isPlaying
                                          ? Colors.red
                                          : isActive
                                              ? AppTheme.primaryColor
                                              : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                                height: 16.h * heightFactor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 6.h),

                  // Display current time / total time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Current position when playing
                      Text(
                        isPlaying && _audioPosition != null
                            ? _formatDurationToTime(_audioPosition)
                            : "00:00",
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isMe
                              ? Colors.white70
                              : AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // Total duration
                      Text(
                        isPlaying && _audioDuration != null
                            ? _formatDurationToTime(_audioDuration)
                            : message.audioDuration != null
                                ? _formatSecondsToTime(message.audioDuration!)
                                : "00:00",
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isMe
                              ? Colors.white70
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add method to build image message widget
  Widget _buildImageMessage(ChatMessage message, bool isMe) {
    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r).copyWith(
        bottomRight: isMe ? const Radius.circular(0) : Radius.circular(16.r),
        bottomLeft: isMe ? Radius.circular(16.r) : const Radius.circular(0),
      ),
      child: Stack(
        children: [
          // Image
          Image.network(
            message.content,
            width: 200.w,
            height: 200.h,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200.w,
                height: 200.h,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: AppTheme.primaryColor,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200.w,
                height: 200.h,
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.grey[400],
                      size: 32.r,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      l10n.failedToLoadImage ?? 'Failed to load image',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Overlay with timestamp and status
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  bottomRight:
                      isMe ? const Radius.circular(0) : Radius.circular(16.r),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  if (isMe)
                    Icon(
                      _getStatusIcon(message.status),
                      size: 12.w,
                      color: _getStatusColor(message.status),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for message status
  IconData _getStatusIcon(MessageStatus? status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.error:
        return Icons.error_outline;
      default:
        return Icons.check;
    }
  }

  Color _getStatusColor(MessageStatus? status) {
    switch (status) {
      case MessageStatus.read:
        return Colors.blue;
      case MessageStatus.error:
        return Colors.red.shade300;
      default:
        return Colors.white70;
    }
  }

  Widget _buildMessageStatus(MessageStatus? status) {
    if (status == null) return const SizedBox();

    IconData icon;
    Color color = Colors.white70;

    switch (status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case MessageStatus.error:
        icon = Icons.error_outline;
        color = Colors.red.shade300;
        break;
    }

    return Icon(
      icon,
      size: 12.w,
      color: color,
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageInput(bool isDarkMode) {
    final l10n = AppLocalizations.of(context);
    final hasTextToSend = _messageController.text.trim().isNotEmpty;
    final hasAudioToSend = _recordingStopped && _recordedAudioPath != null;
    final canSend = (hasTextToSend || hasAudioToSend) &&
        !_isSendingMessage &&
        !_isSendingAudio &&
        !_isSendingImage;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900]!.withOpacity(0.9) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Expanded text field or recording view
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: _isRecording || _recordingStopped
                  ? _buildRecordingView(isDarkMode) // Show recording UI
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText:
                                  l10n.typeAMessage ?? 'Type a message...',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondaryColor
                                    .withOpacity(0.6),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 10.h,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isDarkMode
                                  ? Colors.white
                                  : AppTheme.textPrimaryColor,
                            ),
                            onChanged: (_) => setState(() {}),
                            maxLines: 3,
                            minLines: 1,
                          ),
                        ),
                        IconButton(
                          icon: _isSendingImage
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : const Icon(
                                  Icons.attach_file,
                                  color: AppTheme.textSecondaryColor,
                                ),
                          onPressed: _isSendingImage ? null : _pickAndSendImage,
                        ),
                      ],
                    ),
            ),
          ),

          SizedBox(width: 8.w),

          // Audio button - only show when not in stopped recording state
          if (!_recordingStopped)
            GestureDetector(
              onTap: _isRecording
                  ? _stopRecording
                  : (_micPermissionStatus.isGranted
                      ? _startRecording
                      : _requestMicrophonePermission),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? Colors.red
                      : isDarkMode
                          ? Colors.grey[700]
                          : Colors.grey[200],
                ),
                child: Icon(
                  _isRecording
                      ? Icons.stop
                      : (_micPermissionStatus.isGranted
                          ? Icons.mic
                          : Icons.mic_off),
                  color:
                      _isRecording ? Colors.white : AppTheme.textSecondaryColor,
                  size: 20.w,
                ),
              ),
            ),

          SizedBox(width: 8.w),

          // Send button - always show
          GestureDetector(
            onTap: canSend ? _sendTextMessage : null,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: canSend
                    ? AppTheme.primaryColor
                    : isDarkMode
                        ? Colors.grey[700]
                        : Colors.grey[200],
              ),
              child: (_isSendingMessage || _isSendingAudio)
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.send,
                      color:
                          canSend ? Colors.white : AppTheme.textSecondaryColor,
                      size: 20.w,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // New method to show recording UI inside the text field area
  Widget _buildRecordingView(bool isDarkMode) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording
                  ? Colors.red.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
            ),
            child: Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              color: _isRecording ? Colors.red : Colors.blue,
              size: 20.w,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isRecording
                      ? (l10n.recordingAudio ?? 'Recording audio...')
                      : (l10n.audioReadyToSend ?? 'Audio ready to send'),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                    color: _isRecording ? Colors.red : Colors.blue,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      _formatSecondsToTime(_recordingDuration),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: _isRecording ? Colors.red : Colors.blue,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: SizedBox(
                        height: 20.h,
                        child: _isRecording && _audioWaveform.isNotEmpty
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(
                                  _audioWaveform.length,
                                  (index) {
                                    // Apply subtle animation to make it look alive
                                    double heightFactor = _audioWaveform[index];
                                    final animation = math.sin(
                                                _audioVisualizationController
                                                            .value *
                                                        math.pi +
                                                    index * 0.2) *
                                            0.15 +
                                        0.85;
                                    heightFactor *= animation;

                                    return _buildCompactWaveformBar(
                                        heightFactor, true);
                                  },
                                ),
                              )
                            : _recordingStopped
                                ? _buildStaticWaveform()
                                : const SizedBox(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Only show delete button when recording is stopped
          if (_recordingStopped)
            InkWell(
              onTap: _deleteAudioRecording,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20.w,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Compact waveform for inline display
  Widget _buildCompactWaveformBar(double amplitude, bool isRecording) {
    final minHeight = 2.h;
    final maxHeight = 16.h;
    final height = minHeight + (maxHeight - minHeight) * amplitude;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 2.w,
      height: height,
      decoration: BoxDecoration(
        color: isRecording
            ? Colors.red.withOpacity(0.7)
            : Colors.blue.withOpacity(0.7),
        borderRadius: BorderRadius.circular(1.r),
      ),
    );
  }

  // Static waveform for stopped recording
  Widget _buildStaticWaveform() {
    // Use a fixed seed to keep the waveform consistent
    final random = math.Random(42);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        15,
        (index) {
          final height = (0.3 + random.nextDouble() * 0.7) * 16.h;
          return Container(
            width: 2.w,
            height: height,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.7),
              borderRadius: BorderRadius.circular(1.r),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmojiPicker() {
    // This is a placeholder - you would implement an actual emoji picker here
    return Container(
      height: 250.h,
      color: Colors.white,
      child: const Center(
        child: Text(
          'Emoji picker would be implemented here',
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  // New method to build the post reference bar
  Widget _buildPostReferenceBar(bool isDarkMode) {
    final l10n = AppLocalizations.of(context);

    if (_relatedPost == null) return const SizedBox.shrink();

    final postTypeLabel = _relatedPost!.type == PostType.request
        ? (l10n.request ?? 'Request')
        : (l10n.offer ?? 'Offer');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppTheme.primaryColor.withOpacity(0.2)
            : AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12.r),
          bottomRight: Radius.circular(12.r),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _relatedPost!.type == PostType.request
                  ? AppTheme.primaryColor
                  : AppTheme.accentColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              postTypeLabel,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Icon(
            Icons.work_outline,
            size: 14.w,
            color: isDarkMode
                ? AppTheme.primaryColor.withOpacity(0.9)
                : AppTheme.primaryColor,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              _relatedPost!.activity,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.9)
                    : AppTheme.textPrimaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              // Show full post details in a bottom sheet
              _showPostDetailsBottomSheet();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color:
                    isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                l10n.viewPost ?? "View Post",
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to show post details
  void _showPostDetailsBottomSheet() {
    final l10n = AppLocalizations.of(context);

    if (_relatedPost == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Calculate progress for the visualization
            double progress = 0.0;
            if (_isModalAudioPlaying &&
                _currentlyPlayingModalAudioUrl == _relatedPost!.audioUrl &&
                _audioPosition != null &&
                _audioDuration != null &&
                _audioDuration!.inMilliseconds > 0) {
              progress = (_audioPosition!.inMilliseconds /
                      _audioDuration!.inMilliseconds)
                  .clamp(0.0, 1.0);
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Container(
                          width: 40.w,
                          height: 5.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                    ),

                    // Header with gradient
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _relatedPost!.type == PostType.request
                                ? AppTheme.primaryColor
                                : AppTheme.accentColor,
                            _relatedPost!.type == PostType.request
                                ? AppTheme.primaryColor.withOpacity(0.8)
                                : AppTheme.accentColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _relatedPost!.type == PostType.request
                                    ? Icons.help_outline
                                    : Icons.handyman,
                                color: Colors.white,
                                size: 22.r,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  _relatedPost!.type == PostType.request
                                      ? (l10n.requestWithActivity(
                                              _relatedPost!.activity) ??
                                          'Request: ${_relatedPost!.activity}')
                                      : (l10n.offerWithActivity(
                                              _relatedPost!.activity) ??
                                          'Offer: ${_relatedPost!.activity}'),
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // Close button
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 22.r,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.white.withOpacity(0.9),
                                size: 16.r,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                _relatedPost!.city,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Post content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User info with avatar and rating
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24.r,
                                  backgroundColor:
                                      AppTheme.primaryColor.withOpacity(0.1),
                                  backgroundImage: _relatedPost!.userAvatar !=
                                          null
                                      ? NetworkImage(_relatedPost!.userAvatar!)
                                      : null,
                                  child: _relatedPost!.userAvatar == null
                                      ? Icon(
                                          Icons.person,
                                          color: AppTheme.primaryColor,
                                          size: 24.r,
                                        )
                                      : null,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _relatedPost!.userName,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      // Star rating
                                      Row(
                                        children: [
                                          ...List.generate(
                                            5,
                                            (index) => Icon(
                                              index < 4
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: index < 4
                                                  ? Colors.amber
                                                  : Colors.grey[300],
                                              size: 14.r,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            '4.0',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            Divider(height: 24.h),

                            // Post message
                            if (_relatedPost!.message.isNotEmpty) ...[
                              Text(
                                l10n.messageLabel ?? 'Message:',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Text(
                                  _relatedPost!.message,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    height: 1.4,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.h),
                            ],

                            // Audio message if available
                            if (_relatedPost!.audioUrl != null &&
                                _relatedPost!.audioUrl!.isNotEmpty) ...[
                              Text(
                                l10n.audioMessageLabel ?? 'Audio Message:',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Play/Pause button with animation
                                    Container(
                                      width: 36.w,
                                      height: 36.w,
                                      decoration: BoxDecoration(
                                        color: _isModalAudioPlaying &&
                                                _currentlyPlayingModalAudioUrl ==
                                                    _relatedPost!.audioUrl
                                            ? Colors.red.shade100
                                            : AppTheme.primaryColor
                                                .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isModalAudioPlaying &&
                                                  _currentlyPlayingModalAudioUrl ==
                                                      _relatedPost!.audioUrl
                                              ? Colors.red.shade300
                                              : AppTheme.primaryColor
                                                  .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          if (_isModalAudioPlaying &&
                                              _currentlyPlayingModalAudioUrl ==
                                                  _relatedPost!.audioUrl) {
                                            _stopModalAudio().then((_) {
                                              setModalState(() {});
                                            });
                                          } else {
                                            _playPostAudio(
                                                    _relatedPost!.audioUrl!)
                                                .then((_) {
                                              setModalState(() {});
                                            });
                                          }
                                        },
                                        borderRadius:
                                            BorderRadius.circular(20.r),
                                        child: Icon(
                                          _isModalAudioPlaying &&
                                                  _currentlyPlayingModalAudioUrl ==
                                                      _relatedPost!.audioUrl
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: _isModalAudioPlaying &&
                                                  _currentlyPlayingModalAudioUrl ==
                                                      _relatedPost!.audioUrl
                                              ? Colors.red
                                              : AppTheme.primaryColor,
                                          size: 20.r,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),

                                    // Audio visualization and duration
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Audio visualization with spikes
                                          SizedBox(
                                            height: 20.h,
                                            child: Row(
                                              children: List.generate(
                                                _spikeCount,
                                                (index) {
                                                  final position =
                                                      index / (_spikeCount - 1);
                                                  final isActive =
                                                      position <= progress;

                                                  double heightFactor =
                                                      _getAudioVisualizationData(
                                                                      'modal')
                                                                  .length >
                                                              index
                                                          ? _getAudioVisualizationData(
                                                              'modal')[index]
                                                          : 0.5;

                                                  if (_isModalAudioPlaying &&
                                                      _currentlyPlayingModalAudioUrl ==
                                                          _relatedPost!
                                                              .audioUrl) {
                                                    final animation = math.sin(
                                                                _audioVisualizationController
                                                                            .value *
                                                                        math
                                                                            .pi +
                                                                    index *
                                                                        0.2) *
                                                            0.15 +
                                                        0.85;
                                                    heightFactor *= animation;
                                                  }

                                                  return Expanded(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 1.w),
                                                      child: AnimatedContainer(
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    200),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isActive &&
                                                                  _isModalAudioPlaying &&
                                                                  _currentlyPlayingModalAudioUrl ==
                                                                      _relatedPost!
                                                                          .audioUrl
                                                              ? Colors.red
                                                              : isActive
                                                                  ? AppTheme
                                                                      .primaryColor
                                                                  : Colors.grey
                                                                      .shade300,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      2.r),
                                                        ),
                                                        height:
                                                            16.h * heightFactor,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),

                                          SizedBox(height: 6.h),

                                          // Time display
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _isModalAudioPlaying &&
                                                        _currentlyPlayingModalAudioUrl ==
                                                            _relatedPost!
                                                                .audioUrl &&
                                                        _audioPosition != null
                                                    ? _formatDurationToTime(
                                                        _audioPosition)
                                                    : "00:00",
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  color: AppTheme
                                                      .textSecondaryColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                _isModalAudioPlaying &&
                                                        _audioDuration != null
                                                    ? _formatDurationToTime(
                                                        _audioDuration)
                                                    : _relatedPost!
                                                                .audioDuration !=
                                                            null
                                                        ? _formatSecondsToTime(
                                                            _relatedPost!
                                                                .audioDuration!)
                                                        : "00:00",
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  color: AppTheme
                                                      .textSecondaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Contact user button
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.close ?? 'Close',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Format duration for display when provided with Duration object
  String _formatDurationToTime(Duration? duration) {
    if (duration == null) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // Format duration for display when provided with seconds integer
  String _formatSecondsToTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

// Message model
class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus? status;
  final int? audioDuration; // Duration in seconds for audio messages

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.type,
    this.status,
    this.audioDuration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp,
      'type': type.toString(),
      'status': status?.toString(),
      'audioDuration': audioDuration,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      senderId: map['senderId'],
      content: map['content'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      type: map['type'] == 'MessageType.audio'
          ? MessageType.audio
          : MessageType.text,
      status: _parseMessageStatus(map['status']),
      audioDuration: map['audioDuration'],
    );
  }

  static MessageStatus? _parseMessageStatus(String? status) {
    if (status == null) return null;
    return MessageStatus.values.firstWhere(
      (e) => e.toString() == status,
      orElse: () => MessageStatus.sent,
    );
  }
}

enum MessageType { text, audio, image }

enum MessageStatus { sending, sent, delivered, read, error }
