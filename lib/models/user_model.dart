import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? city;
  final String? phoneNumber;
  final String? bio;
  final String userType;
  final bool isProfessional;
  final String? activity;
  final String? profilePicture;
  final String? audioBioUrl;
  final bool isAdmin; // Add isAdmin property

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userType,
    required this.isProfessional,
    this.city,
    this.phoneNumber,
    this.bio,
    this.activity,
    this.profilePicture,
    this.audioBioUrl,
    this.isAdmin = false, // Default to false
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return User(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      city: data['city'],
      phoneNumber: data['phoneNumber'],
      bio: data['bio'],
      userType: data['userType'] ?? 'Client',
      isProfessional: data['isProfessional'] ?? false,
      activity: data['activity'],
      profilePicture: data['profilePicture'],
      audioBioUrl: data['audioBioUrl'],
      isAdmin: data['isAdmin'] ?? false, // Read isAdmin from Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'city': city,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'userType': userType,
      'isProfessional': isProfessional,
      'activity': activity,
      'profilePicture': profilePicture,
      'audioBioUrl': audioBioUrl,
      'isAdmin': isAdmin, // Include isAdmin in the map
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
