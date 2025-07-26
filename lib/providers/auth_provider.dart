import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:achno/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:achno/services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  User? _currentUser;
  bool _initializing = false;
  bool _initialized = false;
  String? _verificationId;
  int? _resendToken;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _initialized;
  String? get verificationId => _verificationId;

  AuthProvider({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    // Initialize right away when created
    initialize();
  }

  /// Initialize the auth provider and load user data if user is logged in
  Future<void> initialize() async {
    if (_initializing) return; // Don't run multiple initializations in parallel

    if (_initialized) {
      // If already initialized, just check the current auth state
      await checkAuthStatus();
      return;
    }

    _initializing = true;
    debugPrint('Initializing AuthProvider...');

    try {
      // Check SharedPreferences for login status
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      debugPrint('AuthProvider: SharedPreferences isLoggedIn = $isLoggedIn');

      final currentFirebaseUser = _firebaseAuth.currentUser;
      debugPrint(
          'Current Firebase user: ${currentFirebaseUser?.uid ?? 'none'}');

      if (currentFirebaseUser != null) {
        try {
          await _loadCurrentUserData(currentFirebaseUser.uid);
          // Update login status in case it was incorrect
          if (prefs.getBool('isLoggedIn') != true) {
            await prefs.setBool('isLoggedIn', true);
            debugPrint('Updated SharedPreferences: isLoggedIn = true');
          }
        } catch (e) {
          debugPrint('Error loading user data, but Firebase user exists: $e');
          // Create a basic user object from Firebase auth data
          _currentUser = User(
            id: currentFirebaseUser.uid,
            email: currentFirebaseUser.email ?? '',
            firstName: '',
            lastName: '',
            city: '',
            userType: 'Client',
            isProfessional: false,
          );

          // Even with error, we have a user so update login status
          if (prefs.getBool('isLoggedIn') != true) {
            await prefs.setBool('isLoggedIn', true);
          }
        }
      } else {
        _currentUser = null;
        // No Firebase user, clear login status
        if (isLoggedIn) {
          await prefs.setBool('isLoggedIn', false);
          debugPrint('Updated SharedPreferences: isLoggedIn = false');
        }
      }
    } catch (e) {
      debugPrint('Error in initialize: $e');
      _currentUser = null;
    } finally {
      _initializing = false;
      _initialized = true;
      notifyListeners();
      debugPrint(
          'AuthProvider initialized. User authenticated: $isAuthenticated');
    }
  }

  Future<bool> checkAuthentication() async {
    if (!_initialized) {
      await initialize();
    }
    return isAuthenticated;
  }

  Future<void> _loadCurrentUserData(String userId) async {
    int retryCount = 0;
    const maxRetries = 3;
    const initialDelay = Duration(seconds: 1);

    while (retryCount < maxRetries) {
      try {
        debugPrint(
            'Loading user data for ID: $userId (attempt ${retryCount + 1})');

        // First check if Firestore is available
        try {
          await _firestore.terminate();
          await _firestore.clearPersistence();
          await _firestore.enableNetwork();
        } catch (e) {
          debugPrint('Error reinitializing Firestore: $e');
        }

        final userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          _currentUser = User.fromFirestore(userDoc);
          debugPrint(
              'User data loaded successfully: ${_currentUser?.firstName}');
          debugPrint(
              'User is admin: ${_currentUser?.isAdmin}'); // Add this to log admin status
          notifyListeners();
          return;
        } else {
          // Create basic user document if it doesn't exist
          final userData = {
            'email': _firebaseAuth.currentUser?.email ?? '',
            'firstName': '',
            'lastName': '',
            'city': '',
            'userType': 'Client',
            'isProfessional': false,
            'isAdmin': false, // Make sure to set isAdmin to false by default
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          await _firestore.collection('users').doc(userId).set(userData);

          _currentUser = User(
            id: userId,
            email: _firebaseAuth.currentUser?.email ?? '',
            firstName: '',
            lastName: '',
            city: '',
            userType: 'Client',
            isProfessional: false,
            isAdmin: false, // Add isAdmin property here
          );

          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('Error loading user data (attempt ${retryCount + 1}): $e');

        if (e.toString().contains('NOT_FOUND') ||
            e.toString().contains('database (default) does not exist')) {
          // Database doesn't exist error - create minimal user object
          _currentUser = User(
            id: userId,
            email: _firebaseAuth.currentUser?.email ?? '',
            firstName: '',
            lastName: '',
            city: '',
            userType: 'Client',
            isProfessional: false,
            isAdmin: false, // Add isAdmin property here
          );
          notifyListeners();
          return;
        }

        if (retryCount == maxRetries - 1) {
          // On final attempt, keep the Firebase user logged in with minimal data
          if (_firebaseAuth.currentUser != null) {
            _currentUser = User(
              id: userId,
              email: _firebaseAuth.currentUser?.email ?? '',
              firstName: '',
              lastName: '',
              city: '',
              userType: 'Client',
              isProfessional: false,
              isAdmin: false, // Add isAdmin property here
            );
            notifyListeners();
          } else {
            _currentUser = null;
          }
          return;
        }

        // Exponential backoff
        await Future.delayed(initialDelay * (retryCount + 1));
        retryCount++;
      }
    }
  }

  Future<void> _createBasicUserDocument(String userId) async {
    try {
      final userData = {
        'email': _firebaseAuth.currentUser?.email ?? '',
        'firstName': '',
        'lastName': '',
        'city': '',
        'userType': 'Client',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).set(userData);
      debugPrint('Created basic user document for ID: $userId');
    } catch (e) {
      debugPrint('Error creating basic user document: $e');
      // Don't throw here - we want to continue even if this fails
    }
  }

  // New method for sending phone verification code
  Future<void> sendPhoneVerificationCode(
    String phoneNumber,
    Function(String, int?) codeSent,
    Function(firebase_auth.FirebaseAuthException) verificationFailed,
    Function(String) codeAutoRetrievalTimeout,
    Function(firebase_auth.PhoneAuthCredential) verificationCompleted,
  ) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber.startsWith('+')
          ? phoneNumber
          : '+91$phoneNumber', // Default to India code if not provided
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        codeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
    );
  }

  // New method to verify OTP
  Future<firebase_auth.UserCredential> verifyOTPAndLogin(String otp) async {
    if (_verificationId == null) {
      throw Exception('Verification ID not found. Please request OTP again.');
    }

    final credential = firebase_auth.PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    await _loadCurrentUserData(userCredential.user!.uid);

    // Store auth persistence data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    notifyListeners();
    return userCredential;
  }

  Future<void> signIn(String email, String password) async {
    debugPrint('Attempting login for: $email');
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _loadCurrentUserData(userCredential.user!.uid);

      // After successful sign in, FCM token will be saved automatically by NotificationService

      // Store auth persistence data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      debugPrint(
          'Login successful, SharedPreferences updated: isLoggedIn = true');

      notifyListeners();
    } catch (e) {
      debugPrint('Error during login: $e');
      rethrow;
    }
  }

  // Add login method that wraps signIn for compatibility
  Future<void> login(String phoneNumber, String password) async {
    // Convert phone number to email format for Firebase Auth
    final email = "$phoneNumber@phone.achno.app";
    await signIn(email, password);
  }

  Future<void> register({
    required String phoneNumber,
    required String password,
    required String firstName,
    required String lastName,
    required String city,
    required String userType,
    required bool isProfessional,
    String? activity,
  }) async {
    firebase_auth.UserCredential? userCredential;
    try {
      // Create the user with email that's derived from phone number for now
      // Later we'll replace this with proper phone authentication
      final email = "$phoneNumber@phone.achno.app";

      userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      debugPrint('Created Firebase Auth user with ID: $uid');

      // Create user document in Firestore
      final userData = {
        'phoneNumber': phoneNumber,
        'email': email, // Keep email as a field for backward compatibility
        'firstName': firstName,
        'lastName': lastName,
        'city': city,
        'userType': userType,
        'isProfessional': isProfessional,
        'activity': activity,
        'profilePicture': null,
        'audioBioUrl': null,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'settings': {
          'notifications': true,
          'darkMode': false,
          'language': 'en',
        },
        'stats': {
          'postsCount': 0,
          'likesReceived': 0,
          'responsesReceived': 0,
        }
      };

      // Use set() with merge: false to ensure we only create the document once
      await _firestore
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: false));

      // After registration, load the user data
      await _loadCurrentUserData(uid);

      // Set logged in status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // After successful registration, FCM token will be saved automatically by NotificationService

      notifyListeners();
    } catch (e) {
      debugPrint('Error during registration: $e');
      // If Firestore creation fails, delete the Firebase Auth user
      if (userCredential?.user != null) {
        await userCredential!.user!.delete();
        debugPrint('Deleted Firebase Auth user due to Firestore error');
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _currentUser = null;

    // Clear auth persistence data
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', false);

    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    if (!_initialized) {
      await initialize();
      return;
    }

    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.reload();
        await _loadCurrentUserData(firebaseUser.uid);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      _currentUser = null;
      notifyListeners();
      rethrow;
    }
  }

  // Add any other auth methods like password reset, email verification, etc.
}
