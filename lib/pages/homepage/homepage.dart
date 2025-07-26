import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'components/homepage_controller.dart';
import 'components/homepage_view.dart';

class Homepage extends StatefulWidget {
  final Function? onNavigateToAddPost;

  const Homepage({super.key, this.onNavigateToAddPost});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late HomepageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomepageController();
    _initializeController();
  }

  Future<void> _initializeController() async {
    // Initialize audio player in background
    _controller.initAudioPlayer();

    // Get location in background (non-blocking)
    _controller.getCurrentLocationWithoutLocalization();

    // Fetch posts immediately without delay
    if (mounted) {
      _controller.fetchPosts(context);
      // Store context reference to avoid async gap issues
      final currentContext = context;
      _controller.startLocationUpdates(currentContext);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: HomepageView(
        onNavigateToAddPost: widget.onNavigateToAddPost,
        controller: _controller,
      ),
    );
  }
}
