import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/bottom_nav_bar.dart';
import 'package:flutter_application_1/screens/camera_tab.dart';
import 'package:flutter_application_1/screens/create_post_screen.dart';
import 'package:flutter_application_1/screens/feed_tab.dart';
import 'package:flutter_application_1/screens/floating_ai_button.dart';
import 'package:flutter_application_1/screens/profile_tab.dart';
import 'package:flutter_application_1/screens/search_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    FeedTab(),
    CreatePostScreen(),
    CameraTab(), // index 2
    SearchTab(),
    ProfileTab(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onAITap() {
    Navigator.pushNamed(context, '/ai-chat');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],

      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),

      // ✅ Floating AI button — NOT CENTER, NOT COVERING CAMERA
      floatingActionButton: _currentIndex != 2
          ? FloatingAIButton(onTap: _onAITap, isChatActive: false)
          : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
