import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_session/audio_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:achno/providers/auth_provider.dart';
import 'package:achno/models/post_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:math' as math;

class MessageDetailsController extends ChangeNotifier {
  // Message data
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String _currentUserId = '';
  bool _isSendingMessage = false;
  bool _isSendingAudio = false;
  bool _isSendingImage = false;
  String _contactCity = '';

  // Audio recording and playback
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

  // Audio visualization
  final List<double> _audioWaveform = [];
  final int _maxWaveformPoints = 30;
  final Map<String, List<double>> _audioVisualizationData = {};
  final int _spikeCount = 27;

  // Audio progress tracking
  Duration? _audioDuration;
  Duration? _audioPosition;
  StreamSubscription? _playerSubscription;

  // Modal audio playback
  String? _currentlyPlayingModalAudioUrl;
  bool _isModalAudioPlaying = false;

  // Recording state
  bool _recordingStopped = false;

  // Related post
  Post? _relatedPost;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  // Getters
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String get currentUserId => _currentUserId;
  bool get isSendingMessage => _isSendingMessage;
  bool get isSendingAudio => _isSendingAudio;
  bool get isSendingImage => _isSendingImage;
  String get contactCity => _contactCity;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get recordedAudioPath => _recordedAudioPath;
  String get currentlyPlayingId => _currentlyPlayingId;
  int get recordingDuration => _recordingDuration;
  PermissionStatus get micPermissionStatus => _micPermissionStatus;
  List<double> get audioWaveform => _audioWaveform;
  bool get recordingStopped => _recordingStopped;
  Post? get relatedPost => _relatedPost;
  bool get isModalAudioPlaying => _isModalAudioPlaying;
  String? get currentlyPlayingModalAudioUrl => _currentlyPlayingModalAudioUrl;
  Duration? get audioDuration => _audioDuration;
  Duration? get audioPosition => _audioPosition;

  // Initialize controller
  Future<void> initialize(BuildContext context, String conversationId,
      String? contactId, Post? relatedPost) async {
    await _getCurrentUser(context);
    await _initializeAudio();

    if (conversationId.isNotEmpty) {
      await _loadMessages(conversationId);
      _setupMessagesListener(conversationId);
    } else {
      _setLoading(false);
    }

    if (contactId != null && contactId.isNotEmpty) {
      await _loadContactInfo(contactId);
    }

    if (conversationId.isNotEmpty) {
      await _loadRelatedPostInfo(conversationId);
    }

    if (relatedPost != null) {
      _relatedPost = relatedPost;
    }

    _setupPlayerSubscription();
  }

