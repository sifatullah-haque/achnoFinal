import 'package:flutter/material.dart';
import 'package:achno/pages/addPost/components/add_post_view.dart';

class Addpost extends StatefulWidget {
  const Addpost({super.key});

  @override
  State<Addpost> createState() => _AddpostState();
}

class _AddpostState extends State<Addpost> {
  @override
  Widget build(BuildContext context) {
    return const AddPostView();
  }
}
