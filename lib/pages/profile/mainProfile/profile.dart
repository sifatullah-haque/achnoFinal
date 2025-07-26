import 'package:flutter/material.dart';
import 'components/profile_view.dart';

class Profile extends StatefulWidget {
  final String? userId;

  const Profile({super.key, this.userId});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return ProfileView(userId: widget.userId);
  }
}