  // Get current user
  Future<void> _getCurrentUser(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      _currentUserId = authProvider.currentUser!.id;
      notifyListeners();
    }
  }

  // Load contact info
  Future<void> _loadContactInfo(String contactId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(contactId)
          .get();

      if (userDoc.exists) {
        _contactCity = userDoc.data()?['city'] ?? '';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading contact info: $e');
    }
  }

  // Load related post info
  Future<void> _loadRelatedPostInfo(String conversationId) async {
    if (_relatedPost != null) return;

    try {
      final responseQuery = await FirebaseFirestore.instance
          .collection('responses')
          .where('conversationId', isEqualTo: conversationId)
          .limit(1)
          .get();

      if (responseQuery.docs.isNotEmpty) {
        final responseData = responseQuery.docs.first.data();
        final postId = responseData['postId'] as String?;

        if (postId != null) {
          final postDoc = await FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .get();

          if (postDoc.exists) {
            final postData = postDoc.data() as Map<String, dynamic>;
            _relatedPost = Post.fromFirestore(postData, postId, false);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading related post: $e');
    }
  }

  // Initialize audio
  Future<void> _initializeAudio() async {
    try {
      final status = await Permission.microphone.status;
      _micPermissionStatus = status;
      notifyListeners();

      if (status.isGranted) {
        await _initializeRecorder();
        await _initializePlayer();
      }
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }

  // Initialize recorder
  Future<void> _initializeRecorder() async {
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
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
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

  // Setup messages listener
  void _setupMessagesListener(String conversationId) {
    FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        _loadMessages(conversationId);
      }
    });
  }

  // Load messages
  Future<void> _loadMessages(String conversationId) async {
    _setLoading(true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
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

      _messages = messages;
      _setLoading(false);

      // Mark messages as read
      _markMessagesAsRead(conversationId);
    } catch (e) {
      _setLoading(false);
      debugPrint('Error loading messages: $e');
    }
  }

  // Mark messages as read
  Future<void> _markMessagesAsRead(String conversationId) async {
    if (_currentUserId.isEmpty) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: _currentUserId)
          .where('status', isEqualTo: 'MessageStatus.delivered')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'status': 'MessageStatus.read'});
      }

      await batch.commit();

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastReadBy.$_currentUserId': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Parse message status
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

  // Request microphone permission
  Future<void> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    _micPermissionStatus = status;
    notifyListeners();

    if (status.isGranted) {
      await _initializeRecorder();
      await _initializePlayer();
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  // Start recording
  Future<void> startRecording() async {
    if (_isRecording) return;

    _recordingStopped = false;
    notifyListeners();

    if (!_recorderInitialized) {
      await requestMicrophonePermission();
      if (!_recorderInitialized) return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/message_audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      _audioWaveform.clear();
      _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));

      _recorder.onProgress?.listen((event) {
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
      _recordedAudioPath = filePath;
      _recordingDuration = 0;
      notifyListeners();

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration++;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  // Stop recording
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      _recordingTimer?.cancel();
      await _recorder.stopRecorder();

      _isRecording = false;
      _recordingStopped = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      notifyListeners();
    }
  }

  // Cancel recording
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      _recordingTimer?.cancel();
      await _recorder.stopRecorder();

      if (_recordedAudioPath != null) {
        final file = File(_recordedAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _isRecording = false;
      _recordedAudioPath = null;
      _recordingDuration = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    }
  }

  // Delete audio recording
  void deleteAudioRecording() {
    if (_recordedAudioPath != null) {
      try {
        final file = File(_recordedAudioPath!);
        file.exists().then((exists) {
          if (exists) {
            file.delete();
          }
        });
      } catch (e) {
        debugPrint('Error deleting audio file: $e');
      }
    }

    _recordingStopped = false;
    _recordedAudioPath = null;
    _recordingDuration = 0;
    notifyListeners();
  }

  // Play audio
  Future<void> playAudio(String messageId, String audioUrl) async {
    if (_isPlaying && _currentlyPlayingId == messageId) {
      await stopAudio();
      return;
    }

    if (_isPlaying) {
      await stopAudio();
    }

    try {
      _audioPosition = Duration.zero;
      _audioDuration = null;
      notifyListeners();

      await _player.startPlayer(
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
      _currentlyPlayingId = messageId;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  // Stop audio
  Future<void> stopAudio() async {
    if (!_isPlaying) return;

    try {
      await _player.stopPlayer();
      _isPlaying = false;
      _currentlyPlayingId = '';
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  // Play modal audio
  Future<void> playModalAudio(String audioUrl) async {
    if (_isModalAudioPlaying && _currentlyPlayingModalAudioUrl == audioUrl) {
      await stopModalAudio();
      return;
    }

    if (_isPlaying) {
      await stopAudio();
    }

    if (_isModalAudioPlaying) {
      await stopModalAudio();
    }

    try {
      _audioPosition = Duration.zero;
      _audioDuration = null;
      notifyListeners();

      await _player.startPlayer(
        fromURI: audioUrl,
        codec: Codec.aacADTS,
        whenFinished: () {
          _isModalAudioPlaying = false;
          _currentlyPlayingModalAudioUrl = null;
          _audioPosition = null;
          notifyListeners();
        },
      );

      _isModalAudioPlaying = true;
      _currentlyPlayingModalAudioUrl = audioUrl;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing modal audio: $e');
    }
  }

  // Stop modal audio
  Future<void> stopModalAudio() async {
    if (!_isModalAudioPlaying) return;

    try {
      await _player.stopPlayer();
      _isModalAudioPlaying = false;
      _currentlyPlayingModalAudioUrl = null;
      _audioPosition = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping modal audio: $e');
    }
  }

  // Setup player subscription
  void _setupPlayerSubscription() {
    _playerSubscription = _player.onProgress?.listen((event) {
      _audioPosition = event.position;
      _audioDuration = event.duration;
      notifyListeners();
    });
  }

  // Get audio visualization data
  List<double> getAudioVisualizationData(String messageId) {
    if (!_audioVisualizationData.containsKey(messageId)) {
      final random = math.Random(messageId.hashCode);
      final visualizationData = <double>[];

      for (int i = 0; i < _spikeCount; i++) {
        double height;
        if (i < 5 || i > _spikeCount - 5) {
          height = 0.1 + random.nextDouble() * 0.3;
        } else if ((i > 8 && i < 12) ||
            (i > _spikeCount - 12 && i < _spikeCount - 8)) {
          height = 0.4 + random.nextDouble() * 0.4;
        } else {
          height = 0.3 + random.nextDouble() * 0.7;
        }
        visualizationData.add(height);
      }

      _audioVisualizationData[messageId] = visualizationData;
    }

    return _audioVisualizationData[messageId]!;
  }

  // Send text message
  Future<void> sendTextMessage(
      String conversationId, String text, String? contactId) async {
    if (conversationId.isEmpty) return;

    if (_recordingStopped && _recordedAudioPath != null) {
      await sendAudioMessage(conversationId, contactId);
      return;
    }

    if (text.trim().isEmpty) return;

    _isSendingMessage = true;
    notifyListeners();

    try {
      final newMessage = {
        'senderId': _currentUserId,
        'content': text,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'status': 'MessageStatus.sent',
      };

      final localMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        content: text,
        timestamp: DateTime.now(),
        type: MessageType.text,
        status: MessageStatus.sending,
      );

      _messages.add(localMessage);
      notifyListeners();

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(newMessage);

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastMessage': text,
        'lastMessageType': 'text',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _currentUserId,
        if (contactId != null && contactId.isNotEmpty)
          'unreadCount.$contactId': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  // Send audio message
  Future<void> sendAudioMessage(
      String conversationId, String? contactId) async {
    if (_recordedAudioPath == null) return;

    final String recordingPath = _recordedAudioPath!;
    final int duration = _recordingDuration;

    _isSendingAudio = true;
    _recordingStopped = false;
    _recordedAudioPath = null;
    notifyListeners();

    try {
      final file = File(recordingPath);
      if (!await file.exists()) {
        debugPrint('Audio file does not exist');
        _isSendingAudio = false;
        notifyListeners();
        return;
      }

      final localMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        content: 'Sending audio...',
        timestamp: DateTime.now(),
        type: MessageType.audio,
        status: MessageStatus.sending,
        audioDuration: duration,
      );

      _messages.add(localMessage);
      _recordingDuration = 0;
      notifyListeners();

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('audio_messages')
          .child('${DateTime.now().millisecondsSinceEpoch}.aac');

      await storageRef.putFile(file);
      final audioUrl = await storageRef.getDownloadURL();

      final newMessage = {
        'senderId': _currentUserId,
        'content': audioUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'audio',
        'audioDuration': duration,
        'status': 'MessageStatus.sent',
      };

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(newMessage);

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastMessage': 'Audio message',
        'lastMessageType': 'audio',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _currentUserId,
        if (contactId != null && contactId.isNotEmpty)
          'unreadCount.$contactId': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error sending audio message: $e');
    } finally {
      _isSendingAudio = false;
      notifyListeners();
    }
  }

  // Pick and send image
  Future<void> pickAndSendImage(
      String conversationId, String? contactId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await sendImageMessage(conversationId, File(image.path), contactId);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // Send image message
  Future<void> sendImageMessage(
      String conversationId, File imageFile, String? contactId) async {
    if (conversationId.isEmpty) return;

    _isSendingImage = true;
    notifyListeners();

    try {
      final localMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        content: 'Sending image...',
        timestamp: DateTime.now(),
        type: MessageType.image,
        status: MessageStatus.sending,
      );

      _messages.add(localMessage);
      notifyListeners();

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(imageFile);
      final imageUrl = await storageRef.getDownloadURL();

      final newMessage = {
        'senderId': _currentUserId,
        'content': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'image',
        'status': 'MessageStatus.sent',
      };

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(newMessage);

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastMessage': 'Image',
        'lastMessageType': 'image',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _currentUserId,
        if (contactId != null && contactId.isNotEmpty)
          'unreadCount.$contactId': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error sending image message: $e');
    } finally {
      _isSendingImage = false;
      notifyListeners();
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Format duration
  String formatDurationSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String formatDurationObj(Duration? duration) {
    if (duration == null) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playerSubscription?.cancel();

    stopRecording();
    stopAudio();
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
}

// Message model
class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus? status;
  final int? audioDuration;

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
      status: MessageDetailsController._parseMessageStatus(map['status']),
      audioDuration: map['audioDuration'],
    );
  }
}

enum MessageType { text, audio, image }

enum MessageStatus { sending, sent, delivered, read, error }
